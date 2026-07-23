import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/algorithm_controller/algorithm_controller.dart';
import 'package:nt_helper/algorithm_controller/lua_algorithm_controller_engine.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = LuaAlgorithmControllerEngine();

  test('evaluates generic UI primitives from the latest slot snapshot', () {
    const source = r'''
return {
  version = 1,
  title = algorithm.name,
  root = ui.column {
    children = {
      ui.text { text = "Steps " .. nt.parameter("1:Steps").value },
      ui.slider {
        label = "Steps",
        parameter = nt.parameter("1:Steps").number
      }
    }
  }
}
''';

    final firstDocument = engine.evaluate(
      source: source,
      slot: _euclideanSlot(steps: 16),
      slotIndex: 2,
      units: const [],
    );
    final secondDocument = engine.evaluate(
      source: source,
      slot: _euclideanSlot(steps: 11),
      slotIndex: 2,
      units: const [],
    );

    expect(firstDocument.title, 'Euclidean Patterns');
    final firstRoot = firstDocument.root as AlgorithmControllerColumn;
    final secondRoot = secondDocument.root as AlgorithmControllerColumn;
    expect(
      (firstRoot.children.first as AlgorithmControllerText).text,
      'Steps 16',
    );
    expect(
      (secondRoot.children.first as AlgorithmControllerText).text,
      'Steps 11',
    );
    expect(
      (firstRoot.children.last as AlgorithmControllerSlider).parameterNumber,
      1,
    );
  });

  test('does not expose filesystem and process libraries to controllers', () {
    const source = r'''
return {
  version = 1,
  title = "Unsafe",
  root = ui.text { text = tostring(os) }
}
''';

    final document = engine.evaluate(
      source: source,
      slot: _euclideanSlot(),
      slotIndex: 0,
      units: const [],
    );
    expect((document.root as AlgorithmControllerText).text, 'nil');
  });

  test('rejects unknown UI primitives', () {
    const source = r'''
return {
  version = 1,
  title = "Unknown",
  root = { type = "native_flutter_widget" }
}
''';

    expect(
      () => engine.evaluate(
        source: source,
        slot: _euclideanSlot(),
        slotIndex: 0,
        units: const [],
      ),
      throwsA(
        isA<LuaAlgorithmControllerException>().having(
          (error) => error.message,
          'message',
          contains('unknown UI node type'),
        ),
      ),
    );
  });

  test(
    'bundled Euclidean controller builds controls and canvas shapes',
    () async {
      final source = await rootBundle.loadString(
        'assets/algorithm_controllers/euclidean_patterns.lua',
      );

      final document = engine.evaluate(
        source: source,
        slot: _euclideanSlot(channelCount: 2),
        slotIndex: 2,
        units: const [],
      );

      final root = document.root as AlgorithmControllerColumn;
      final channelColumn = root.children.last as AlgorithmControllerColumn;
      expect(document.title, 'Euclidean Patterns');
      expect(channelColumn.children, hasLength(2));

      final firstChannel =
          channelColumn.children.first as AlgorithmControllerSection;
      expect(firstChannel.title, 'Channel 1');
      expect(
        firstChannel.children.whereType<AlgorithmControllerSlider>(),
        hasLength(3),
      );
      final canvas = firstChannel.children
          .whereType<AlgorithmControllerCanvas>()
          .single;
      expect(
        canvas.shapes.whereType<AlgorithmControllerCircle>(),
        hasLength(16),
      );
    },
  );
}

Slot _euclideanSlot({int steps = 16, int channelCount = 1}) {
  final fixtures = <({String name, int value, int min, int max})>[];
  for (var channel = 1; channel <= channelCount; channel++) {
    fixtures.addAll([
      (name: '$channel:Enable', value: channel == 1 ? 1 : 0, min: 0, max: 1),
      (name: '$channel:Steps', value: steps, min: 1, max: 32),
      (name: '$channel:Pulses', value: 4, min: 1, max: 32),
      (name: '$channel:Rotation', value: 0, min: 0, max: 32),
    ]);
  }

  return Slot(
    algorithm: Algorithm(
      algorithmIndex: 2,
      guid: 'eucp',
      name: 'Euclidean Patterns',
      specifications: [channelCount],
    ),
    routing: RoutingInfo.filler(),
    pages: ParameterPages(
      algorithmIndex: 2,
      pages: [
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
          defaultValue: fixtures[index].min,
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
          value: fixtures[index].value,
        ),
    ],
    enums: [
      for (var index = 0; index < fixtures.length; index++)
        ParameterEnumStrings(
          algorithmIndex: 2,
          parameterNumber: index,
          values: fixtures[index].name.endsWith(':Enable')
              ? const ['Off', 'On']
              : const [],
        ),
    ],
    mappings: [for (final _ in fixtures) Mapping.filler()],
    valueStrings: [for (final _ in fixtures) ParameterValueString.filler()],
  );
}
