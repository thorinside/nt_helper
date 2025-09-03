import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc/bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/ui/widgets/routing/routing_editor_widget.dart';
import 'package:nt_helper/core/routing/models/connection.dart' show Connection, ConnectionType;
import 'package:nt_helper/core/routing/models/port.dart' as core_port;
import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// A minimal fake DistingCubit that we can drive from the test.
class FakeDistingCubit extends Cubit<DistingState> {
  final _controller = StreamController<DistingState>.broadcast();

  FakeDistingCubit() : super(const DistingState.initial()) {
    // expose stream for RoutingEditorCubit to listen to
    _stream = _controller.stream;
  }

  @override
  Stream<DistingState> get stream => _stream;

  late final Stream<DistingState> _stream;

  void push(DistingState state) => _controller.add(state);

  @override
  Future<void> close() async {
    await _controller.close();
    return super.close();
  }
}

Widget buildTestApp({required RoutingEditorCubit editorCubit, required FakeDistingCubit distingCubit}) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider.value(
        value: editorCubit,
        child: BlocProvider.value(value: distingCubit, child: const RoutingEditorWidget()),
      ),
    ),
  );
}

void main() {
  testWidgets('Connection label updates when port output mode changes', (tester) async {
    final fakeDisting = FakeDistingCubit();
    final editorCubit = RoutingEditorCubit(fakeDisting);

    await tester.pumpWidget(buildTestApp(editorCubit: editorCubit, distingCubit: fakeDisting));

    // Prepare a minimal synchronized state.
    final algorithm = Algorithm(
      algorithmIndex: 0,
      guid: 'alg-001',
      name: 'Dummy Alg',
    );

    final slots = [Slot(index: 0, algorithm: algorithm)];

    // Ports for the algorithm
    final algoInputPort = core_port.Port(
      id: 'algo_001_input_1',
      name: 'In1',
      type: core_port.PortType.cv,
      direction: core_port.PortDirection.input,
    );
    final algoOutputPort = core_port.Port(
      id: 'algo_001_output_1',
      name: 'Out1',
      type: core_port.PortType.audio,
      direction: core_port.PortDirection.output,
    );

    // One connection from algorithm output to physical input.
    final conn = Connection(
      id: 'conn-01',
      sourcePortId: algoOutputPort.id,
      destinationPortId: 'hw_in_1',
      connectionType: ConnectionType.algorithmToAlgorithm, // will be treated as alg‑to‑alg
      busNumber: 13, // physical output bus (O1)
    );

    final synced = DistingState.synchronized(
      disting: null,
      distingVersion: '',
      firmwareVersion: '',
      presetName: '',
      algorithms: [algorithm],
      slots: slots,
      unitStrings: [],
      inputDevice: null,
      outputDevice: null,
      loading: false,
      offline: false,
    );

    fakeDisting.push(synced);
    await tester.pumpAndSettle();

    // Verify initial label (no R suffix)
    expect(find.text('O1'), findsOneWidget);

    final editorState = editorCubit.state;
    if (editorState is RoutingEditorStateLoaded) {
      await editorCubit.setPortOutputMode(
        portId: algoOutputPort.id,
        outputMode: core_port.OutputMode.replace,
      );
    }

    await tester.pumpAndSettle();

    // Verify updated label with R suffix.
    expect(find.text('O1 R'), findsOneWidget);
  });
}
