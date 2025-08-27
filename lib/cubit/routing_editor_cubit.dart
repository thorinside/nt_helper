import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

part 'routing_editor_cubit.freezed.dart';
part 'routing_editor_state.dart';

/// Cubit that manages the state of the routing editor.
/// 
/// Watches the DistingCubit's synchronized state and processes routing 
/// information into a visual representation for the routing canvas.
class RoutingEditorCubit extends Cubit<RoutingEditorState> {
  final DistingCubit _distingCubit;
  StreamSubscription<DistingState>? _distingStateSubscription;

  RoutingEditorCubit(this._distingCubit) 
      : super(const RoutingEditorState.initial()) {
    _initializeStateWatcher();
  }

  /// Initialize watching the disting cubit state changes
  void _initializeStateWatcher() {
    _distingStateSubscription = _distingCubit.stream.listen((distingState) {
      _processDistingState(distingState);
    });
    
    // Process current state if already synchronized
    final currentState = _distingCubit.state;
    _processDistingState(currentState);
  }

  /// Process incoming DistingState and update routing editor state accordingly
  void _processDistingState(DistingState distingState) {
    distingState.when(
      initial: () => emit(const RoutingEditorState.initial()),
      selectDevice: (inputDevices, outputDevices, canWorkOffline) => 
          emit(const RoutingEditorState.disconnected()),
      connected: (disting, inputDevice, outputDevice, offline, loading) => 
          emit(const RoutingEditorState.connecting()),
      synchronized: (disting, distingVersion, firmwareVersion, presetName, 
          algorithms, slots, unitStrings, inputDevice, outputDevice, 
          loading, offline, screenshot, demo, videoStream) {
        _processSynchronizedState(slots);
      },
    );
  }

  /// Extract routing data from synchronized state and build visual representation
  void _processSynchronizedState(List<Slot> slots) {
    try {
      // Create physical hardware ports
      final physicalInputs = _createPhysicalInputPorts();
      final physicalOutputs = _createPhysicalOutputPorts(); 
      
      // Create algorithm representations with their ports (empty for now)
      final algorithms = <RoutingAlgorithm>[];
      for (int i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final routingAlgorithm = RoutingAlgorithm(
          index: i,
          algorithm: slot.algorithm,
          inputPorts: <Port>[], // Will be populated by AlgorithmRouting hierarchy
          outputPorts: <Port>[], // Will be populated by AlgorithmRouting hierarchy  
        );
        algorithms.add(routingAlgorithm);
      }
      
      // No connections for now - will be handled by AlgorithmRouting hierarchy
      final connections = <Connection>[];

      emit(RoutingEditorState.loaded(
        physicalInputs: physicalInputs,
        physicalOutputs: physicalOutputs,
        algorithms: algorithms,
        connections: connections,
      ));
    } catch (e) {
      debugPrint('Error processing synchronized state: $e');
      emit(RoutingEditorState.error('Failed to process routing data: $e'));
    }
  }

  /// Create the 12 physical input ports of the Disting NT
  List<Port> _createPhysicalInputPorts() {
    return [
      // Audio inputs
      const Port(id: 'hw_in_1', name: 'Audio In 1', type: PortType.audio, direction: PortDirection.input),
      const Port(id: 'hw_in_2', name: 'Audio In 2', type: PortType.audio, direction: PortDirection.input),
      // CV inputs
      const Port(id: 'hw_in_3', name: 'CV 1', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_4', name: 'CV 2', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_5', name: 'CV 3', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_6', name: 'CV 4', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_7', name: 'CV 5', type: PortType.cv, direction: PortDirection.input),
      const Port(id: 'hw_in_8', name: 'CV 6', type: PortType.cv, direction: PortDirection.input),
      // Gate inputs
      const Port(id: 'hw_in_9', name: 'Gate 1', type: PortType.gate, direction: PortDirection.input),
      const Port(id: 'hw_in_10', name: 'Gate 2', type: PortType.gate, direction: PortDirection.input),
      // Trigger inputs
      const Port(id: 'hw_in_11', name: 'Trigger 1', type: PortType.trigger, direction: PortDirection.input),
      const Port(id: 'hw_in_12', name: 'Trigger 2', type: PortType.trigger, direction: PortDirection.input),
    ];
  }

  /// Create the 8 physical output ports of the Disting NT
  List<Port> _createPhysicalOutputPorts() {
    return [
      const Port(id: 'hw_out_1', name: 'Audio Out 1', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_2', name: 'Audio Out 2', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_3', name: 'Audio Out 3', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_4', name: 'Audio Out 4', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_5', name: 'Audio Out 5', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_6', name: 'Audio Out 6', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_7', name: 'Audio Out 7', type: PortType.audio, direction: PortDirection.output),
      const Port(id: 'hw_out_8', name: 'Audio Out 8', type: PortType.audio, direction: PortDirection.output),
    ];
  }

  /// Refresh routing data from hardware
  Future<void> refreshRouting() async {
    if (state is RoutingEditorStateLoaded) {
      emit(const RoutingEditorState.refreshing());
    }
    
    try {
      await _distingCubit.refreshRouting();
      // State will be updated through the stream subscription
    } catch (e) {
      debugPrint('Error refreshing routing: $e');
      emit(RoutingEditorState.error('Failed to refresh routing: $e'));
    }
  }

  /// Clear the current routing state
  void clearRouting() {
    emit(const RoutingEditorState.initial());
  }

  @override
  Future<void> close() {
    _distingStateSubscription?.cancel();
    return super.close();
  }
}