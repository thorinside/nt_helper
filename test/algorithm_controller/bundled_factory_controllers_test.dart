import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/algorithm_controller/algorithm_controller.dart';
import 'package:nt_helper/algorithm_controller/lua_algorithm_controller_engine.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = LuaAlgorithmControllerEngine();

  test('registry exposes the complete bundled controller set', () {
    for (final guid in ['eucp', 'clck', 'clkd', 'attn', 'xfad']) {
      expect(
        AlgorithmControllerRegistry.bundled.findForGuid(guid),
        isNotNull,
        reason: 'missing controller for $guid',
      );
    }
  });

  test('minimum factory controller configurations evaluate', () async {
    final cases = [
      (
        asset: 'assets/algorithm_controllers/attenuverter.lua',
        slot: _attenuverterSlot(1),
      ),
      (
        asset: 'assets/algorithm_controllers/clock_divider.lua',
        slot: _clockDividerSlot(1),
      ),
      (asset: 'assets/algorithm_controllers/clock.lua', slot: _clockSlot(1)),
      (
        asset: 'assets/algorithm_controllers/crossfader.lua',
        slot: _crossfaderSlot(inputCount: 2, externalCv: false),
      ),
    ];

    for (final testCase in cases) {
      final document = await _evaluate(engine, testCase.asset, testCase.slot);
      expect(document.version, 1);
      _expectNoControllerBypass(_flatten(document.root));
    }
  });

  test(
    'maximum-channel Attenuverter builds focused channel sections',
    () async {
      final document = await _evaluate(
        engine,
        'assets/algorithm_controllers/attenuverter.lua',
        _attenuverterSlot(12),
      );
      final nodes = _flatten(document.root);

      expect(nodes.whereType<AlgorithmControllerSection>(), hasLength(12));
      expect(nodes.whereType<AlgorithmControllerCanvas>(), hasLength(12));
      expect(nodes.whereType<AlgorithmControllerButton>(), hasLength(36));
      _expectNoControllerBypass(nodes);
    },
  );

  test(
    'maximum-channel Clock Divider selects the active divisor controls',
    () async {
      final document = await _evaluate(
        engine,
        'assets/algorithm_controllers/clock_divider.lua',
        _clockDividerSlot(8),
      );
      final nodes = _flatten(document.root);

      expect(nodes.whereType<AlgorithmControllerSection>(), hasLength(8));
      expect(nodes.whereType<AlgorithmControllerCanvas>(), hasLength(8));
      expect(
        nodes.whereType<AlgorithmControllerChoice>().map((node) => node.label),
        containsAll(['Type', 'Divisor']),
      );
      _expectNoControllerBypass(nodes);
    },
  );

  test(
    'maximum-output Clock builds common, swing, and output sections',
    () async {
      final document = await _evaluate(
        engine,
        'assets/algorithm_controllers/clock.lua',
        _clockSlot(8),
      );
      final nodes = _flatten(document.root);
      final sections = nodes.whereType<AlgorithmControllerSection>().toList();

      expect(sections, hasLength(10));
      expect(sections.map((section) => section.title), contains('Clock'));
      expect(sections.map((section) => section.title), contains('Swing'));
      expect(sections.map((section) => section.title), contains('Output 8'));
      expect(nodes.whereType<AlgorithmControllerCanvas>(), hasLength(9));
      expect(
        nodes.whereType<AlgorithmControllerChoice>().where(
          (node) => node.label == 'Divisor',
        ),
        hasLength(2),
      );
      expect(
        nodes.whereType<AlgorithmControllerChoice>().where(
          (node) => node.label == 'Ratchet mode',
        ),
        hasLength(2),
      );
      expect(
        nodes.whereType<AlgorithmControllerSlider>().where(
          (node) => node.label == 'Trigger length',
        ),
        hasLength(4),
      );
      _expectNoControllerBypass(nodes);
    },
  );

  test('Clock handles every source and swing mode condition', () async {
    for (var source = 0; source <= 2; source++) {
      for (var swingType = 0; swingType <= 7; swingType++) {
        final document = await _evaluate(
          engine,
          'assets/algorithm_controllers/clock.lua',
          _clockSlot(1, source: source, swingType: swingType),
        );
        final nodes = _flatten(document.root);
        final tempo = nodes.whereType<AlgorithmControllerSlider>().singleWhere(
          (node) => node.label == 'Tempo',
        );
        final tuplePositions = nodes
            .whereType<AlgorithmControllerSlider>()
            .where((node) => node.label.startsWith('16th note'));

        expect(tempo.enabled, source == 0);
        expect(tuplePositions.length, swingType >= 3 ? 3 : 0);
      }
    }
  });

  test(
    'Crossfader builds curve preview and one jump per configured input',
    () async {
      final document = await _evaluate(
        engine,
        'assets/algorithm_controllers/crossfader.lua',
        _crossfaderSlot(inputCount: 12, externalCv: true),
      );
      final nodes = _flatten(document.root);

      expect(nodes.whereType<AlgorithmControllerSection>(), hasLength(1));
      expect(nodes.whereType<AlgorithmControllerCanvas>(), hasLength(1));
      expect(nodes.whereType<AlgorithmControllerButton>(), hasLength(12));
      expect(
        nodes.whereType<AlgorithmControllerText>().map((node) => node.text),
        contains(
          'Preview excludes the contribution from the assigned external crossfade CV.',
        ),
      );
      _expectNoControllerBypass(nodes);
    },
  );
}

