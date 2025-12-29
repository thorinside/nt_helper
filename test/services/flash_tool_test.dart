import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/models/flash_progress.dart';
import 'package:nt_helper/models/flash_stage.dart';
import 'package:nt_helper/services/flash_tool_bridge.dart';
import 'package:nt_helper/services/flash_tool_manager.dart';

void main() {
  group('FlashStage', () {
    test('fromMachineValue parses all stages correctly', () {
      expect(FlashStage.fromMachineValue('SDP_CONNECT'), FlashStage.sdpConnect);
      expect(FlashStage.fromMachineValue('BL_CHECK'), FlashStage.blCheck);
      expect(FlashStage.fromMachineValue('SDP_UPLOAD'), FlashStage.sdpUpload);
      expect(FlashStage.fromMachineValue('WRITE'), FlashStage.write);
      expect(FlashStage.fromMachineValue('CONFIGURE'), FlashStage.configure);
      expect(FlashStage.fromMachineValue('RESET'), FlashStage.reset);
      expect(FlashStage.fromMachineValue('COMPLETE'), FlashStage.complete);
    });

    test('fromMachineValue returns null for unknown stage', () {
      expect(FlashStage.fromMachineValue('UNKNOWN'), isNull);
      expect(FlashStage.fromMachineValue(''), isNull);
      expect(FlashStage.fromMachineValue('sdp_connect'), isNull); // case-sensitive
    });

    test('machineValue returns correct string', () {
      expect(FlashStage.sdpConnect.machineValue, 'SDP_CONNECT');
      expect(FlashStage.blCheck.machineValue, 'BL_CHECK');
      expect(FlashStage.sdpUpload.machineValue, 'SDP_UPLOAD');
      expect(FlashStage.write.machineValue, 'WRITE');
      expect(FlashStage.configure.machineValue, 'CONFIGURE');
      expect(FlashStage.reset.machineValue, 'RESET');
      expect(FlashStage.complete.machineValue, 'COMPLETE');
    });
  });

  group('FlashToolManager.getPlatformKeywordForTesting', () {
    test('returns macos for macOS', () {
      expect(
        FlashToolManager.getPlatformKeywordForTesting(
          isMacOS: true,
          isWindows: false,
          isLinux: false,
        ),
        'macos',
      );
    });

    test('returns windows for Windows', () {
      expect(
        FlashToolManager.getPlatformKeywordForTesting(
          isMacOS: false,
          isWindows: true,
          isLinux: false,
        ),
        'windows',
      );
    });

    test('returns linux for Linux', () {
      expect(
        FlashToolManager.getPlatformKeywordForTesting(
          isMacOS: false,
          isWindows: false,
          isLinux: true,
        ),
        'linux',
      );
    });

    test('throws for unsupported platform', () {
      expect(
        () => FlashToolManager.getPlatformKeywordForTesting(
          isMacOS: false,
          isWindows: false,
          isLinux: false,
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('FlashToolManager.getBinaryNameForTesting', () {
    test('returns nt-flash.exe for Windows', () {
      expect(
        FlashToolManager.getBinaryNameForTesting(isWindows: true),
        'nt-flash.exe',
      );
    });

    test('returns nt-flash for non-Windows', () {
      expect(
        FlashToolManager.getBinaryNameForTesting(isWindows: false),
        'nt-flash',
      );
    });
  });

  group('FlashToolBridge._parseMachineOutput', () {
    test('parses STATUS message correctly', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'STATUS:SDP_CONNECT:0:Connecting to device...',
      );

      expect(result, isNotNull);
      expect(result!.stage, FlashStage.sdpConnect);
      expect(result.percent, 0);
      expect(result.message, 'Connecting to device...');
      expect(result.isError, false);
    });

    test('parses STATUS message with colons in message', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'STATUS:COMPLETE:100:Firmware update complete: success!',
      );

      expect(result, isNotNull);
      expect(result!.stage, FlashStage.complete);
      expect(result.percent, 100);
      expect(result.message, 'Firmware update complete: success!');
      expect(result.isError, false);
    });

    test('parses PROGRESS message correctly', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'PROGRESS:SDP_UPLOAD:45',
      );

      expect(result, isNotNull);
      expect(result!.stage, FlashStage.sdpUpload);
      expect(result.percent, 45);
      expect(result.message, '');
      expect(result.isError, false);
    });

    test('parses ERROR message correctly', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'ERROR:Device not found in SDP mode',
      );

      expect(result, isNotNull);
      expect(result!.stage, FlashStage.complete);
      expect(result.percent, 0);
      expect(result.message, 'Device not found in SDP mode');
      expect(result.isError, true);
    });

    test('parses ERROR message with colons', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'ERROR:Failed: timeout after 30s',
      );

      expect(result, isNotNull);
      expect(result!.stage, FlashStage.complete);
      expect(result.message, 'Failed: timeout after 30s');
      expect(result.isError, true);
    });

    test('returns null for unknown message type', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'INFO:Some informational message',
      );

      expect(result, isNull);
    });

    test('returns null for empty string', () {
      final result = FlashToolBridge.parseMachineOutputForTesting('');
      expect(result, isNull);
    });

    test('returns null for malformed STATUS (missing parts)', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'STATUS:SDP_CONNECT',
      );
      expect(result, isNull);
    });

    test('returns null for malformed PROGRESS (missing parts)', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'PROGRESS:SDP_UPLOAD',
      );
      expect(result, isNull);
    });

    test('returns null for STATUS with unknown stage', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'STATUS:UNKNOWN_STAGE:50:Message',
      );
      expect(result, isNull);
    });

    test('handles non-numeric percent gracefully', () {
      final result = FlashToolBridge.parseMachineOutputForTesting(
        'PROGRESS:SDP_UPLOAD:abc',
      );

      expect(result, isNotNull);
      expect(result!.percent, 0); // defaults to 0
    });
  });

  group('FlashProgress', () {
    test('creates immutable instance with required fields', () {
      const progress = FlashProgress(
        stage: FlashStage.sdpConnect,
        percent: 50,
        message: 'Test message',
      );

      expect(progress.stage, FlashStage.sdpConnect);
      expect(progress.percent, 50);
      expect(progress.message, 'Test message');
      expect(progress.isError, false);
    });

    test('isError defaults to false', () {
      const progress = FlashProgress(
        stage: FlashStage.complete,
        percent: 100,
        message: 'Done',
      );

      expect(progress.isError, false);
    });

    test('can set isError to true', () {
      const progress = FlashProgress(
        stage: FlashStage.complete,
        percent: 0,
        message: 'Failed',
        isError: true,
      );

      expect(progress.isError, true);
    });

    test('copyWith creates new instance with updated fields', () {
      const original = FlashProgress(
        stage: FlashStage.sdpConnect,
        percent: 0,
        message: 'Starting',
      );

      final updated = original.copyWith(percent: 50, message: 'In progress');

      expect(updated.stage, FlashStage.sdpConnect);
      expect(updated.percent, 50);
      expect(updated.message, 'In progress');
      expect(updated.isError, false);
    });

    test('equality works correctly', () {
      const a = FlashProgress(
        stage: FlashStage.complete,
        percent: 100,
        message: 'Done',
      );
      const b = FlashProgress(
        stage: FlashStage.complete,
        percent: 100,
        message: 'Done',
      );

      expect(a, equals(b));
    });
  });

  group('FlashToolDownloadException', () {
    test('stores message correctly', () {
      const exception = FlashToolDownloadException('Download failed');
      expect(exception.message, 'Download failed');
    });

    test('toString includes class name and message', () {
      const exception = FlashToolDownloadException('Network error');
      expect(exception.toString(), 'FlashToolDownloadException: Network error');
    });
  });
}
