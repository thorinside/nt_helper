import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/core/routing/models/port.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart' as state;
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/widgets/routing/bus_lanes_view.dart';

import 'bus_lanes_view_test.mocks.dart';

@GenerateMocks([RoutingEditorCubit])
void main() {
  setUpAll(() {
    provideDummy<state.RoutingEditorState>(
      const state.RoutingEditorStateInitial(),
    );
    provideDummy<BusAssignmentResult>(
      const BusAssignmentResult(
        algorithmIndex: 0,
        parameterNumber: 0,
        previousBusValue: 0,
        newBusValue: 0,
        reorder: null,
      ),
    );
  });

  late MockRoutingEditorCubit cubit;

  setUp(() {
    cubit = MockRoutingEditorCubit();
    when(cubit.stream).thenAnswer((_) => const Stream.empty());
  });

  state.RoutingEditorStateLoaded loadedWith(
    List<state.RoutingAlgorithm> algorithms,
  ) => state.RoutingEditorStateLoaded(
    physicalInputs: const [],
    physicalOutputs: const [],
    algorithms: algorithms,
    connections: const [],
  );

  // One algorithm with a single output writing bus 13 (Add). With one used
  // bus the lane field shows 1..24, so bus 13 sits at column 13.
  state.RoutingAlgorithm oscWithOutput() => state.RoutingAlgorithm(
    id: 'algoA',
    index: 0,
    algorithm: Algorithm(algorithmIndex: 0, guid: 'a', name: 'Osc'),
    inputPorts: const [],
    outputPorts: const [
      Port(
        id: 'a_out',
        name: 'Out',
        type: PortType.audio,
        direction: PortDirection.output,
        busValue: 13,
        outputMode: OutputMode.add,
        parameterNumber: 3,
        modeParameterNumber: 5,
      ),
    ],
  );

  state.RoutingAlgorithm inPlaceOutputOnInputBus() => state.RoutingAlgorithm(
    id: 'algoInPlace',
    index: 0,
    algorithm: Algorithm(algorithmIndex: 0, guid: 'attn', name: 'Attn'),
    inputPorts: const [
      Port(
        id: 'attn_in',
        name: 'Input',
        type: PortType.audio,
        direction: PortDirection.input,
        busValue: 5,
        parameterNumber: 0,
        busParam: 'Input',
      ),
    ],
    outputPorts: const [
      Port(
        id: 'attn_out',
        name: 'Output',
        type: PortType.audio,
        direction: PortDirection.output,
        busValue: 5,
        outputMode: OutputMode.replace,
        parameterNumber: 1,
        busParam: 'Output',
      ),
    ],
  );

  // Only bus 13 is in use, so it's column 1: gutter 172 + 1*42 + 21 = 235.
  // Output row 0 center y = header 28 + portRowY(0) 45 = 73.
  const beadCenter = Offset(235, 73);
  // None column 0 center: gutter 172 + 21 = 193.
  const noneCenter = Offset(193, 73);

  Widget host() => MaterialApp(
    home: Scaffold(
      body: BlocProvider<RoutingEditorCubit>.value(
        value: cubit,
        child: const BusLanesView(),
      ),
    ),
  );

  testWidgets('shows empty message when there are no algorithms', (
    tester,
  ) async {
    when(cubit.state).thenReturn(loadedWith(const []));
    await tester.pumpWidget(host());
    expect(find.text('No algorithms loaded.'), findsOneWidget);
  });

  testWidgets('renders lanes and a block for a loaded preset', (tester) async {
    when(cubit.state).thenReturn(loadedWith([oscWithOutput()]));
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.byType(BusLanesView), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('double-tapping an output bead toggles the output mode', (
    tester,
  ) async {
    when(cubit.state).thenReturn(loadedWith([oscWithOutput()]));
    when(
      cubit.togglePortOutputMode(portId: anyNamed('portId')),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(host());
    await tester.pump();

    await tester.tapAt(beadCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(beadCenter);
    // Drain the double-tap recognizer's timers.
    await tester.pump(const Duration(seconds: 1));

    verify(cubit.togglePortOutputMode(portId: 'a_out')).called(1);
  });

  testWidgets('selecting a bead and pressing Delete disconnects it', (
    tester,
  ) async {
    when(cubit.state).thenReturn(loadedWith([oscWithOutput()]));
    when(
      cubit.assignBusAndSolve(
        algorithmIndex: anyNamed('algorithmIndex'),
        parameterNumber: anyNamed('parameterNumber'),
        previousBusValue: anyNamed('previousBusValue'),
        busValue: anyNamed('busValue'),
      ),
    ).thenAnswer(
      (_) async => const BusAssignmentResult(
        algorithmIndex: 0,
        parameterNumber: 3,
        previousBusValue: 13,
        newBusValue: 0,
        reorder: null,
      ),
    );

    await tester.pumpWidget(host());
    await tester.pump();

    // Single tap selects (pump past the double-tap window so onTap resolves).
    await tester.tapAt(beadCenter);
    await tester.pump(const Duration(milliseconds: 400));

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    verify(
      cubit.assignBusAndSolve(
        algorithmIndex: 0,
        parameterNumber: 3,
        previousBusValue: 13,
        busValue: 0,
      ),
    ).called(1);
  });

  testWidgets('dragging an output bead to the None column disconnects it', (
    tester,
  ) async {
    when(cubit.state).thenReturn(loadedWith([oscWithOutput()]));
    when(
      cubit.assignBusAndSolve(
        algorithmIndex: anyNamed('algorithmIndex'),
        parameterNumber: anyNamed('parameterNumber'),
        previousBusValue: anyNamed('previousBusValue'),
        busValue: anyNamed('busValue'),
      ),
    ).thenAnswer(
      (_) async => const BusAssignmentResult(
        algorithmIndex: 0,
        parameterNumber: 3,
        previousBusValue: 13,
        newBusValue: 0,
        reorder: null,
      ),
    );

    await tester.pumpWidget(host());
    await tester.pump();

    await tester.dragFrom(beadCenter, noneCenter - beadCenter);
    await tester.pumpAndSettle();

    verify(
      cubit.assignBusAndSolve(
        algorithmIndex: 0,
        parameterNumber: 3,
        previousBusValue: 13,
        busValue: 0,
      ),
    ).called(1);
  });

  testWidgets('dragging an in-place output bead assigns another bus', (
    tester,
  ) async {
    when(
      cubit.state,
    ).thenReturn(loadedWith([inPlaceOutputOnInputBus(), oscWithOutput()]));
    when(
      cubit.assignBusAndSolve(
        algorithmIndex: anyNamed('algorithmIndex'),
        parameterNumber: anyNamed('parameterNumber'),
        previousBusValue: anyNamed('previousBusValue'),
        busValue: anyNamed('busValue'),
      ),
    ).thenAnswer(
      (_) async => const BusAssignmentResult(
        algorithmIndex: 0,
        parameterNumber: 1,
        previousBusValue: 5,
        newBusValue: 13,
        reorder: null,
      ),
    );

    await tester.pumpWidget(host());
    await tester.pump();

    // Visible buses are 5 and 13. The first algorithm's output row is row 1,
    // so the bead starts on bus 5 at column 1 and drops onto bus 13 at column 2.
    await tester.dragFrom(const Offset(235, 99), const Offset(42, 0));
    await tester.pumpAndSettle();

    verify(
      cubit.assignBusAndSolve(
        algorithmIndex: 0,
        parameterNumber: 1,
        previousBusValue: 5,
        busValue: 13,
      ),
    ).called(1);
  });
}
