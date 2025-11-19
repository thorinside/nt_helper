import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('I/O Flags Tests - Story 7.5', () {
    group('AC-9: Input/Output Detection via Flags', () {
      test('should detect input from isInput flag', () {
        // Create a parameter with isInput flag set
        final param = ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: 'Audio Input',
          min: 1,
          max: 20,
          defaultValue: 5,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 1, // Bit 0 set: isInput = true
        );

        expect(param.isInput, isTrue);
        expect(param.isOutput, isFalse);
      });

      test('should detect output from isOutput flag', () {
        // Create a parameter with isOutput flag set
        final param = ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 2,
          name: 'Audio Output',
          min: 1,
          max: 20,
          defaultValue: 10,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 2, // Bit 1 set: isOutput = true
        );

        expect(param.isInput, isFalse);
        expect(param.isOutput, isTrue);
      });

      test('should detect audio port type from isAudio flag', () {
        // Create a parameter with isAudio flag set
        final param = ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 3,
          name: 'Audio Signal',
          min: 1,
          max: 20,
          defaultValue: 15,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 7, // Bits 0, 1, 2 set: isInput, isOutput, isAudio
        );

        expect(param.isAudio, isTrue);
      });

      test('should detect CV port type from isAudio flag being false', () {
        // Create a parameter with isAudio flag NOT set (CV signal)
        final param = ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 4,
          name: 'CV Signal',
          min: 1,
          max: 20,
          defaultValue: 8,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 3, // Bits 0, 1 set: isInput, isOutput; Bit 2 clear: isAudio = false
        );

        expect(param.isAudio, isFalse);
      });

      test('should handle parameters without I/O flags (ioFlags = 0)', () {
        // Create a parameter with no I/O flags (not an I/O parameter)
        final param = ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 5,
          name: 'Algorithm Mode',
          min: 0,
          max: 3,
          defaultValue: 1,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 0, // No flags set
        );

        expect(param.isInput, isFalse);
        expect(param.isOutput, isFalse);
        expect(param.isAudio, isFalse);
      });
    });

    group('AC-1: No Gate/Clock Port Types', () {
      test('PortType enum should only contain audio and cv', () {
        final allTypes = PortType.values;
        expect(allTypes, hasLength(2));
        expect(allTypes, contains(PortType.audio));
        expect(allTypes, contains(PortType.cv));
      });
    });

    group('AC-7: Audio/CV Connection Compatibility', () {
      test('should allow audio to CV connections', () {
        const audioPort = Port(
          id: 'audio',
          name: 'Audio Output',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        const cvPort = Port(
          id: 'cv',
          name: 'CV Input',
          type: PortType.cv,
          direction: PortDirection.input,
        );

        expect(audioPort.isCompatibleWith(cvPort), isTrue);
        expect(audioPort.canConnectTo(cvPort), isTrue);
      });

      test('should allow CV to audio connections', () {
        const cvPort = Port(
          id: 'cv',
          name: 'CV Output',
          type: PortType.cv,
          direction: PortDirection.output,
        );

        const audioPort = Port(
          id: 'audio',
          name: 'Audio Input',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(cvPort.isCompatibleWith(audioPort), isTrue);
        expect(cvPort.canConnectTo(audioPort), isTrue);
      });
    });

    group('AC-8: Offline/Mock Mode Behavior', () {
      test('parameters without I/O flags should not be treated as I/O parameters', () {
        // In offline/mock mode where ioFlags = 0
        final param = ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: 'Some Parameter',
          min: 1,
          max: 20,
          defaultValue: 5,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 0, // Offline mode: no I/O metadata
        );

        // Parameters without I/O flags should not create ports
        // This is acceptable: offline mode has limited routing capabilities
        expect(param.isInput, isFalse);
        expect(param.isOutput, isFalse);
      });

      test('parameters with explicit I/O flags should work even in offline mode', () {
        // If offline metadata includes I/O flags (from bundled metadata), they should work
        final param = ParameterInfo(
          algorithmIndex: 0,
          parameterNumber: 1,
          name: 'Input',
          min: 1,
          max: 20,
          defaultValue: 5,
          unit: 1,
          powerOfTen: 0,
          ioFlags: 5, // isInput + isAudio (from bundled metadata)
        );

        // Should recognize as I/O parameter when flags are present
        expect(param.isInput, isTrue);
        expect(param.isAudio, isTrue);
      });
    });
  });
}
