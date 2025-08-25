import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:nt_helper/domain/video/usb_device_info.dart';
import 'package:nt_helper/domain/video/usb_video_manager.dart';
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/services/platform_channels/usb_video_channel.dart';

@GenerateMocks([UsbVideoChannel])
import 'usb_video_manager_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsbVideoManager', () {
    late MockUsbVideoChannel mockChannel;
    late UsbVideoManager manager;

    setUp(() {
      mockChannel = MockUsbVideoChannel();
      manager = UsbVideoManager(channel: mockChannel);
    });

    test('initializes with disconnected state', () {
      expect(manager.currentState, const VideoStreamState.disconnected());
    });

    test('initialize creates state stream', () async {
      await manager.initialize();

      expect(manager.stateStream, isNotNull);
    });

    test('state stream is available after initialization', () async {
      await manager.initialize();

      // Stream should be available and not null
      expect(manager.stateStream, isNotNull);

      // Should be a broadcast stream (can have multiple listeners)
      expect(manager.stateStream.isBroadcast, true);
    });

    test('disconnect updates state to disconnected', () async {
      when(mockChannel.stopVideoStream()).thenAnswer((_) async {});

      await manager.initialize();
      await manager.disconnect();

      expect(manager.currentState, const VideoStreamState.disconnected());
      verify(mockChannel.stopVideoStream()).called(1);
    });

    test('isSupported returns mock value', () async {
      when(mockChannel.isSupported()).thenAnswer((_) async => true);

      final supported = await manager.isSupported();

      expect(supported, true);
      verify(mockChannel.isSupported()).called(1);
    });

    test('listUsbCameras returns mock list', () async {
      final mockDevices = [
        const UsbDeviceInfo(
          deviceId: 'test1',
          productName: 'Test Camera 1',
          vendorId: 0x1234,
          productId: 0x5678,
          isDistingNT: false,
        ),
      ];
      when(mockChannel.listUsbCameras()).thenAnswer((_) async => mockDevices);

      final cameras = await manager.listUsbCameras();

      expect(cameras, mockDevices);
      verify(mockChannel.listUsbCameras()).called(1);
    });

    test('findDistingNT returns null when no devices', () async {
      when(
        mockChannel.listUsbCameras(),
      ).thenAnswer((_) async => <UsbDeviceInfo>[]);

      final device = await manager.findDistingNT();

      expect(device, isNull);
      verify(mockChannel.listUsbCameras()).called(1);
    });

    test('findDistingNT returns Disting NT when found', () async {
      const distingNT = UsbDeviceInfo(
        deviceId: 'disting_nt',
        productName: 'Disting NT',
        vendorId: 0x16C0, // Expert Sleepers vendor ID
        productId: 0x1234,
        isDistingNT: true,
      );
      when(mockChannel.listUsbCameras()).thenAnswer((_) async => [distingNT]);

      final device = await manager.findDistingNT();

      expect(device, distingNT);
      verify(mockChannel.listUsbCameras()).called(1);
    });
  });
}