Future<AlgorithmControllerDocument> _evaluate(
  LuaAlgorithmControllerEngine engine,
  String asset,
  Slot slot,
) async {
  final source = await rootBundle.loadString(asset);
  return engine.evaluate(
    source: source,
    slot: slot,
    slotIndex: slot.algorithm.algorithmIndex,
    units: const [],
  );
}

List<AlgorithmControllerNode> _flatten(AlgorithmControllerNode root) {
  final nodes = <AlgorithmControllerNode>[];

  void visit(AlgorithmControllerNode node) {
    nodes.add(node);
    switch (node) {
      case AlgorithmControllerColumn(:final children):
      case AlgorithmControllerRow(:final children):
      case AlgorithmControllerSection(:final children):
        children.forEach(visit);
      case AlgorithmControllerText():
      case AlgorithmControllerSlider():
      case AlgorithmControllerChoice():
      case AlgorithmControllerToggle():
      case AlgorithmControllerButton():
      case AlgorithmControllerDivider():
      case AlgorithmControllerSpacer():
      case AlgorithmControllerCanvas():
        break;
    }
  }

  visit(root);
  return nodes;
}

void _expectNoControllerBypass(List<AlgorithmControllerNode> nodes) {
  for (final node in nodes) {
    final parameterNumber = switch (node) {
      AlgorithmControllerSlider(:final parameterNumber) => parameterNumber,
      AlgorithmControllerChoice(:final parameterNumber) => parameterNumber,
      AlgorithmControllerToggle(:final parameterNumber) => parameterNumber,
      AlgorithmControllerButton(:final action) => action.parameterNumber,
      _ => null,
    };
    expect(parameterNumber, isNot(0));
  }
}

Slot _attenuverterSlot(int channels) {
  final builder = _SlotBuilder(guid: 'attn', name: 'Attenuverter');
  for (var channel = 1; channel <= channels; channel++) {
    builder
      ..add(
        '$channel:Enable',
        value: channel == 1 ? 1 : 0,
        max: 1,
        enums: const ['Off', 'On'],
      )
      ..add('$channel:Scale', value: 1000, min: -2000, max: 2000)
      ..add('$channel:Offset', value: 0, min: -100, max: 100)
      ..add('$channel:Fine', value: 0, min: -1000, max: 1000)
      ..add('$channel:Octaves', value: 0, min: -10, max: 10)
      ..add('$channel:Semitones', value: 0, min: -60, max: 60);
  }
  return builder.build(specifications: [channels]);
}

Slot _clockDividerSlot(int channels) {
  final builder = _SlotBuilder(guid: 'clkd', name: 'Clock divider');
  for (var channel = 1; channel <= channels; channel++) {
    final type = (channel - 1) % 3;
    builder
      ..add(
        '$channel:Type',
        value: type,
        max: 2,
        enums: const ['Free', 'Metrical (2)', 'Metrical (2,3)'],
      )
      ..add('$channel:Divisor', value: 2, min: 1, max: 32)
      ..add(
        '$channel:Divisor',
        value: 1,
        max: 5,
        enums: const ['1', '2', '4', '8', '16', '32'],
      )
      ..add(
        '$channel:Divisor',
        value: 2,
        max: 9,
        enums: const ['1', '2', '3', '4', '6', '8', '12', '16', '24', '32'],
      )
      ..add(
        '$channel:Enable',
        value: channel == 1 ? 1 : 0,
        max: 1,
        enums: const ['Off', 'On'],
      );
  }
  return builder.build(specifications: [channels]);
}

