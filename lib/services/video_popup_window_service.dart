import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

class VideoPopupWindowService {
  VideoPopupWindowService._();

  static final VideoPopupWindowService instance = VideoPopupWindowService._();

  static const windowType = 'video-popup';
  static const windowsNativeEntryPointArg = 'windows_video_popup';
  static const raiseMethod = 'raiseVideoPopup';
  static const _channelName = 'nt_helper/video_popup';
  static const _channel = WindowMethodChannel(
    _channelName,
    mode: ChannelMode.unidirectional,
  );
  static const _windowsNativeChannel = MethodChannel(
    'nt_helper/windows_video_popup',
  );

  DistingCubit? _cubit;
  bool _handlerRegistered = false;

  static String get windowArguments => jsonEncode({'type': windowType});

  static bool isVideoPopupArguments(String arguments) {
    if (arguments.isEmpty) return false;
    try {
      final decoded = jsonDecode(arguments);
      return decoded is Map && decoded['type'] == windowType;
    } catch (_) {
      return false;
    }
  }

  static bool isWindowsNativeVideoPopupArguments(List<String> args) {
    return args.length >= 2 &&
        args.first == windowsNativeEntryPointArg &&
        isVideoPopupArguments(args[1]);
  }

  bool get isSupported =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> registerMainCubit(DistingCubit cubit) async {
    _cubit = cubit;
    await _ensureHandlerRegistered();
  }

  Future<bool> open(DistingCubit cubit) async {
    if (!isSupported) return false;

    await registerMainCubit(cubit);

    if (Platform.isWindows) {
      debugPrint(
        '[VIDEO_POPUP_DART] open(): using Windows native backend '
        'arguments=$windowArguments',
      );
      final opened = await _windowsNativeChannel.invokeMethod<bool>(
        'openOrFocus',
        {'arguments': windowArguments},
      );
      debugPrint(
        '[VIDEO_POPUP_DART] open(): Windows native openOrFocus result=$opened',
      );
      return opened ?? true;
    }

    debugPrint('[VIDEO_POPUP_DART] open(): using desktop_multi_window backend');

    final existing = await _findExistingWindow();
    if (existing != null) {
      await existing.show();
      try {
        await existing.invokeMethod(raiseMethod);
      } on MissingPluginException {
        // Older running popup instances may not have the raise handler yet.
      }
      return true;
    }

    await WindowController.create(
      WindowConfiguration(arguments: windowArguments, hiddenAtLaunch: true),
    );
    return true;
  }

  Future<void> _ensureHandlerRegistered() async {
    if (_handlerRegistered) return;
    if (Platform.isWindows) {
      debugPrint(
        '[VIDEO_POPUP_DART] registering Windows native method handler',
      );
      _windowsNativeChannel.setMethodCallHandler(_handleMethodCall);
    } else {
      await _channel.setMethodCallHandler(_handleMethodCall);
    }
    _handlerRegistered = true;
  }

  Future<WindowController?> _findExistingWindow() async {
    final controllers = await WindowController.getAll();
    for (final controller in controllers) {
      if (isVideoPopupArguments(controller.arguments)) {
        return controller;
      }
    }
    return null;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    debugPrint(
      '[VIDEO_POPUP_DART] main handler received method=${call.method} '
      'arguments=${call.arguments}',
    );
    switch (call.method) {
      case 'setDisplayMode':
        final modeName = call.arguments as String?;
        DisplayMode? mode;
        for (final candidate in DisplayMode.values) {
          if (candidate.name == modeName) {
            mode = candidate;
            break;
          }
        }
        if (mode == null) {
          throw PlatformException(
            code: 'invalid_display_mode',
            message: 'Unknown display mode: $modeName',
          );
        }
        _cubit?.setDisplayMode(mode);
        return true;
      default:
        throw MissingPluginException(
          'Unknown video popup method ${call.method}',
        );
    }
  }
}
