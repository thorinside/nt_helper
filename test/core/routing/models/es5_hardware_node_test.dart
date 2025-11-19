import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/es5_hardware_node.dart';
import 'package:nt_helper/core/routing/models/port.dart';

void main() {
  group('ES5HardwareNode', () {
    group('constants', () {
      test('has correct id', () {
        expect(ES5HardwareNode.id, equals('es5_hardware_node'));
      });

      test('has correct name', () {
        expect(ES5HardwareNode.name, equals('ES-5'));
      });

      test('has correct type', () {
        expect(ES5HardwareNode.type, equals('es5_expander'));
      });

      test('has correct input port count', () {
        expect(ES5HardwareNode.inputPortCount, equals(10));
      });

      test('has correct bus assignments', () {
        expect(ES5HardwareNode.leftAudioBus, equals(29));
        expect(ES5HardwareNode.rightAudioBus, equals(30));
      });
    });

    group('createInputPorts', () {
      late List<Port> ports;

      setUp(() {
        ports = ES5HardwareNode.createInputPorts();
      });

      test('creates exactly 10 ports', () {
        expect(ports.length, equals(10));
      });

      test('creates L port with correct configuration', () {
        final lPort = ports.firstWhere((p) => p.id == 'es5_L');
        expect(lPort.name, equals('L'));
        expect(lPort.type, equals(PortType.audio));
        expect(lPort.direction, equals(PortDirection.input));
        expect(lPort.description, equals('ES-5 Left (Silent Way)'));
        expect(lPort.busValue, equals(29));
        expect(lPort.isPhysical, isTrue);
        expect(lPort.nodeId, equals('es5_hardware_node'));
      });

      test('creates R port with correct configuration', () {
        final rPort = ports.firstWhere((p) => p.id == 'es5_R');
        expect(rPort.name, equals('R'));
        expect(rPort.type, equals(PortType.audio));
        expect(rPort.direction, equals(PortDirection.input));
        expect(rPort.description, equals('ES-5 Right (Silent Way)'));
        expect(rPort.busValue, equals(30));
        expect(rPort.isPhysical, isTrue);
        expect(rPort.nodeId, equals('es5_hardware_node'));
      });

      test('creates numbered ports 1-8 with correct configuration', () {
        for (int i = 1; i <= 8; i++) {
          final port = ports.firstWhere((p) => p.id == 'es5_$i');
          expect(port.name, equals('$i'));
          expect(port.type, equals(PortType.cv));
          expect(port.direction, equals(PortDirection.input));
          expect(port.description, equals('ES-5 Output $i'));
          expect(port.busValue, isNull);
          expect(port.isPhysical, isTrue);
          expect(port.nodeId, equals('es5_hardware_node'));
        }
      });

      test('creates ports in correct order (L, R, 1-8)', () {
        expect(ports[0].id, equals('es5_L'));
        expect(ports[1].id, equals('es5_R'));
        expect(ports[2].id, equals('es5_1'));
        expect(ports[3].id, equals('es5_2'));
        expect(ports[4].id, equals('es5_3'));
        expect(ports[5].id, equals('es5_4'));
        expect(ports[6].id, equals('es5_5'));
        expect(ports[7].id, equals('es5_6'));
        expect(ports[8].id, equals('es5_7'));
        expect(ports[9].id, equals('es5_8'));
      });

      test('all ports are physical', () {
        expect(ports.every((p) => p.isPhysical), isTrue);
      });

      test('all ports are inputs', () {
        expect(ports.every((p) => p.direction == PortDirection.input), isTrue);
      });

      test('all ports have correct nodeId', () {
        expect(ports.every((p) => p.nodeId == 'es5_hardware_node'), isTrue);
      });
    });

    group('createOutputPorts', () {
      test('returns empty list', () {
        final ports = ES5HardwareNode.createOutputPorts();
        expect(ports, isEmpty);
      });
    });

    group('isES5Port', () {
      test('returns true for ES-5 ports', () {
        final port = Port(
          id: 'es5_L',
          name: 'L',
          type: PortType.audio,
          direction: PortDirection.input,
          nodeId: 'es5_hardware_node',
        );
        expect(ES5HardwareNode.isES5Port(port), isTrue);
      });

      test('returns false for non-ES-5 ports', () {
        final port = Port(
          id: 'hw_out_1',
          name: 'O1',
          type: PortType.audio,
          direction: PortDirection.input,
          nodeId: 'hw_outputs',
        );
        expect(ES5HardwareNode.isES5Port(port), isFalse);
      });

      test('returns false for ports with null nodeId', () {
        final port = Port(
          id: 'es5_L',
          name: 'L',
          type: PortType.audio,
          direction: PortDirection.input,
        );
        expect(ES5HardwareNode.isES5Port(port), isFalse);
      });
    });

    group('getLeftAudioPort', () {
      test('returns L port with correct configuration', () {
        final port = ES5HardwareNode.getLeftAudioPort();
        expect(port.id, equals('es5_L'));
        expect(port.name, equals('L'));
        expect(port.type, equals(PortType.audio));
        expect(port.direction, equals(PortDirection.input));
        expect(port.busValue, equals(29));
        expect(port.isPhysical, isTrue);
      });
    });

    group('getRightAudioPort', () {
      test('returns R port with correct configuration', () {
        final port = ES5HardwareNode.getRightAudioPort();
        expect(port.id, equals('es5_R'));
        expect(port.name, equals('R'));
        expect(port.type, equals(PortType.audio));
        expect(port.direction, equals(PortDirection.input));
        expect(port.busValue, equals(30));
        expect(port.isPhysical, isTrue);
      });
    });

    group('getNumberedPort', () {
      test('returns correct port for valid numbers 1-8', () {
        for (int i = 1; i <= 8; i++) {
          final port = ES5HardwareNode.getNumberedPort(i);
          expect(port.id, equals('es5_$i'));
          expect(port.name, equals('$i'));
          expect(port.type, equals(PortType.cv));
          expect(port.direction, equals(PortDirection.input));
          expect(port.busValue, isNull);
          expect(port.isPhysical, isTrue);
        }
      });

      test('throws ArgumentError for port number 0', () {
        expect(
          () => ES5HardwareNode.getNumberedPort(0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for port number 9', () {
        expect(
          () => ES5HardwareNode.getNumberedPort(9),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError for negative port number', () {
        expect(
          () => ES5HardwareNode.getNumberedPort(-1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('ArgumentError contains correct message', () {
        try {
          ES5HardwareNode.getNumberedPort(10);
          fail('Should have thrown ArgumentError');
        } catch (e) {
          expect(e, isA<ArgumentError>());
          expect(
            e.toString(),
            contains('ES-5 numbered port must be between 1 and 8'),
          );
          expect(e.toString(), contains('got 10'));
        }
      });
    });

    group('integration', () {
      test('all ports from createInputPorts match individual getters', () {
        final allPorts = ES5HardwareNode.createInputPorts();

        // Check L and R ports match getters
        expect(allPorts[0], equals(ES5HardwareNode.getLeftAudioPort()));
        expect(allPorts[1], equals(ES5HardwareNode.getRightAudioPort()));

        // Check numbered ports match getters
        for (int i = 1; i <= 8; i++) {
          expect(allPorts[i + 1], equals(ES5HardwareNode.getNumberedPort(i)));
        }
      });

      test('L and R ports have bus values, numbered ports do not', () {
        final ports = ES5HardwareNode.createInputPorts();
        final lPort = ports[0];
        final rPort = ports[1];
        final numberedPorts = ports.sublist(2);

        expect(lPort.busValue, isNotNull);
        expect(rPort.busValue, isNotNull);
        expect(numberedPorts.every((p) => p.busValue == null), isTrue);
      });

      test('audio ports have different types than gate ports', () {
        final ports = ES5HardwareNode.createInputPorts();
        final audioPorts = ports.take(2);
        final gatePorts = ports.skip(2);

        expect(audioPorts.every((p) => p.type == PortType.audio), isTrue);
        expect(gatePorts.every((p) => p.type == PortType.cv), isTrue);
      });
    });
  });
}
