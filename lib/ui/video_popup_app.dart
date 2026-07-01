import 'dart:async';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:nt_helper/cubit/video_frame_cubit.dart';
import 'package:nt_helper/cubit/video_frame_state.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/video/usb_video_manager.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/services/video_popup_window_service.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:window_manager/window_manager.dart';

const _windowsVideoPopupChannel = MethodChannel(
  'nt_helper/windows_video_popup',
);

class VideoPopupApp extends StatelessWidget {
  const VideoPopupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      home: const VideoPopupWindow(),
    );
  }
}

class VideoPopupWindow extends StatefulWidget {
  const VideoPopupWindow({super.key});

  @override
  State<VideoPopupWindow> createState() => _VideoPopupWindowState();
}

class _VideoPopupWindowState extends State<VideoPopupWindow>
    with WindowListener {
  final SettingsService _settings = SettingsService();
  final UsbVideoManager _videoManager = UsbVideoManager();
  final VideoFrameCubit _videoFrameCubit = VideoFrameCubit();
  StreamSubscription<VideoStreamState>? _videoStateSubscription;
  Stream<dynamic>? _connectedStream;
  Uint8List? _lastFrame;
  Uint8List? _displayFrame;
  bool _alwaysOnTop = SettingsService.defaultVideoPopupAlwaysOnTop;
  bool _toolbarVisible = true;
  bool _toolbarHovering = false;
  Timer? _toolbarHideTimer;

  static const _channel = WindowMethodChannel(
    'nt_helper/video_popup',
    mode: ChannelMode.unidirectional,
  );

  @override
  void initState() {
    super.initState();
    _alwaysOnTop = _settings.videoPopupAlwaysOnTop;
    if (!Platform.isWindows) {
      windowManager.addListener(this);
    }
    unawaited(_configureWindow());
    unawaited(_configureWindowController());
    unawaited(_startVideo());
    _startToolbarHideTimer();
  }

  Future<void> _configureWindow() async {
    if (Platform.isLinux) {
      await windowManager.setPreventClose(true);
    }
    if (!Platform.isWindows && _alwaysOnTop) {
      await windowManager.setAlwaysOnTop(true);
    }
  }

  Future<void> _configureWindowController() async {
    if (Platform.isWindows) {
      _windowsVideoPopupChannel.setMethodCallHandler(_handleWindowsMethod);
      return;
    }
    final controller = await WindowController.fromCurrentEngine();
    await controller.setWindowMethodHandler(_handleWindowMethod);
  }

  Future<dynamic> _handleWindowMethod(MethodCall call) async {
    switch (call.method) {
      case VideoPopupWindowService.raiseMethod:
        await raiseVideoPopupWindow();
        return true;
      default:
        throw MissingPluginException(
          'Unknown video popup method ${call.method}',
        );
    }
  }

  Future<dynamic> _handleWindowsMethod(MethodCall call) async {
    switch (call.method) {
      case 'boundsChanged':
        final bounds = _rectFromMap(call.arguments);
        if (bounds != null) {
          await _settings.setVideoPopupBounds(bounds);
        }
        return true;
      default:
        throw MissingPluginException(
          'Unknown Windows video popup method ${call.method}',
        );
    }
  }

  Future<void> _startVideo() async {
    await _videoManager.initialize();
    _videoStateSubscription = _videoManager.stateStream.listen(
      _onVideoStateChanged,
    );
    await _videoManager.autoConnect();
    _onVideoStateChanged(_videoManager.currentState);
  }

  void _onVideoStateChanged(VideoStreamState videoState) {
    final stream = videoState.maybeWhen(
      streaming: (videoStream, width, height, fps) => videoStream,
      orElse: () => null,
    );

    if (stream == null) {
      _connectedStream = null;
      _videoFrameCubit.disconnect();
      if (mounted) setState(() {});
      return;
    }

    if (!identical(stream, _connectedStream)) {
      _connectedStream = stream;
      _videoFrameCubit.connectToStream(stream);
    }
    if (mounted) setState(() {});
  }

  Future<void> _setDisplayMode(DisplayMode mode) async {
    if (Platform.isWindows) {
      await _windowsVideoPopupChannel.invokeMethod('setDisplayMode', mode.name);
    } else {
      await _channel.invokeMethod('setDisplayMode', mode.name);
    }
  }

  Future<void> _toggleAlwaysOnTop() async {
    final next = !_alwaysOnTop;
    if (Platform.isWindows) {
      await _windowsVideoPopupChannel.invokeMethod('setAlwaysOnTop', {
        'alwaysOnTop': next,
      });
    } else {
      await windowManager.setAlwaysOnTop(next);
    }
    await _settings.setVideoPopupAlwaysOnTop(next);
    if (mounted) {
      setState(() {
        _alwaysOnTop = next;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    final frame = _lastFrame;
    if (frame == null) return;
    Pasteboard.writeImage(frame);
  }

  Future<void> _saveBounds() async {
    final bounds = Platform.isWindows
        ? await getWindowsVideoPopupBounds()
        : await windowManager.getBounds();
    await _settings.setVideoPopupBounds(bounds);
  }

  @override
  void onWindowMoved() => unawaited(_saveBounds());

  @override
  void onWindowResized() => unawaited(_saveBounds());

  @override
  void onWindowClose() {
    if (Platform.isLinux) {
      unawaited(_hideLinuxPopup());
    }
  }

  Future<void> _hideLinuxPopup() async {
    await _saveBounds();
    await windowManager.hide();
  }

  void _startToolbarHideTimer({Duration? delay}) {
    if (_settings.videoToolbarAlwaysVisible || _toolbarHovering) return;
    _toolbarHideTimer?.cancel();
    _toolbarHideTimer = Timer(delay ?? const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _toolbarVisible = false;
        });
      }
    });
  }

  void _showToolbar() {
    _toolbarHideTimer?.cancel();
    if (!_toolbarVisible) {
      setState(() {
        _toolbarVisible = true;
      });
    }
    _startToolbarHideTimer();
  }

  @override
  void dispose() {
    if (Platform.isWindows) {
      _windowsVideoPopupChannel.setMethodCallHandler(null);
    } else {
      windowManager.removeListener(this);
    }
    _toolbarHideTimer?.cancel();
    _videoStateSubscription?.cancel();
    _videoFrameCubit.disconnect();
    unawaited(_videoFrameCubit.close());
    unawaited(_videoManager.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _settings.videoToolbarAlwaysVisibleNotifier,
      builder: (context, alwaysShowToolbar, _) {
        final showToolbar =
            alwaysShowToolbar ||
            _toolbarVisible ||
            MediaQuery.of(context).accessibleNavigation;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: MouseRegion(
              onEnter: (_) {
                _toolbarHovering = true;
                _showToolbar();
              },
              onExit: (_) {
                _toolbarHovering = false;
                _startToolbarHideTimer(
                  delay: const Duration(milliseconds: 350),
                );
              },
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: VideoPopupContent(
                      manager: _videoManager,
                      videoFrameCubit: _videoFrameCubit,
                      displayFrame: _displayFrame,
                      onCopyToClipboard: _copyToClipboard,
                      onFrameUpdate: (frameData) {
                        final stableBytes = Uint8List.fromList(frameData);
                        final previousFrame = _displayFrame;
                        _lastFrame = stableBytes;
                        _displayFrame = stableBytes;
                        if (previousFrame != null) {
                          MemoryImage(previousFrame).evict();
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() {});
                        });
                      },
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 36,
                    child: IgnorePointer(
                      ignoring: !showToolbar,
                      child: ClipRect(
                        child: AnimatedSlide(
                          offset: showToolbar
                              ? Offset.zero
                              : const Offset(0, -1),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: VideoPopupTopBar(
                            alwaysOnTop: _alwaysOnTop,
                            onToggleAlwaysOnTop: _toggleAlwaysOnTop,
                            onSetDisplayMode: _setDisplayMode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class VideoPopupTopBar extends StatelessWidget {
  const VideoPopupTopBar({
    super.key,
    required this.alwaysOnTop,
    required this.onToggleAlwaysOnTop,
    required this.onSetDisplayMode,
  });

  final bool alwaysOnTop;
  final VoidCallback onToggleAlwaysOnTop;
  final ValueChanged<DisplayMode> onSetDisplayMode;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _displayModeButton(
                    Icons.list_alt_rounded,
                    'Parameter View',
                    DisplayMode.parameters,
                  ),
                  _displayModeButton(
                    Icons.line_axis_rounded,
                    'Algorithm UI',
                    DisplayMode.algorithmUI,
                  ),
                  _displayModeButton(
                    Icons.line_weight_rounded,
                    'Overview UI',
                    DisplayMode.overview,
                  ),
                  _displayModeButton(
                    Icons.leaderboard_rounded,
                    'Overview VU Meters',
                    DisplayMode.overviewVUs,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Keep video window on top',
              icon: Icon(
                alwaysOnTop ? Icons.push_pin : Icons.push_pin_outlined,
                size: 18,
                color: Colors.white,
                semanticLabel: 'Keep video window on top',
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              isSelected: alwaysOnTop,
              onPressed: onToggleAlwaysOnTop,
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayModeButton(IconData icon, String tooltip, DisplayMode mode) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon, size: 18, color: Colors.white),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: () => onSetDisplayMode(mode),
    );
  }
}

class VideoPopupContent extends StatelessWidget {
  const VideoPopupContent({
    super.key,
    required this.manager,
    required this.videoFrameCubit,
    required this.displayFrame,
    required this.onCopyToClipboard,
    required this.onFrameUpdate,
  });

  final UsbVideoManager manager;
  final VideoFrameCubit videoFrameCubit;
  final Uint8List? displayFrame;
  final VoidCallback onCopyToClipboard;
  final ValueChanged<Uint8List> onFrameUpdate;

  static const int _fadeInFrames = 8;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoFrameCubit, VideoFrameState>(
      bloc: videoFrameCubit,
      builder: (context, frameState) {
        return frameState.when((frameData, frameCounter, lastFrameTime, fps) {
          if (frameData != null && frameData.length > 10) {
            onFrameUpdate(frameData);
          }

          final bytesToDisplay = displayFrame ?? frameData;
          if (bytesToDisplay == null) {
            return _buildStatus(context);
          }

          final framesIntoFade = frameCounter.clamp(0, _fadeInFrames);
          final fadeT = (framesIntoFade / _fadeInFrames).clamp(0.0, 1.0);
          final opacity = 0.3 + 0.7 * Curves.easeOut.transform(fadeT);

          return Semantics(
            label:
                'Disting NT video feed. Long press to copy frame to clipboard.',
            child: GestureDetector(
              onLongPress: onCopyToClipboard,
              child: SizedBox.expand(
                child: RepaintBoundary(
                  child: ColoredBox(
                    color: Colors.black,
                    child: Opacity(
                      opacity: opacity,
                      child: Image.memory(
                        bytesToDisplay,
                        key: const ValueKey('video_popup_frame'),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }, initial: () => _buildStatus(context));
      },
    );
  }

  Widget _buildStatus(BuildContext context) {
    final state = manager.currentState;
    final errorMessage = state.maybeWhen(
      error: (message) => message,
      orElse: () => null,
    );
    final isConnecting = state.maybeWhen(
      connecting: () => true,
      orElse: () => false,
    );

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: errorMessage == null
            ? Semantics(
                liveRegion: true,
                label: isConnecting
                    ? 'Connecting to Disting NT video'
                    : 'Waiting for Disting NT video',
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => unawaited(manager.autoConnect()),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

Future<void> configureVideoPopupWindow() async {
  final settings = SettingsService();
  final bounds = Rect.fromLTWH(
    settings.videoPopupBoundsX,
    settings.videoPopupBoundsY,
    settings.videoPopupBoundsWidth,
    settings.videoPopupBoundsHeight,
  );

  final hasSavedPosition = bounds.left >= 0 && bounds.top >= 0;
  const minSize = Size(256, 100);
  final initialSize = Size(
    bounds.width.clamp(minSize.width, 1024).toDouble(),
    bounds.height.clamp(minSize.height, 320).toDouble(),
  );

  if (Platform.isWindows) {
    await _windowsVideoPopupChannel.invokeMethod('configureVideoPopup', {
      'x': hasSavedPosition ? bounds.left : null,
      'y': hasSavedPosition ? bounds.top : null,
      'width': initialSize.width,
      'height': initialSize.height,
      'center': !hasSavedPosition,
      'alwaysOnTop': settings.videoPopupAlwaysOnTop,
      'title': 'Disting NT Video',
    });
    return;
  }

  final options = WindowOptions(
    size: initialSize,
    minimumSize: minSize,
    center: !hasSavedPosition,
    backgroundColor: Colors.black,
    skipTaskbar: false,
    title: 'Disting NT Video',
    alwaysOnTop: settings.videoPopupAlwaysOnTop ? true : null,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    if (Platform.isLinux) {
      await windowManager.setPreventClose(true);
    }
    if (hasSavedPosition) {
      await windowManager.setBounds(bounds);
    }
    await windowManager.show();
    await raiseVideoPopupWindow();
  });
}

Future<void> raiseVideoPopupWindow() async {
  if (Platform.isWindows) {
    await _windowsVideoPopupChannel.invokeMethod('raiseCurrentWindow');
    return;
  }
  await windowManager.focus();
}

Future<Rect> getWindowsVideoPopupBounds() async {
  final result = await _windowsVideoPopupChannel
      .invokeMapMethod<String, dynamic>('getBounds');
  final bounds = _rectFromMap(result);
  if (bounds != null) return bounds;
  return Rect.zero;
}

Rect? _rectFromMap(Object? value) {
  if (value is! Map) {
    return null;
  }

  final x = (value['x'] as num?)?.toDouble();
  final y = (value['y'] as num?)?.toDouble();
  final width = (value['width'] as num?)?.toDouble();
  final height = (value['height'] as num?)?.toDouble();
  if (x == null || y == null || width == null || height == null) {
    return null;
  }
  return Rect.fromLTWH(x, y, width, height);
}
