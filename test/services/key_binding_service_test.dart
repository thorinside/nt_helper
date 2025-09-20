import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/platform/platform_interaction_service.dart';
import 'package:nt_helper/services/key_binding_service.dart';

class _TestHardwareKeyboardAdapter implements HardwareKeyboardAdapter {
  final Set<LogicalKeyboardKey> _pressed = {};

  @override
  Set<LogicalKeyboardKey> get logicalKeysPressed => _pressed;

  void setPressedKeys(Iterable<LogicalKeyboardKey> keys) {
    _pressed
      ..clear()
      ..addAll(keys);
  }
}

class _TestPlatformInteractionService extends PlatformInteractionService {
  _TestPlatformInteractionService(this._platform);

  final TargetPlatform _platform;

  @override
  TargetPlatform get currentPlatform => _platform;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KeyBindingService', () {
    late _TestHardwareKeyboardAdapter hardwareAdapter;

    setUp(() {
      hardwareAdapter = _TestHardwareKeyboardAdapter();
    });

    test('provides zoom shortcuts for meta and control modifiers', () {
      final service = KeyBindingService(
        platformInteractionService: _TestPlatformInteractionService(
          TargetPlatform.macOS,
        ),
        hardwareKeyboard: hardwareAdapter,
      );

      final shortcuts = service.desktopZoomShortcuts;

      expect(
        shortcuts.containsKey(
          const SingleActivator(LogicalKeyboardKey.equal, meta: true),
        ),
        isTrue,
      );
      expect(
        shortcuts.containsKey(
          const SingleActivator(LogicalKeyboardKey.minus, control: true),
        ),
        isTrue,
      );
      expect(
        shortcuts.containsKey(
          const SingleActivator(LogicalKeyboardKey.digit0, meta: true),
        ),
        isTrue,
      );
    });

    testWidgets('builds actions that invoke provided callbacks', (
      tester,
    ) async {
      int zoomInCount = 0;
      int zoomOutCount = 0;
      int resetCount = 0;

      final service = KeyBindingService(
        platformInteractionService: _TestPlatformInteractionService(
          TargetPlatform.windows,
        ),
        hardwareKeyboard: hardwareAdapter,
      );

      final actions = service.buildZoomActions(
        onZoomIn: () => zoomInCount++,
        onZoomOut: () => zoomOutCount++,
        onResetZoom: () => resetCount++,
      );

      late BuildContext capturedContext;

      await tester.pumpWidget(
        WidgetsApp(
          color: const Color(0xFF000000),
          builder: (context, child) {
            return Actions(
              actions: actions,
              child: Builder(
                builder: (innerContext) {
                  capturedContext = innerContext;
                  return const SizedBox.shrink();
                },
              ),
            );
          },
        ),
      );

      Actions.invoke(capturedContext, const ZoomInIntent());
      Actions.invoke(capturedContext, const ZoomOutIntent());
      Actions.invoke(capturedContext, const ResetZoomIntent());

      expect(zoomInCount, 1);
      expect(zoomOutCount, 1);
      expect(resetCount, 1);
    });

    test('reports zoom modifier state correctly on macOS', () {
      final service = KeyBindingService(
        platformInteractionService: _TestPlatformInteractionService(
          TargetPlatform.macOS,
        ),
        hardwareKeyboard: hardwareAdapter,
      );

      hardwareAdapter.setPressedKeys({LogicalKeyboardKey.metaLeft});
      expect(service.isZoomModifierPressed(), isTrue);

      hardwareAdapter.setPressedKeys({});
      expect(service.isZoomModifierPressed(), isFalse);
    });

    test('reports zoom modifier state correctly on Windows', () {
      final service = KeyBindingService(
        platformInteractionService: _TestPlatformInteractionService(
          TargetPlatform.windows,
        ),
        hardwareKeyboard: hardwareAdapter,
      );

      hardwareAdapter.setPressedKeys({LogicalKeyboardKey.controlRight});
      expect(service.isZoomModifierPressed(), isTrue);

      hardwareAdapter.setPressedKeys({});
      expect(service.isZoomModifierPressed(), isFalse);
    });
  });
}