Slot _clockSlot(int outputs, {int source = 0, int swingType = 3}) {
  final builder = _SlotBuilder(guid: 'clck', name: 'Clock')
    ..add(
      'Source',
      value: source,
      max: 2,
      enums: const ['Internal', 'External', 'MIDI'],
    )
    ..add('Tempo', value: 1200, min: 300, max: 2400, display: '120.0 BPM')
    ..add('Run', value: 1, max: 1, enums: const ['Off', 'On'])
    ..add('Time sig numerator', value: 4, min: 1, max: 99)
    ..add(
      'Time sig denominator',
      value: 2,
      max: 4,
      enums: const ['1', '2', '4', '8', '16'],
    )
    ..add(
      'Swing type',
      value: swingType,
      max: 7,
      enums: const [
        'None',
        '16ths',
        '8ths',
        'Pentuplet',
        'Sextuplet',
        'Septuplet',
        'Octuplet',
        'Nonuplet',
      ],
    )
    ..add('Swing', value: 120, min: -1000, max: 1000, display: '12.0%')
    ..add('16th note 1', value: 2, min: 2, max: 9)
    ..add('16th note 2', value: 4, min: 2, max: 9)
    ..add('16th note 3', value: 5, min: 2, max: 9);

  const outputTypes = ['Clock', 'Run/stop', 'Reset', 'Trigger'];
  const divisors = [
    '1/64T',
    '1/32T',
    '1/32',
    '1/16T',
    '1/16',
    '1/8T',
    '1/8',
    '1/4T',
    '3/16',
    '1/4',
    '1/2T',
    '3/8',
    '1/2',
    '1/1T',
    '3/4',
    '1/1',
    '3/2',
    '2/1',
    '3/1',
    '4/1',
  ];
  for (var output = 1; output <= outputs; output++) {
    final type = (output - 1) % outputTypes.length;
    builder
      ..add(
        '$output:Enable',
        value: output == 1 ? 1 : 0,
        max: 1,
        enums: const ['Off', 'On'],
      )
      ..add('$output:Type', value: type, max: 3, enums: outputTypes)
      ..add('$output:Divisor', value: 9, max: 19, enums: divisors)
      ..add('$output:Low voltage', value: 0, min: -100, max: 100)
      ..add('$output:High voltage', value: 50, min: -100, max: 100)
      ..add(
        '$output:Ratchet mode',
        value: 2,
        max: 2,
        enums: const ['Off', 'Twos', 'Twos and threes'],
      )
      ..add('$output:Ratchet', value: 3, max: 7, display: '4')
      ..add('$output:Trigger length', value: 10, min: 1, max: 100);
  }
  return builder.build(specifications: [outputs]);
}

Slot _crossfaderSlot({required int inputCount, required bool externalCv}) {
  return (_SlotBuilder(guid: 'xfad', name: 'Crossfader')
        ..add('Width', value: 1, min: 1, max: 8)
        ..add('Crossfade input', value: externalCv ? 1 : 0, max: 64)
        ..add('Crossfader', value: 500, max: 1000, display: '50.0%')
        ..add(
          'Curve',
          value: 1,
          max: 2,
          enums: const ['Equal gain', 'Equal power', 'Transition'],
        )
        ..add('Number of inputs', value: inputCount, min: 2, max: 12))
      .build();
}

final class _SlotBuilder {
  _SlotBuilder({required this.guid, required this.name}) {
    add('Bypass', value: 0, max: 1, enums: const ['Off', 'On']);
  }

  final String guid;
  final String name;
  final List<_ParameterFixture> _parameters = [];

  void add(
    String name, {
    required int value,
    int min = 0,
    int max = 100,
    List<String> enums = const [],
    String display = '',
  }) {
    _parameters.add(
      _ParameterFixture(
        name: name,
        value: value,
        min: min,
        max: max,
        enums: enums,
        display: display,
      ),
    );
  }

  Slot build({List<int> specifications = const []}) {
    return Slot(
      algorithm: Algorithm(
        algorithmIndex: 3,
        guid: guid,
        name: name,
        specifications: specifications,
      ),
      routing: RoutingInfo.filler(),
      pages: ParameterPages(
        algorithmIndex: 3,
        pages: [
          ParameterPage(
            name: 'Parameters',
            parameters: [
              for (var number = 1; number < _parameters.length; number++)
                number,
            ],
          ),
          ParameterPage(name: 'Algorithm', parameters: const [0]),
        ],
      ),
      parameters: [
        for (final (number, fixture) in _parameters.indexed)
          ParameterInfo(
            algorithmIndex: 3,
            parameterNumber: number,
            min: fixture.min,
            max: fixture.max,
            defaultValue: fixture.value,
            unit: 0,
            name: fixture.name,
            powerOfTen: 0,
          ),
      ],
      values: [
        for (final (number, fixture) in _parameters.indexed)
          ParameterValue(
            algorithmIndex: 3,
            parameterNumber: number,
            value: fixture.value,
          ),
      ],
      enums: [
        for (final (number, fixture) in _parameters.indexed)
          ParameterEnumStrings(
            algorithmIndex: 3,
            parameterNumber: number,
            values: fixture.enums,
          ),
      ],
      mappings: [for (final _ in _parameters) Mapping.filler()],
      valueStrings: [
        for (final (number, fixture) in _parameters.indexed)
          ParameterValueString(
            algorithmIndex: 3,
            parameterNumber: number,
            value: fixture.display,
          ),
      ],
    );
  }
}

final class _ParameterFixture {
  const _ParameterFixture({
    required this.name,
    required this.value,
    required this.min,
    required this.max,
    required this.enums,
    required this.display,
  });

  final String name;
  final int value;
  final int min;
  final int max;
  final List<String> enums;
  final String display;
}
