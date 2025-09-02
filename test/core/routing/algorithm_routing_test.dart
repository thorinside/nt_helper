import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/routing_state.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';
import 'package:nt_helper/core/routing/port_compatibility_validator.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

// Helper function to create test Slot
Slot _createTestSlot({
  required List<ParameterInfo> parameters,
  List<ParameterValue> values = const [],
  List<ParameterEnumStrings> enums = const [],
}) {
  return Slot(
    algorithm: Algorithm(
      algorithmIndex: 0,
      guid: 'test-algo',
      name: 'Test Algorithm',
    ),
    routing: RoutingInfo(algorithmIndex: 0, routingInfo: []),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: parameters,
    values: values,
    enums: enums,
    mappings: const [],
    valueStrings: const [],
  );
}

// Test implementation of the abstract AlgorithmRouting class
class TestAlgorithmRouting extends AlgorithmRouting {
  TestAlgorithmRouting({super.validator})
      : _state = const RoutingState(status: RoutingSystemStatus.ready);

  RoutingState _state;
  final List<Port> _inputPorts = [];
  final List<Port> _outputPorts = [];
  final List<Connection> _connections = [];

  @override
  RoutingState get state => _state;

  @override
  List<Port> get inputPorts => List.unmodifiable(_inputPorts);

  @override
  List<Port> get outputPorts => List.unmodifiable(_outputPorts);

  @override
  List<Connection> get connections => List.unmodifiable(_connections);

  @override
  List<Port> generateInputPorts() {
    return [
      const Port(
        id: 'input1',
        name: 'Audio Input 1',
        type: PortType.audio,
        direction: PortDirection.input,
      ),
      const Port(
        id: 'input2',
        name: 'CV Input 1',
        type: PortType.cv,
        direction: PortDirection.input,
      ),
    ];
  }

  @override
  List<Port> generateOutputPorts() {
    return [
      const Port(
        id: 'output1',
        name: 'Audio Output 1',
        type: PortType.audio,
        direction: PortDirection.output,
      ),
      const Port(
        id: 'output2',
        name: 'Gate Output 1',
        type: PortType.gate,
        direction: PortDirection.output,
      ),
    ];
  }

  @override
  void updateState(RoutingState newState) {
    _state = newState;
  }

  // Helper methods for testing
  void setInputPorts(List<Port> ports) {
    _inputPorts.clear();
    _inputPorts.addAll(ports);
  }

  void setOutputPorts(List<Port> ports) {
    _outputPorts.clear();
    _outputPorts.addAll(ports);
  }

  void addTestConnection(Connection connection) {
    _connections.add(connection);
  }

  void clearConnections() {
    _connections.clear();
  }
}

