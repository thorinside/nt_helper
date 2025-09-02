import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/core/routing/algorithm_routing_cubit.dart';
import 'package:nt_helper/core/routing/algorithm_routing.dart';
import 'package:nt_helper/core/routing/models/routing_state.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

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
    // Sync internal lists with the state
    _inputPorts.clear();
    _inputPorts.addAll(newState.inputPorts);
    _outputPorts.clear();
    _outputPorts.addAll(newState.outputPorts);
    _connections.clear();
    _connections.addAll(newState.connections);
  }

  @override
  Connection? addConnection(Port source, Port destination) {
    // Use the parent implementation but also update internal state
    final connection = super.addConnection(source, destination);
    if (connection != null) {
      _connections.add(connection);
    }
    return connection;
  }

  @override
  bool removeConnection(String connectionId) {
    _connections.removeWhere((conn) => conn.id == connectionId);
    return true; // Always return true for test simplicity
  }
}

void main() {
  group('AlgorithmRoutingCubit Tests', () {
    late TestAlgorithmRouting algorithm;
    late AlgorithmRoutingCubit cubit;

    setUp(() {
      algorithm = TestAlgorithmRouting();
      cubit = AlgorithmRoutingCubit(algorithm);
    });

    tearDown(() {
      cubit.close();
    });

    group('Initialization Tests', () {
      test('should initialize with proper state sequence', () async {
        // The cubit should start with uninitialized state, then move to initializing, then ready
        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.length, greaterThanOrEqualTo(1));
        expect(states.last.status, equals(RoutingSystemStatus.ready));
        expect(states.last.inputPorts.length, equals(2));
        expect(states.last.outputPorts.length, equals(2));

        await subscription.cancel();
      });

      test('should have correct initial ports after initialization', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        expect(cubit.state.status, equals(RoutingSystemStatus.ready));
        expect(cubit.state.inputPorts.length, equals(2));
        expect(cubit.state.outputPorts.length, equals(2));

        final inputPort1 = cubit.state.findPortById('input1');
        expect(inputPort1, isNotNull);
        expect(inputPort1!.name, equals('Audio Input 1'));
        expect(inputPort1.type, equals(PortType.audio));

        final outputPort1 = cubit.state.findPortById('output1');
        expect(outputPort1, isNotNull);
        expect(outputPort1!.name, equals('Audio Output 1'));
        expect(outputPort1.type, equals(PortType.audio));
      });
    });

    group('Connection Management Tests', () {
      setUp(() async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should successfully connect compatible ports', () async {
        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.connectPorts('output1', 'input1');

        // Wait for connection to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));
        expect(finalState.connections.length, equals(1));

        final connection = finalState.connections.first;
        expect(connection.sourcePortId, equals('output1'));
        expect(connection.destinationPortId, equals('input1'));

        await subscription.cancel();
      });

      test('should reject incompatible port connections', () async {
        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        // Try to connect incompatible ports (audio output to CV input might have warnings but should work)
        // Let's try connecting input to input instead
        cubit.connectPorts('input1', 'input2');

        // Wait for connection attempt to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.error));
        expect(finalState.connections.length, equals(0));
        expect(finalState.errorMessage, contains('Invalid connection'));

        await subscription.cancel();
      });

      test('should handle connection with detailed validation', () async {
        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.connectPortsWithValidation('output1', 'input1');

        // Wait for connection to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));
        expect(finalState.connections.length, equals(1));

        await subscription.cancel();
      });

      test('should successfully disconnect ports', () async {
        // First connect ports
        cubit.connectPorts('output1', 'input1');
        await Future.delayed(const Duration(milliseconds: 100));

        final connectionId = cubit.state.connections.first.id;

        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.disconnectPorts(connectionId);

        // Wait for disconnection to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));
        expect(finalState.connections.length, equals(0));

        await subscription.cancel();
      });

      test('should handle disconnect of non-existent connection', () async {
        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.disconnectPorts('non_existent');

        // Wait for disconnection attempt to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.error));
        expect(finalState.errorMessage, contains('Connection not found'));

        await subscription.cancel();
      });
    });

    group('Connection Update Tests', () {
      setUp(() async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Create a connection to update
        cubit.connectPorts('output1', 'input1');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should update connection properties', () async {
        final connectionId = cubit.state.connections.first.id;
        final originalGain = cubit.state.connections.first.gain;

        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.updateConnection(
          connectionId,
          gain: 0.5,
          isMuted: true,
        );

        // Wait for update to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));

        final updatedConnection = finalState.findConnectionById(connectionId);
        expect(updatedConnection, isNotNull);
        expect(updatedConnection!.gain, equals(0.5));
        expect(updatedConnection.gain, isNot(equals(originalGain)));
        expect(updatedConnection.isMuted, isTrue);
        // Properties field removed from Connection model

        await subscription.cancel();
      });
    });

    group('Validation Tests', () {
      setUp(() async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should validate empty routing successfully', () async {
        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.validateRouting();

        // Wait for validation to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));

        await subscription.cancel();
      });

      test('should validate routing with valid connections', () async {
        // Create a valid connection first
        cubit.connectPorts('output1', 'input1');
        await Future.delayed(const Duration(milliseconds: 100));

        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.validateRouting();

        // Wait for validation to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));

        await subscription.cancel();
      });
    });

    group('Clear and Reset Tests', () {
      setUp(() async {
        // Wait for initialization and create some connections
        await Future.delayed(const Duration(milliseconds: 100));
        cubit.connectPorts('output1', 'input1');
        cubit.connectPorts('output2', 'input2');
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should clear all connections', () async {
        expect(cubit.state.connections.length, equals(2));

        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.clearAllConnections();

        // Wait for clearing to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));
        expect(finalState.connections.length, equals(0));

        await subscription.cancel();
      });

      test('should reset routing system', () async {
        expect(cubit.state.connections.length, equals(2));

        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.resetRouting();

        // Wait for reset to complete
        await Future.delayed(const Duration(milliseconds: 200));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.ready));
        expect(finalState.connections.length, equals(0));
        expect(finalState.inputPorts.length, equals(2)); // Ports should be regenerated
        expect(finalState.outputPorts.length, equals(2));

        await subscription.cancel();
      });
    });

    group('Error Handling Tests', () {
      test('should handle operations when not ready', () async {
        // Create a new cubit but don't wait for initialization
        final testCubit = AlgorithmRoutingCubit(TestAlgorithmRouting());
        
        // Immediately try to connect (should be ignored)
        testCubit.connectPorts('output1', 'input1');
        
        // The state should still be initializing or ready after init
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Operation should have been handled gracefully
        expect(testCubit.state.status, 
               anyOf([RoutingSystemStatus.ready, RoutingSystemStatus.initializing]));

        await testCubit.close();
      });

      test('should handle invalid port IDs', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));

        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.connectPorts('invalid_source', 'invalid_destination');

        // Wait for connection attempt to complete
        await Future.delayed(const Duration(milliseconds: 100));

        expect(states.isNotEmpty, isTrue);
        final finalState = states.last;
        expect(finalState.status, equals(RoutingSystemStatus.error));
        expect(finalState.errorMessage, contains('Port not found'));

        await subscription.cancel();
      });
    });

    group('State Management Tests', () {
      test('should provide access to underlying algorithm', () async {
        expect(cubit.algorithm, equals(algorithm));
      });

      test('should emit state changes correctly', () async {
        final states = <RoutingState>[];
        final subscription = cubit.stream.listen(states.add);

        // Wait for initial state
        await Future.delayed(const Duration(milliseconds: 100));

        // Perform operations that should emit states
        cubit.connectPorts('output1', 'input1');
        await Future.delayed(const Duration(milliseconds: 100));

        cubit.validateRouting();
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have multiple state emissions
        expect(states.length, greaterThan(2));

        await subscription.cancel();
      });
    });
  });
}