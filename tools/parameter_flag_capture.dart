/// Integration test to capture parameter flag data from connected hardware.
///
/// This test connects to the disting NT hardware and queries parameter values
/// for the Clock algorithm, capturing the raw SysEx bytes for analysis.
///
/// Run with: flutter test test/integration/parameter_flag_capture_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'dart:typed_data';

void main() {
  test('Capture Clock algorithm parameter values with flag analysis', () async {
    // Initialize Flutter bindings
    TestWidgetsFlutterBinding.ensureInitialized();

    // Initialize MIDI
    final midiCommand = MidiCommand();

    // Find connected devices
    final devices = await midiCommand.devices;
    if (devices == null || devices.isEmpty) {
      fail('No MIDI devices found. Please connect the disting NT hardware.');
    }

    print('Found ${devices.length} MIDI device(s)');

    // Find disting NT device
    final distingDevice = devices.where((d) => d.name.contains('disting')).firstOrNull;

    if (distingDevice == null) {
      fail('No disting NT device found. Available devices: ${devices.map((d) => d.name).join(', ')}');
    }

    print('Using device: ${distingDevice.name}');

    // Setup raw message capture
    final List<Uint8List> capturedMessages = [];

    final subscription = midiCommand.onMidiDataReceived?.listen((packet) {
      final data = packet.data;
      if (data.isNotEmpty && data[0] == 0xF0) {
        // SysEx message
        if (data.length > 6 && data[6] == 0x44) {
          // 0x44 = respAllParameterValues
          capturedMessages.add(Uint8List.fromList(data));
          print('Captured 0x44 message (${data.length} bytes)');
        }
      }
    });

    // Connect to device
    await midiCommand.connectToDevice(distingDevice);

    // Create MIDI manager
    final manager = DistingMidiManager(
      midiCommand: midiCommand,
      inputDevice: distingDevice,
      outputDevice: distingDevice,
      sysExId: 0, // Default
    );

    try {
      print('Requesting parameters for slot 0 (Clock algorithm)...');

      // Query all parameter values
      final result = await manager.requestAllParameterValues(0);

      // Wait a moment for messages to be captured
      await Future.delayed(Duration(milliseconds: 500));

      if (result == null) {
        fail('Failed to get parameter values');
      }

      print('Received ${result.values.length} parameters');

      // Analyze captured messages
      if (capturedMessages.isEmpty) {
        print('WARNING: No raw messages were captured');
        print('Parameter values received:');
        for (final pv in result.values) {
          print('  Parameter ${pv.parameterNumber}: ${pv.value}');
        }
      } else {
        print('\nAnalyzing captured SysEx messages:');
        print('=' * 70);

        for (var msgIndex = 0; msgIndex < capturedMessages.length; msgIndex++) {
          final message = capturedMessages[msgIndex];
          print('\nMessage ${msgIndex + 1}:');
          print('Hex dump: ${message.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

          // Parse the message
          if (message.length < 8) {
            print('ERROR: Message too short');
            continue;
          }

          // Extract payload (skip F0 00 21 27 6D <sysExId> 44, end before F7)
          final payload = message.sublist(7, message.length - 1);

          if (payload.isEmpty) {
            print('ERROR: Empty payload');
            continue;
          }

          final algorithmIndex = payload[0];
          print('Algorithm index: $algorithmIndex');
          print('');

          print('Parameter Flag Analysis:');
          print('-' * 70);
          print('Param# | Byte0 | Byte1 | Byte2 | Flag  | Value   | Analysis');
          print('-' * 70);

          for (int offset = 1; offset < payload.length; offset += 3) {
            if (offset + 2 >= payload.length) break;

            final paramNumber = (offset - 1) ~/ 3;
            final byte0 = payload[offset];
            final byte1 = payload[offset + 1];
            final byte2 = payload[offset + 2];

            // Decode value
            final rawValue = (byte0 << 14) | (byte1 << 7) | byte2;
            var value = rawValue;
            if (value & 0x8000 != 0) {
              value -= 0x10000; // Sign extend
            }

            // Extract flag (bits 16-20 = byte0 bits 2-6)
            final flag = (byte0 >> 2) & 0x1F;

            final hasFlag = flag != 0;
            final analysis = hasFlag ? '<<< FLAG SET!' : '';

            print('${paramNumber.toString().padLeft(6)} | '
                  '0x${byte0.toRadixString(16).padLeft(2, '0')} | '
                  '0x${byte1.toRadixString(16).padLeft(2, '0')} | '
                  '0x${byte2.toRadixString(16).padLeft(2, '0')} | '
                  '${flag.toString().padLeft(5)} | '
                  '${value.toString().padLeft(7)} | '
                  '$analysis');
          }

          print('=' * 70);
        }
      }

    } finally {
      await subscription?.cancel();
      manager.dispose();
      midiCommand.disconnectDevice(distingDevice);
    }
  }, timeout: Timeout(Duration(seconds: 30)));
}
