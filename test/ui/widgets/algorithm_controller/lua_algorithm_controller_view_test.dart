import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/algorithm_controller/algorithm_controller.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/ui/widgets/algorithm_controller/lua_algorithm_controller_view.dart';
import 'package:nt_helper/ui/widgets/slot_detail_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDistingCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cubit = MockDistingCubit();
    when(() => cubit.state).thenReturn(const DistingState.initial());
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => cubit.updateParameterValue(
        algorithmIndex: any(named: 'algorithmIndex'),
        parameterNumber: any(named: 'parameterNumber'),
        value: any(named: 'value'),
        userIsChangingTheValue: any(named: 'userIsChangingTheValue'),
      ),
    ).thenAnswer((_) async {});
  });

  testWidgets('re-evaluates Lua when a new immutable Slot arrives', (
    tester,
  ) async {
    const source = r'''
return {
  version = 1,
  title = "Reactive controller",
  root = ui.text {
    text = "Snapshot value " .. nt.parameter("1:Steps").value
  }
}
''';
    var sourceLoads = 0;
    Future<String> sourceLoader(String _) async {
      sourceLoads += 1;
      return source;
    }

    await tester.pumpWidget(
      _host(cubit, _slot(steps: 16), source, sourceLoader: sourceLoader),
    );
    await tester.pumpAndSettle();
    expect(find.text('Snapshot value 16'), findsOneWidget);
    expect(sourceLoads, 1);

    await tester.pumpWidget(
      _host(cubit, _slot(steps: 9), source, sourceLoader: sourceLoader),
    );
    await tester.pumpAndSettle();
    expect(find.text('Snapshot value 16'), findsNothing);
    expect(find.text('Snapshot value 9'), findsOneWidget);
    expect(sourceLoads, 1);
  });

  testWidgets('slider and button actions write through DistingCubit', (
    tester,
  ) async {
    const source = r'''
local steps = nt.parameter("1:Steps")
return {
  version = 1,
  title = "Controls",
  root = ui.column {
    children = {
      ui.slider { label = "Steps", parameter = steps.number },
      ui.button {
        label = "Set twelve",
        action = {
          type = "set_parameter",
          parameter = steps.number,
          value = 12
        }
      }
    }
  }
}
''';

    await tester.pumpWidget(_host(cubit, _slot(steps: 16), source));
    await tester.pumpAndSettle();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 1);
    expect(slider.max, 32);
    slider.onChanged!(18);
    slider.onChangeEnd!(18);
    await tester.tap(find.text('Set twelve'));

    verify(
      () => cubit.updateParameterValue(
        algorithmIndex: 2,
        parameterNumber: 1,
        value: 18,
        userIsChangingTheValue: true,
      ),
    ).called(1);
    verify(
      () => cubit.updateParameterValue(
        algorithmIndex: 2,
        parameterNumber: 1,
        value: 18,
        userIsChangingTheValue: false,
      ),
    ).called(1);
    verify(
      () => cubit.updateParameterValue(
        algorithmIndex: 2,
        parameterNumber: 1,
        value: 12,
        userIsChangingTheValue: false,
      ),
    ).called(1);
  });

  testWidgets(
    'controller ranges and writes stay inside live parameter limits',
    (tester) async {
      const source = r'''
local steps = nt.parameter("1:Steps")
return {
  version = 1,
  title = "Clamped controls",
  root = ui.slider {
    label = "Steps",
    parameter = steps.number,
    minimum = -100,
    maximum = 100
  }
}
''';

      await tester.pumpWidget(_host(cubit, _slot(steps: 16), source));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 1);
      expect(slider.max, 32);
      slider.onChanged!(100);

      verify(
        () => cubit.updateParameterValue(
          algorithmIndex: 2,
          parameterNumber: 1,
          value: 32,
          userIsChangingTheValue: true,
        ),
      ).called(1);
    },
  );

  testWidgets('canvas supplies a semantic description', (tester) async {
    const source = r'''
return {
  version = 1,
  title = "Drawing",
  root = ui.canvas {
    semantics_label = "Four pulses across sixteen steps",
    shapes = {
      ui.circle { x = 0.5, y = 0.5, radius = 0.1, fill = "primary" }
    }
  }
}
''';

    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_host(cubit, _slot(), source));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Four pulses across sixteen steps'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('Euclidean controller is default-off and survives Slot updates', (
    tester,
  ) async {
    Widget app(Slot slot) {
      return MaterialApp(
        home: BlocProvider<DistingCubit>.value(
          value: cubit,
          child: Scaffold(
            body: SlotDetailView(
              slot: slot,
              slotIndex: 2,
              units: const [],
              firmwareVersion: FirmwareVersion('1.17.0'),
              onToggleSpreadsheetEditingMode: () {},
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(app(_slot(steps: 16, emptyPages: true)));
    await tester.pumpAndSettle();

    IconButton controllerButton() => tester.widget<IconButton>(
      find.byKey(const ValueKey('slot-editor-mode-controller')),
    );

    expect(find.byType(LuaAlgorithmControllerView), findsNothing);
    expect(controllerButton().isSelected, isFalse);

    await tester.tap(find.byKey(const ValueKey('slot-editor-mode-controller')));
    await tester.pumpAndSettle();

    expect(find.byType(LuaAlgorithmControllerView), findsOneWidget);
    expect(controllerButton().isSelected, isTrue);
    expect(find.text('16 steps · 4 pulses · rotation 0'), findsOneWidget);

    await tester.pumpWidget(app(_slot(steps: 9, emptyPages: true)));
    await tester.pumpAndSettle();

    expect(find.byType(LuaAlgorithmControllerView), findsOneWidget);
    expect(controllerButton().isSelected, isTrue);
    expect(find.text('9 steps · 4 pulses · rotation 0'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('slot-editor-mode-standard')));
    await tester.pumpAndSettle();
    expect(find.byType(LuaAlgorithmControllerView), findsNothing);
  });
}

Widget _host(
  MockDistingCubit cubit,
  Slot slot,
  String source, {
  AlgorithmControllerSourceLoader? sourceLoader,
}) {
  return MaterialApp(
    home: BlocProvider<DistingCubit>.value(
      value: cubit,
      child: Scaffold(
        body: LuaAlgorithmControllerView(
          definition: const AlgorithmControllerDefinition(
            id: 'test.controller',
            algorithmGuid: 'eucp',
            name: 'Test controller',
            assetPath: 'memory.lua',
          ),
          slot: slot,
          slotIndex: 2,
          units: const [],
          sourceLoader: sourceLoader ?? (_) async => source,
        ),
      ),
    ),
  );
}

Slot _slot({int steps = 16, bool emptyPages = false}) {
  const fixtures = [
    (name: '1:Enable', min: 0, max: 1, defaultValue: 0),
    (name: '1:Steps', min: 1, max: 32, defaultValue: 16),
    (name: '1:Pulses', min: 1, max: 32, defaultValue: 4),
    (name: '1:Rotation', min: 0, max: 32, defaultValue: 0),
  ];
  final values = [1, steps, 4, 0];
  return Slot(
    algorithm: Algorithm(
      algorithmIndex: 2,
      guid: 'eucp',
      name: 'Euclidean Patterns',
      specifications: const [1],
    ),
    routing: RoutingInfo.filler(),
    pages: ParameterPages(
      algorithmIndex: 2,
      pages: emptyPages
          ? const []
          : [
              ParameterPage(
                name: 'Patterns',
                parameters: [
                  for (var index = 0; index < fixtures.length; index++) index,
                ],
              ),
            ],
    ),
    parameters: [
      for (var index = 0; index < fixtures.length; index++)
        ParameterInfo(
          algorithmIndex: 2,
          parameterNumber: index,
          min: fixtures[index].min,
          max: fixtures[index].max,
          defaultValue: fixtures[index].defaultValue,
          unit: 0,
          name: fixtures[index].name,
          powerOfTen: 0,
        ),
    ],
    values: [
      for (var index = 0; index < fixtures.length; index++)
        ParameterValue(
          algorithmIndex: 2,
          parameterNumber: index,
          value: values[index],
        ),
    ],
    enums: [
      for (var index = 0; index < fixtures.length; index++)
        ParameterEnumStrings(
          algorithmIndex: 2,
          parameterNumber: index,
          values: index == 0 ? const ['Off', 'On'] : const [],
        ),
    ],
    mappings: [for (final _ in fixtures) Mapping.filler()],
    valueStrings: [for (final _ in fixtures) ParameterValueString.filler()],
  );
}
