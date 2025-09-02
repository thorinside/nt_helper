import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/ui/widgets/routing/physical_port_generator.dart';

void main() {
  group('PhysicalPortGenerator', () {
    group('generatePhysicalInputPorts', () {
      test('generates exactly 12 input ports', () {
        final ports = PhysicalPortGenerator.generatePhysicalInputPorts();
        expect(ports.length, equals(12));
      });

      test('generates ports with correct IDs', () {
        final ports = PhysicalPortGenerator.generatePhysicalInputPorts();
        
        for (int i = 0; i < ports.length; i++) {
          expect(ports[i].id, equals('hw_in_${i + 1}'));
        }
      });

      test('generates ports with correct names', () {
        final ports = PhysicalPortGenerator.generatePhysicalInputPorts();
        
        for (int i = 0; i < ports.length; i++) {
          expect(ports[i].name, equals('Input ${i + 1}'));
        }
      });

      test('generates ports with output direction (sources)', () {
        final ports = PhysicalPortGenerator.generatePhysicalInputPorts();
        
        for (final port in ports) {
          expect(port.direction, equals(PortDirection.output));
        }
      });

      test('generates ports with correct metadata', () {
        final ports = PhysicalPortGenerator.generatePhysicalInputPorts();
        
        for (int i = 0; i < ports.length; i++) {
          final metadata = ports[i].metadata!;
          expect(metadata['isPhysical'], isTrue);
          expect(metadata['hardwareIndex'], equals(i + 1));
          expect(metadata['jackType'], equals('input'));
          expect(metadata['nodeId'], equals('hw_inputs'));
        }
      });

      test('generates ports with audio type', () {
        final ports = PhysicalPortGenerator.generatePhysicalInputPorts();
        
        for (final port in ports) {
          expect(port.type, equals(PortType.audio));
        }
      });
    });

    group('generatePhysicalOutputPorts', () {
      test('generates exactly 8 output ports', () {
        final ports = PhysicalPortGenerator.generatePhysicalOutputPorts();
        expect(ports.length, equals(8));
      });

      test('generates ports with correct IDs', () {
        final ports = PhysicalPortGenerator.generatePhysicalOutputPorts();
        
        for (int i = 0; i < ports.length; i++) {
          expect(ports[i].id, equals('hw_out_${i + 1}'));
        }
      });

      test('generates ports with correct names', () {
        final ports = PhysicalPortGenerator.generatePhysicalOutputPorts();
        
        for (int i = 0; i < ports.length; i++) {
          expect(ports[i].name, equals('Output ${i + 1}'));
        }
      });

      test('generates ports with input direction (targets)', () {
        final ports = PhysicalPortGenerator.generatePhysicalOutputPorts();
        
        for (final port in ports) {
          expect(port.direction, equals(PortDirection.input));
        }
      });

      test('generates ports with correct metadata', () {
        final ports = PhysicalPortGenerator.generatePhysicalOutputPorts();
        
        for (int i = 0; i < ports.length; i++) {
          final metadata = ports[i].metadata!;
          expect(metadata['isPhysical'], isTrue);
          expect(metadata['hardwareIndex'], equals(i + 1));
          expect(metadata['jackType'], equals('output'));
          expect(metadata['nodeId'], equals('hw_outputs'));
        }
      });

      test('generates ports with audio type', () {
        final ports = PhysicalPortGenerator.generatePhysicalOutputPorts();
        
        for (final port in ports) {
          expect(port.type, equals(PortType.audio));
        }
      });
    });

    group('generatePhysicalInputPort', () {
      test('generates single input port with correct properties', () {
        final port = PhysicalPortGenerator.generatePhysicalInputPort(5);
        
        expect(port.id, equals('hw_in_5'));
        expect(port.name, equals('Input 5'));
        expect(port.type, equals(PortType.audio));
        expect(port.direction, equals(PortDirection.output));
        expect(port.metadata?['hardwareIndex'], equals(5));
      });

      test('throws ArgumentError for index < 1', () {
        expect(
          () => PhysicalPortGenerator.generatePhysicalInputPort(0),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for index > 12', () {
        expect(
          () => PhysicalPortGenerator.generatePhysicalInputPort(13),
          throwsArgumentError,
        );
      });
    });

    group('generatePhysicalOutputPort', () {
      test('generates single output port with correct properties', () {
        final port = PhysicalPortGenerator.generatePhysicalOutputPort(3);
        
        expect(port.id, equals('hw_out_3'));
        expect(port.name, equals('Output 3'));
        expect(port.type, equals(PortType.audio));
        expect(port.direction, equals(PortDirection.input));
        expect(port.metadata?['hardwareIndex'], equals(3));
      });

      test('throws ArgumentError for index < 1', () {
        expect(
          () => PhysicalPortGenerator.generatePhysicalOutputPort(0),
          throwsArgumentError,
        );
      });

      test('throws ArgumentError for index > 8', () {
        expect(
          () => PhysicalPortGenerator.generatePhysicalOutputPort(9),
          throwsArgumentError,
        );
      });
    });

    group('Port Validation Methods', () {
      test('isPhysicalInputPort identifies physical inputs correctly', () {
        final inputPort = PhysicalPortGenerator.generatePhysicalInputPort(1);
        final outputPort = PhysicalPortGenerator.generatePhysicalOutputPort(1);
        final algorithmPort = Port(
          id: 'algo_1',
          name: 'Algorithm Port',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        expect(PhysicalPortGenerator.isPhysicalInputPort(inputPort), isTrue);
        expect(PhysicalPortGenerator.isPhysicalInputPort(outputPort), isFalse);
        expect(PhysicalPortGenerator.isPhysicalInputPort(algorithmPort), isFalse);
      });

      test('isPhysicalOutputPort identifies physical outputs correctly', () {
        final inputPort = PhysicalPortGenerator.generatePhysicalInputPort(1);
        final outputPort = PhysicalPortGenerator.generatePhysicalOutputPort(1);
        final algorithmPort = Port(
          id: 'algo_1',
          name: 'Algorithm Port',
          type: PortType.audio,
          direction: PortDirection.input,
        );

        expect(PhysicalPortGenerator.isPhysicalOutputPort(outputPort), isTrue);
        expect(PhysicalPortGenerator.isPhysicalOutputPort(inputPort), isFalse);
        expect(PhysicalPortGenerator.isPhysicalOutputPort(algorithmPort), isFalse);
      });

      test('isPhysicalPort identifies any physical port', () {
        final inputPort = PhysicalPortGenerator.generatePhysicalInputPort(1);
        final outputPort = PhysicalPortGenerator.generatePhysicalOutputPort(1);
        final algorithmPort = Port(
          id: 'algo_1',
          name: 'Algorithm Port',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        expect(PhysicalPortGenerator.isPhysicalPort(inputPort), isTrue);
        expect(PhysicalPortGenerator.isPhysicalPort(outputPort), isTrue);
        expect(PhysicalPortGenerator.isPhysicalPort(algorithmPort), isFalse);
      });
    });

    group('Utility Methods', () {
      test('getHardwareIndex extracts correct index', () {
        final input5 = PhysicalPortGenerator.generatePhysicalInputPort(5);
        final output3 = PhysicalPortGenerator.generatePhysicalOutputPort(3);
        final algorithmPort = Port(
          id: 'algo_1',
          name: 'Algorithm Port',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        expect(PhysicalPortGenerator.getHardwareIndex(input5), equals(5));
        expect(PhysicalPortGenerator.getHardwareIndex(output3), equals(3));
        expect(PhysicalPortGenerator.getHardwareIndex(algorithmPort), isNull);
      });

      test('getPhysicalPortLabel generates correct labels', () {
        final input7 = PhysicalPortGenerator.generatePhysicalInputPort(7);
        final output2 = PhysicalPortGenerator.generatePhysicalOutputPort(2);
        final algorithmPort = Port(
          id: 'algo_1',
          name: 'Algorithm Port',
          type: PortType.audio,
          direction: PortDirection.output,
        );

        expect(PhysicalPortGenerator.getPhysicalPortLabel(input7), equals('In 7'));
        expect(PhysicalPortGenerator.getPhysicalPortLabel(output2), equals('Out 2'));
        expect(
          PhysicalPortGenerator.getPhysicalPortLabel(algorithmPort),
          equals('Algorithm Port'),
        );
      });
    });

    group('Consistency Checks', () {
      test('all generated ports have unique IDs', () {
        final allPorts = [
          ...PhysicalPortGenerator.generatePhysicalInputPorts(),
          ...PhysicalPortGenerator.generatePhysicalOutputPorts(),
        ];

        final ids = allPorts.map((p) => p.id).toSet();
        expect(ids.length, equals(allPorts.length));
      });

      test('port directions are opposite for inputs vs outputs', () {
        final inputs = PhysicalPortGenerator.generatePhysicalInputPorts();
        final outputs = PhysicalPortGenerator.generatePhysicalOutputPorts();

        // Inputs should be sources (output direction)
        for (final input in inputs) {
          expect(input.direction, equals(PortDirection.output));
        }

        // Outputs should be targets (input direction)
        for (final output in outputs) {
          expect(output.direction, equals(PortDirection.input));
        }
      });

      test('metadata is consistent across generation methods', () {
        // Compare bulk generation with individual generation
        final bulkInputs = PhysicalPortGenerator.generatePhysicalInputPorts();
        final bulkOutputs = PhysicalPortGenerator.generatePhysicalOutputPorts();

        for (int i = 1; i <= 12; i++) {
          final individual = PhysicalPortGenerator.generatePhysicalInputPort(i);
          final bulk = bulkInputs[i - 1];
          
          expect(individual.id, equals(bulk.id));
          expect(individual.name, equals(bulk.name));
          expect(individual.type, equals(bulk.type));
          expect(individual.direction, equals(bulk.direction));
          expect(individual.metadata, equals(bulk.metadata));
        }

        for (int i = 1; i <= 8; i++) {
          final individual = PhysicalPortGenerator.generatePhysicalOutputPort(i);
          final bulk = bulkOutputs[i - 1];
          
          expect(individual.id, equals(bulk.id));
          expect(individual.name, equals(bulk.name));
          expect(individual.type, equals(bulk.type));
          expect(individual.direction, equals(bulk.direction));
          expect(individual.metadata, equals(bulk.metadata));
        }
      });
    });
  });
}