void main() {
  group('AlgorithmRouting Abstract Class Tests', () {
    late TestAlgorithmRouting algorithm;
    late Port audioInputPort;
    late Port audioOutputPort;
    late Port cvInputPort;
    late Port midiInputPort;

    setUp(() {
      algorithm = TestAlgorithmRouting();
      
      audioInputPort = const Port(
        id: 'audio_in',
        name: 'Audio Input',
        type: PortType.audio,
        direction: PortDirection.input,
      );
      
      audioOutputPort = const Port(
        id: 'audio_out',
        name: 'Audio Output',
        type: PortType.audio,
        direction: PortDirection.output,
      );
      
      cvInputPort = const Port(
        id: 'cv_in',
        name: 'CV Input',
        type: PortType.cv,
        direction: PortDirection.input,
      );
      
      midiInputPort = const Port(
        id: 'midi_in',
        name: 'MIDI Input',
        type: PortType.gate,
        direction: PortDirection.input,
      );
    });

    group('Constructor Tests', () {
      test('should create with default validator', () {
        final testAlgorithm = TestAlgorithmRouting();
        
        expect(testAlgorithm.validator, isNotNull);
        expect(testAlgorithm.validator, isA<PortCompatibilityValidator>());
      });

      test('should create with custom validator', () {
        final customValidator = PortCompatibilityValidator();
        final testAlgorithm = TestAlgorithmRouting(validator: customValidator);
        
        expect(testAlgorithm.validator, equals(customValidator));
      });
    });

    group('Abstract Method Implementation Tests', () {
      test('should implement generateInputPorts', () {
        final inputPorts = algorithm.generateInputPorts();
        
        expect(inputPorts.length, equals(2));
        expect(inputPorts[0].id, equals('input1'));
        expect(inputPorts[0].type, equals(PortType.audio));
        expect(inputPorts[0].direction, equals(PortDirection.input));
        expect(inputPorts[1].id, equals('input2'));
        expect(inputPorts[1].type, equals(PortType.cv));
      });

      test('should implement generateOutputPorts', () {
        final outputPorts = algorithm.generateOutputPorts();
        
        expect(outputPorts.length, equals(2));
        expect(outputPorts[0].id, equals('output1'));
        expect(outputPorts[0].type, equals(PortType.audio));
        expect(outputPorts[0].direction, equals(PortDirection.output));
        expect(outputPorts[1].id, equals('output2'));
        expect(outputPorts[1].type, equals(PortType.gate));
      });

      test('should implement updateState', () {
        const newState = RoutingState(
          status: RoutingSystemStatus.error,
          errorMessage: 'Test error',
        );
        
        algorithm.updateState(newState);
        
        expect(algorithm.state, equals(newState));
        expect(algorithm.state.status, equals(RoutingSystemStatus.error));
        expect(algorithm.state.errorMessage, equals('Test error'));
      });
    });

    group('Connection Validation Tests', () {
      test('should validate compatible connection', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        final isValid = algorithm.validateConnection(audioOutputPort, audioInputPort);
        
        expect(isValid, isTrue);
      });

      test('should reject incompatible connection', () {
        algorithm.setInputPorts([midiInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        final isValid = algorithm.validateConnection(audioOutputPort, audioInputPort);
        
        expect(isValid, isFalse);
      });

      test('should provide detailed validation results', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        final result = algorithm.validateConnectionDetailed(audioOutputPort, audioInputPort);
        
        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should provide detailed validation errors', () {
        algorithm.setInputPorts([midiInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        final result = algorithm.validateConnectionDetailed(audioOutputPort, audioInputPort);
        
        expect(result.isValid, isFalse);
        expect(result.errors.isNotEmpty, isTrue);
        expect(result.errors[0].type, equals(ValidationErrorType.incompatibleType));
      });
    });

    group('Connection Management Tests', () {
      test('should add valid connection', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        final connection = algorithm.addConnection(audioOutputPort, audioInputPort);
        
        expect(connection, isNotNull);
        expect(connection!.sourcePortId, equals(audioOutputPort.id));
        expect(connection.destinationPortId, equals(audioInputPort.id));
        expect(connection.id, equals('${audioOutputPort.id}_${audioInputPort.id}'));
      });

      test('should reject invalid connection', () {
        algorithm.setInputPorts([midiInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        final connection = algorithm.addConnection(audioOutputPort, audioInputPort);
        
        expect(connection, isNull);
      });

      test('should remove connection by ID', () {
        const testConnection = Connection(
          id: 'test_connection',
          sourcePortId: 'source',
          destinationPortId: 'dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );
        algorithm.addTestConnection(testConnection);
        
        final removed = algorithm.removeConnection('test_connection');
        
        expect(removed, isTrue);
      });

      test('should return false when removing non-existent connection', () {
        final removed = algorithm.removeConnection('nonexistent');
        
        expect(removed, isFalse);
      });
    });

    group('Port Finding Tests', () {
      setUp(() {
        algorithm.setInputPorts([audioInputPort, cvInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
      });

      test('should find input port by ID', () {
        final foundPort = algorithm.findPortById('audio_in');
        
        expect(foundPort, equals(audioInputPort));
      });

      test('should find output port by ID', () {
        final foundPort = algorithm.findPortById('audio_out');
        
        expect(foundPort, equals(audioOutputPort));
      });

      test('should return null for non-existent port', () {
        final foundPort = algorithm.findPortById('nonexistent');
        
        expect(foundPort, isNull);
      });
    });

    group('Routing Validation Tests', () {
      test('should validate routing with valid connections', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        const validConnection = Connection(
          id: 'valid',
          sourcePortId: 'audio_out',
          destinationPortId: 'audio_in',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );
        algorithm.addTestConnection(validConnection);
        
        final isValid = algorithm.validateRouting();
        
        expect(isValid, isTrue);
      });

      test('should invalidate routing with missing source port', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        const invalidConnection = Connection(
          id: 'invalid',
          sourcePortId: 'nonexistent_source',
          destinationPortId: 'audio_in',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );
        algorithm.addTestConnection(invalidConnection);
        
        final isValid = algorithm.validateRouting();
        
        expect(isValid, isFalse);
      });

      test('should invalidate routing with missing destination port', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        const invalidConnection = Connection(
          id: 'invalid',
          sourcePortId: 'audio_out',
          destinationPortId: 'nonexistent_dest',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );
        algorithm.addTestConnection(invalidConnection);
        
        final isValid = algorithm.validateRouting();
        
        expect(isValid, isFalse);
      });

      test('should invalidate routing with incompatible connection', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        const incompatibleConnection = Connection(
          id: 'incompatible',
          sourcePortId: 'audio_out',
          destinationPortId: 'midi_in',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );
        algorithm.addTestConnection(incompatibleConnection);
        
        final isValid = algorithm.validateRouting();
        
        expect(isValid, isFalse);
      });
    });

    group('Dispose Tests', () {
      test('should dispose without errors', () {
        expect(() => algorithm.dispose(), returnsNormally);
      });
    });

    group('Edge Cases and Error Handling Tests', () {
      test('should handle empty port lists', () {
        algorithm.clearConnections();
        algorithm.setInputPorts([]);
        algorithm.setOutputPorts([]);
        
        expect(algorithm.inputPorts, isEmpty);
        expect(algorithm.outputPorts, isEmpty);
        expect(algorithm.findPortById('any_id'), isNull);
        expect(algorithm.validateRouting(), isTrue); // No connections to validate
      });

      test('should handle connection validation with existing connections', () {
        algorithm.setInputPorts([audioInputPort, cvInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        
        // Add an existing connection
        const existingConnection = Connection(
          id: 'existing',
          sourcePortId: 'audio_out',
          destinationPortId: 'cv_in',
          connectionType: ConnectionType.algorithmToAlgorithm,
        );
        algorithm.addTestConnection(existingConnection);
        
        // Try to validate a new connection
        final result = algorithm.validateConnectionDetailed(audioOutputPort, audioInputPort);
        
        expect(result.isValid, isTrue);
        // Should have warnings about existing connections
        expect(result.warnings.isNotEmpty, isTrue);
      });

      test('should handle null connections list in validation', () {
        algorithm.setInputPorts([audioInputPort]);
        algorithm.setOutputPorts([audioOutputPort]);
        algorithm.clearConnections();
        
        final isValid = algorithm.validateConnection(audioOutputPort, audioInputPort);
        
        expect(isValid, isTrue);
      });
    });

    group('extractModeParameters Tests', () {
      test('should extract mode parameters with enum values Add and Replace', () {
        final slot = _createTestSlot(
          parameters: [
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 1,
              name: 'Output 1 mode',
              unit: 1, // enum type
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 2,
              name: 'Output 2 mode',
              unit: 1, // enum type
              min: 0,
              max: 1,
              defaultValue: 1,
              powerOfTen: 0,
            ),
            // Non-mode parameter should be ignored
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 3,
              name: 'Some other param',
              unit: 1,
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
          ],
          enums: [
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 1,
              values: ['Add', 'Replace'],
            ),
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 2,
              values: ['Add', 'Replace'],
            ),
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 3,
              values: ['Option1', 'Option2'],
            ),
          ],
          values: [
            ParameterValue(
              algorithmIndex: 0,
              parameterNumber: 1,
              value: 1, // Replace
            ),
            ParameterValue(
              algorithmIndex: 0,
              parameterNumber: 2,
              value: 0, // Add
            ),
          ],
        );

        final modeParameters = AlgorithmRouting.extractModeParameters(slot);

        expect(modeParameters, hasLength(2));
        expect(modeParameters['Output 1 mode'], equals(1)); // Replace
        expect(modeParameters['Output 2 mode'], equals(0)); // Add
        expect(modeParameters.containsKey('Some other param'), isFalse);
      });

      test('should use default values when no value is provided', () {
        final slot = _createTestSlot(
          parameters: [
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 1,
              name: 'Output mode',
              unit: 1,
              min: 0,
              max: 1,
              defaultValue: 0, // Default to Add
              powerOfTen: 0,
            ),
          ],
          enums: [
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 1,
              values: ['Add', 'Replace'],
            ),
          ],
          values: [], // No values provided
        );

        final modeParameters = AlgorithmRouting.extractModeParameters(slot);

        expect(modeParameters['Output mode'], equals(0)); // Should use default
      });

      test('should only extract parameters ending with "mode"', () {
        final slot = _createTestSlot(
          parameters: [
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 1,
              name: 'Output mode',
              unit: 1,
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 2,
              name: 'Modulation',
              unit: 1,
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 3,
              name: 'Input mode',
              unit: 1,
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
          ],
          enums: [
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 1,
              values: ['Add', 'Replace'],
            ),
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 2,
              values: ['Add', 'Replace'],
            ),
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 3,
              values: ['Add', 'Replace'],
            ),
          ],
          values: [],
        );

        final modeParameters = AlgorithmRouting.extractModeParameters(slot);

        expect(modeParameters, hasLength(2));
        expect(modeParameters.containsKey('Output mode'), isTrue);
        expect(modeParameters.containsKey('Input mode'), isTrue);
        expect(modeParameters.containsKey('Modulation'), isFalse);
      });

      test('should ignore parameters not meeting all criteria', () {
        final slot = _createTestSlot(
          parameters: [
            // Wrong unit type
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 1,
              name: 'Output mode',
              unit: 0, // Not enum
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
            // Wrong enum values
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 2,
              name: 'Another mode',
              unit: 1,
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
            // Correct mode parameter
            ParameterInfo(
              algorithmIndex: 0,
              parameterNumber: 3,
              name: 'Valid mode',
              unit: 1,
              min: 0,
              max: 1,
              defaultValue: 0,
              powerOfTen: 0,
            ),
          ],
          enums: [
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 1,
              values: ['Add', 'Replace'],
            ),
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 2,
              values: ['Option1', 'Option2'],
            ),
            ParameterEnumStrings(
              algorithmIndex: 0,
              parameterNumber: 3,
              values: ['Add', 'Replace'],
            ),
          ],
          values: [],
        );

        final modeParameters = AlgorithmRouting.extractModeParameters(slot);

        expect(modeParameters, hasLength(1));
        expect(modeParameters.containsKey('Valid mode'), isTrue);
      });

      test('should handle empty slot parameters', () {
        final slot = _createTestSlot(
          parameters: [],
          enums: [],
          values: [],
        );

        final modeParameters = AlgorithmRouting.extractModeParameters(slot);

        expect(modeParameters, isEmpty);
      });
    });
  });
}