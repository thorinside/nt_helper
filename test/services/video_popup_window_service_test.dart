import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/services/video_popup_window_service.dart';

void main() {
  group('VideoPopupWindowService window arguments', () {
    test('recognizes hosted popup window arguments', () {
      expect(
        VideoPopupWindowService.isVideoPopupArguments(
          VideoPopupWindowService.windowArguments,
        ),
        isTrue,
      );
      expect(
        VideoPopupWindowService.isVideoPopupArguments('{"type":"main"}'),
        isFalse,
      );
    });

    test('recognizes Windows native popup entrypoint arguments', () {
      expect(
        VideoPopupWindowService.isWindowsNativeVideoPopupArguments([
          VideoPopupWindowService.windowsNativeEntryPointArg,
          VideoPopupWindowService.windowArguments,
        ]),
        isTrue,
      );
      expect(
        VideoPopupWindowService.isWindowsNativeVideoPopupArguments([
          'multi_window',
          VideoPopupWindowService.windowArguments,
        ]),
        isFalse,
      );
    });
  });
}
