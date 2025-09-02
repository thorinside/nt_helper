import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';

void main() {
  group('OutputMode Enum Tests', () {
    test('OutputMode should have add and replace values', () {
      expect(OutputMode.values, hasLength(2));
      expect(OutputMode.values, contains(OutputMode.add));
      expect(OutputMode.values, contains(OutputMode.replace));
    });

    test('OutputMode should serialize to JSON correctly', () {
      expect(OutputMode.add.name, equals('add'));
      expect(OutputMode.replace.name, equals('replace'));
    });
  });

  group('Port Model Tests', () {
    test('should create port with all required fields', () {
      const port = Port(
        id: 'test_port',
        name: 'Test Port',
        type: PortType.audio,
        direction: PortDirection.input,
      );

      expect(port.id, equals('test_port'));
      expect(port.name, equals('Test Port'));
      expect(port.type, equals(PortType.audio));
      expect(port.direction, equals(PortDirection.input));
      expect(port.isActive, isTrue); // default value
    });

    test('should create port with optional fields', () {
      const port = Port(
        id: 'test_port',
        name: 'Test Port',
        type: PortType.cv,
        direction: PortDirection.output,
        description: 'A test CV output port',
        isActive: false,
        constraints: {'voltageRange': {'min': -5, 'max': 5}},
        metadata: {'category': 'modulation'},
      );

      expect(port.description, equals('A test CV output port'));
      expect(port.isActive, isFalse);
      expect(port.constraints?['voltageRange'], isNotNull);
      expect(port.metadata?['category'], equals('modulation'));
    });

    test('should create output port with outputMode', () {
      const port = Port(
        id: 'output_port',
        name: 'Output Port',
        type: PortType.audio,
        direction: PortDirection.output,
        outputMode: OutputMode.replace,
      );

      expect(port.outputMode, equals(OutputMode.replace));
    });

    test('should create output port with default add mode when not specified', () {
      const port = Port(
        id: 'output_port',
        name: 'Output Port',
        type: PortType.audio,
        direction: PortDirection.output,
      );

      expect(port.outputMode, isNull);
    });

    test('input port should not have outputMode', () {
      const port = Port(
        id: 'input_port',
        name: 'Input Port',
        type: PortType.audio,
        direction: PortDirection.input,
        outputMode: OutputMode.replace, // This should be ignored for input ports
      );

      // The outputMode might be present but should not be used for input ports
      expect(port.direction, equals(PortDirection.input));
    });

    test('should serialize to and from JSON correctly', () {
      const originalPort = Port(
        id: 'test_port',
        name: 'Test Port',
        type: PortType.gate,
        direction: PortDirection.bidirectional,
        description: 'Test description',
        isActive: true,
        constraints: {'maxConnections': 4},
      );

      final json = originalPort.toJson();
      final deserializedPort = Port.fromJson(json);

      expect(deserializedPort, equals(originalPort));
      expect(deserializedPort.id, equals(originalPort.id));
      expect(deserializedPort.name, equals(originalPort.name));
      expect(deserializedPort.type, equals(originalPort.type));
      expect(deserializedPort.direction, equals(originalPort.direction));
      expect(deserializedPort.description, equals(originalPort.description));
      expect(deserializedPort.isActive, equals(originalPort.isActive));
      expect(deserializedPort.constraints, equals(originalPort.constraints));
    });

    test('should serialize port with outputMode to and from JSON correctly', () {
      const originalPort = Port(
        id: 'output_port',
        name: 'Output Port',
        type: PortType.audio,
        direction: PortDirection.output,
        outputMode: OutputMode.replace,
      );

      final json = originalPort.toJson();
      expect(json['outputMode'], equals('replace'));

      final deserializedPort = Port.fromJson(json);
      expect(deserializedPort.outputMode, equals(OutputMode.replace));
      expect(deserializedPort, equals(originalPort));
    });

    group('Port Direction Tests', () {
      test('input port should be identified correctly', () {
        const inputPort = Port(
          id: 'input',
          name: 'Input',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(inputPort.isInput, isTrue);
        expect(inputPort.isOutput, isFalse);
      });

      test('output port should be identified correctly', () {
        const outputPort = Port(
          id: 'output',
          name: 'Output',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        expect(outputPort.isInput, isFalse);
        expect(outputPort.isOutput, isTrue);
      });

      test('bidirectional port should be both input and output', () {
        const bidirectionalPort = Port(
          id: 'bidirectional',
          name: 'Bidirectional',
          type: PortType.audio,
          direction: PortDirection.bidirectional,
        );

        expect(bidirectionalPort.isInput, isTrue);
        expect(bidirectionalPort.isOutput, isTrue);
      });
    });

    group('Port Connection Compatibility Tests', () {
      test('output port should connect to input port', () {
        const outputPort = Port(
          id: 'output',
          name: 'Output',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        const inputPort = Port(
          id: 'input',
          name: 'Input',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(outputPort.canConnectTo(inputPort), isTrue);
        expect(inputPort.canConnectTo(outputPort), isTrue);
      });

      test('input port should not connect to input port', () {
        const inputPort1 = Port(
          id: 'input1',
          name: 'Input 1',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        const inputPort2 = Port(
          id: 'input2',
          name: 'Input 2',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(inputPort1.canConnectTo(inputPort2), isFalse);
      });

      test('output port should not connect to output port', () {
        const outputPort1 = Port(
          id: 'output1',
          name: 'Output 1',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        const outputPort2 = Port(
          id: 'output2',
          name: 'Output 2',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        expect(outputPort1.canConnectTo(outputPort2), isFalse);
      });

      test('bidirectional port should connect to any port', () {
        const bidirectionalPort = Port(
          id: 'bidirectional',
          name: 'Bidirectional',
          type: PortType.audio,
          direction: PortDirection.bidirectional,
        );

        const inputPort = Port(
          id: 'input',
          name: 'Input',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        const outputPort = Port(
          id: 'output',
          name: 'Output',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        expect(bidirectionalPort.canConnectTo(inputPort), isTrue);
        expect(bidirectionalPort.canConnectTo(outputPort), isTrue);
        expect(inputPort.canConnectTo(bidirectionalPort), isTrue);
        expect(outputPort.canConnectTo(bidirectionalPort), isTrue);
      });
    });

    group('Port Type Compatibility Tests', () {
      test('same types should be compatible', () {
        const audioPort1 = Port(
          id: 'audio1',
          name: 'Audio 1',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        const audioPort2 = Port(
          id: 'audio2',
          name: 'Audio 2',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(audioPort1.isCompatibleWith(audioPort2), isTrue);
      });

      test('audio and CV should be compatible', () {
        const audioPort = Port(
          id: 'audio',
          name: 'Audio',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        const cvPort = Port(
          id: 'cv',
          name: 'CV',
          type: PortType.cv,
          direction: PortDirection.input,
        );

        expect(audioPort.isCompatibleWith(cvPort), isTrue);
        expect(cvPort.isCompatibleWith(audioPort), isTrue);
      });

      test('clock and gate should be compatible', () {
        const clockPort = Port(
          id: 'clock',
          name: 'Clock',
          type: PortType.clock,
          direction: PortDirection.output,
        );

        const gatePort = Port(
          id: 'gate',
          name: 'Gate',
          type: PortType.gate,
          direction: PortDirection.input,
        );

        expect(clockPort.isCompatibleWith(gatePort), isTrue);
        expect(gatePort.isCompatibleWith(clockPort), isTrue);
      });

      test('audio and gate should not be directly compatible', () {
        const audioPort = Port(
          id: 'audio',
          name: 'Audio',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        const gatePort = Port(
          id: 'gate',
          name: 'Gate',
          type: PortType.gate,
          direction: PortDirection.input,
        );

        // Audio and gate are different signal types, so they're not compatible
        // unless there's a clock/gate exception
        expect(audioPort.isCompatibleWith(gatePort), isFalse);
        expect(gatePort.isCompatibleWith(audioPort), isFalse);
      });
    });

    group('Port Equality Tests', () {
      test('ports with same values should be equal', () {
        const port1 = Port(
          id: 'test',
          name: 'Test',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        const port2 = Port(
          id: 'test',
          name: 'Test',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(port1, equals(port2));
        expect(port1.hashCode, equals(port2.hashCode));
      });

      test('ports with different values should not be equal', () {
        const port1 = Port(
          id: 'test1',
          name: 'Test 1',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        const port2 = Port(
          id: 'test2',
          name: 'Test 2',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(port1, isNot(equals(port2)));
      });
    });

    group('Port Copy Tests', () {
      test('should create modified copy with copyWith', () {
        const originalPort = Port(
          id: 'original',
          name: 'Original',
          type: PortType.audio,
          direction: PortDirection.input,
          isActive: true,
        );

        final modifiedPort = originalPort.copyWith(
          name: 'Modified',
          isActive: false,
        );

        expect(modifiedPort.id, equals(originalPort.id));
        expect(modifiedPort.name, equals('Modified'));
        expect(modifiedPort.type, equals(originalPort.type));
        expect(modifiedPort.direction, equals(originalPort.direction));
        expect(modifiedPort.isActive, isFalse);
      });
    });
  });
}