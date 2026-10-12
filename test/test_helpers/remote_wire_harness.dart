import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';

import 'mock_midi_command.dart';

const remoteWireSysExId = 0x35;

/// MemoryWireHarness's real-manager/recorded-transport seam, without memory
/// queries or automatic remote replies. Attempts and sent packets are distinct.
final class RemoteWireHarness {
  RemoteWireHarness() {
    when(() => midi.onMidiPacketReceived).thenAnswer((_) => incoming.stream);
    when(
      () => midi.sendData(any(), deviceId: any(named: 'deviceId')),
    ).thenAnswer((invocation) {
      final packet = List<int>.unmodifiable(
        invocation.positionalArguments.single as Uint8List,
      );
      attempts.add(packet);
      if (packet[6] == 0x78 && failRemoteSend) {
        throw StateError('Injected remote transport failure');
      }
      sentPackets.add(packet);
      onSend?.call(packet);
    });
  }

  final midi = MockMidiCommand();
  final incoming = StreamController<MidiPacket>.broadcast();
  final device = MidiDevice(
    'remote-wire-device',
    'Remote Wire Device',
    MidiDeviceType.serial,
    true,
  );
  final List<List<int>> attempts = [];
  final List<List<int>> sentPackets = [];
  final List<DistingMidiManager> _managers = [];
  bool failRemoteSend = false;
  void Function(List<int>)? onSend;
  late DistingMidiManager manager = _createManager();

  DistingMidiManager replaceManager() => manager = _createManager();

  DistingMidiManager _createManager() {
    final next = DistingMidiManager(
      midiCommand: midi,
      inputDevice: device,
      outputDevice: device,
      sysExId: remoteWireSysExId,
    );
    _managers.add(next);
    return next;
  }

  List<List<int>> get remotePackets =>
      sentPackets.where((packet) => packet[6] == 0x78).toList();
  List<List<int>> get remoteAttempts =>
      attempts.where((packet) => packet[6] == 0x78).toList();

  void injectVersion() => incoming.add(
    MidiPacket(
      Uint8List.fromList([
        0xF0,
        0x00,
        0x21,
        0x27,
        0x6D,
        remoteWireSysExId,
        0x32,
        ...'1.19.0'.codeUnits,
        0x00,
        0xF7,
      ]),
      0,
      device,
    ),
  );

  Future<void> close() async {
    for (final manager in _managers) {
      manager.dispose();
    }
    await incoming.close();
  }
}

List<int> remoteFrame(List<int> payload) => [
  0xF0,
  0x00,
  0x21,
  0x27,
  0x6D,
  remoteWireSysExId,
  0x78,
  ...payload,
  0xF7,
];
