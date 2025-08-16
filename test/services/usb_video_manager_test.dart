import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/domain/video/usb_video_manager.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('UsbVideoManager', () {
    late UsbVideoManager manager;

    setUp(() {
      manager = UsbVideoManager();
    });

    tearDown(() {
      // Don't call dispose in tests as it uses platform channels
      // which aren't available in test environment
    });

    test('initializes with disconnected state', () {
      expect(manager.currentState, const VideoStreamState.disconnected());
    });

    test('initialize creates state stream', () async {
      await manager.initialize();
      
      expect(manager.stateStream, isNotNull);
    });

    test('state stream emits state changes', () async {
      await manager.initialize();
      
      final states = <VideoStreamState>[];
      final subscription = manager.stateStream.listen(states.add);
      
      // Wait a bit for any state changes
      await Future.delayed(const Duration(milliseconds: 100));
      
      subscription.cancel();
      
      // Should have at least the initial disconnected state
      expect(states.isNotEmpty, true);
    });

    test('disconnect updates state to disconnected', () async {
      await manager.initialize();
      await manager.disconnect();
      
      expect(manager.currentState, const VideoStreamState.disconnected());
    });

    test('isSupported returns boolean', () async {
      final supported = await manager.isSupported();
      
      // Should return true or false, not throw
      expect(supported, isA<bool>());
    });

    test('listUsbCameras returns list', () async {
      final cameras = await manager.listUsbCameras();
      
      // Should return a list (might be empty)
      expect(cameras, isA<List>());
    });

    test('findDistingNT returns null when no devices', () async {
      final device = await manager.findDistingNT();
      
      // In test environment, should return null
      expect(device, isNull);
    });
  });
}