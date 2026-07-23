import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/algorithm_controller/algorithm_controller.dart';
import 'package:nt_helper/algorithm_controller/lua_algorithm_controller_engine.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const engine = LuaAlgorithmControllerEngine();
  late Map<String, dynamic> tables;

  setUpAll(() async {
    final bundle =
        jsonDecode(
              await File('assets/metadata/full_metadata.json').readAsString(),
            )
            as Map<String, dynamic>;
    tables = Map<String, dynamic>.from(bundle['tables'] as Map);
  });

  test(
    'extended bundled controllers evaluate against canonical metadata',
    () async {
      const cases = [
        (
          guid: 'lfo ',
          name: 'LFO',
          asset: 'assets/algorithm_controllers/lfo.lua',
        ),
        (
          guid: 'envq',
          name: 'Envelope (DAHDSR)',
          asset: 'assets/algorithm_controllers/envelope_dahdsr.lua',
        ),
        (
          guid: 'eqpa',
          name: 'EQ Parametric',
          asset: 'assets/algorithm_controllers/parametric_eq.lua',
        ),
        (
          guid: 'mix2',
          name: 'Mixer Stereo',
          asset: 'assets/algorithm_controllers/mixer_stereo.lua',
        ),
        (
          guid: 'drea',
          name: 'Dream Machine',
          asset: 'assets/algorithm_controllers/dream_machine.lua',
        ),
        (
          guid: 'fbnk',
          name: 'Filter bank',
          asset: 'assets/algorithm_controllers/filter_bank.lua',
        ),
        (
          guid: 'xaoc',
          name: 'Chaos',
          asset: 'assets/algorithm_controllers/chaos.lua',
        ),
        (
          guid: 'quan',
          name: 'Quantizer',
          asset: 'assets/algorithm_controllers/quantizer.lua',
        ),
        (
          guid: 'ensq',
          name: 'Envelope Sequencer',
          asset: 'assets/algorithm_controllers/envelope_sequencer.lua',
        ),
        (
          guid: 'quad',
          name: 'Quadraphonic Mixer',
          asset: 'assets/algorithm_controllers/quadraphonic_mixer.lua',
        ),
      ];

      for (final testCase in cases) {
        final definition = AlgorithmControllerRegistry.bundled.findForGuid(
          testCase.guid,
        );
        expect(
          definition?.assetPath,
          testCase.asset,
          reason: 'registry mismatch for ${testCase.guid}',
        );

        final source = await File(testCase.asset).readAsString();
        final document = engine.evaluate(
          source: source,
          slot: _slotFromMetadata(
            tables,
            guid: testCase.guid,
            name: testCase.name,
          ),
          slotIndex: 7,
          units: const [],
        );
        final nodes = _flatten(document.root);

        expect(document.version, 1, reason: testCase.guid);
        expect(nodes, isNotEmpty, reason: testCase.guid);
        _expectNoControllerBypass(nodes, reason: testCase.guid);
      }
    },
  );

  test(
    'extended controllers expose their defining visual structures',
    () async {
      Future<List<AlgorithmControllerNode>> nodesFor(
        String guid,
        String name,
        String asset,
      ) async {
        final document = engine.evaluate(
          source: await File(asset).readAsString(),
          slot: _slotFromMetadata(tables, guid: guid, name: name),
          slotIndex: 7,
          units: const [],
        );
        return _flatten(document.root);
      }

      for (final testCase in const [
        (
          guid: 'lfo ',
          name: 'LFO',
          asset: 'assets/algorithm_controllers/lfo.lua',
        ),
        (
          guid: 'envq',
          name: 'Envelope (DAHDSR)',
          asset: 'assets/algorithm_controllers/envelope_dahdsr.lua',
        ),
        (
          guid: 'eqpa',
          name: 'EQ Parametric',
          asset: 'assets/algorithm_controllers/parametric_eq.lua',
        ),
        (
          guid: 'mix2',
          name: 'Mixer Stereo',
          asset: 'assets/algorithm_controllers/mixer_stereo.lua',
        ),
        (
          guid: 'drea',
          name: 'Dream Machine',
          asset: 'assets/algorithm_controllers/dream_machine.lua',
        ),
        (
          guid: 'fbnk',
          name: 'Filter bank',
          asset: 'assets/algorithm_controllers/filter_bank.lua',
        ),
        (
          guid: 'xaoc',
          name: 'Chaos',
          asset: 'assets/algorithm_controllers/chaos.lua',
        ),
        (
          guid: 'ensq',
          name: 'Envelope Sequencer',
          asset: 'assets/algorithm_controllers/envelope_sequencer.lua',
        ),
      ]) {
        final nodes = await nodesFor(
          testCase.guid,
          testCase.name,
          testCase.asset,
        );
        expect(
          nodes.whereType<AlgorithmControllerCanvas>(),
          isNotEmpty,
          reason: '${testCase.guid} should provide an illustrative preview',
        );
      }

      final quantizer = await nodesFor(
        'quan',
        'Quantizer',
        'assets/algorithm_controllers/quantizer.lua',
      );
      expect(
        quantizer.whereType<AlgorithmControllerButton>().where(
          (node) => node.label.endsWith(' on'),
        ),
        hasLength(128),
      );

      final envelopeSequencer = await nodesFor(
        'ensq',
        'Envelope Sequencer',
        'assets/algorithm_controllers/envelope_sequencer.lua',
      );
      expect(
        envelopeSequencer.whereType<AlgorithmControllerButton>().where(
          (node) =>
              node.action.type == AlgorithmControllerActionType.pulseParameter,
        ),
        hasLength(1),
      );

      final quad = await nodesFor(
        'quad',
        'Quadraphonic Mixer',
        'assets/algorithm_controllers/quadraphonic_mixer.lua',
      );
      final quadPads = quad.whereType<AlgorithmControllerXYPad>().toList();
      expect(quadPads, hasLength(4));
      expect(quadPads.every((pad) => pad.aspectRatio == 1), isTrue);

      final filterBank = await nodesFor(
        'fbnk',
        'Filter bank',
        'assets/algorithm_controllers/filter_bank.lua',
      );
      expect(
        filterBank.whereType<AlgorithmControllerButton>().map(
          (node) => node.label,
        ),
        containsAll(['12 notes down', '12 notes up']),
      );
    },
  );

  test('mode-specific controls follow the current slot snapshot', () async {
    Future<List<AlgorithmControllerNode>> nodesFor(
      String guid,
      String name,
      String asset, {
      Map<String, int> values = const {},
      Map<String, String> displayValues = const {},
    }) async {
      final document = engine.evaluate(
        source: await File(asset).readAsString(),
        slot: _slotFromMetadata(
          tables,
          guid: guid,
          name: name,
          values: values,
          displayValues: displayValues,
        ),
        slotIndex: 7,
        units: const [],
      );
      return _flatten(document.root);
    }

    final automaticScala = await nodesFor(
      'quan',
      'Quantizer',
      'assets/algorithm_controllers/quantizer.lua',
      values: const {'Microtuning': 1},
      displayValues: const {'Scala .kbm': 'Automatic'},
    );
    expect(
      automaticScala.whereType<AlgorithmControllerSlider>().map(
        (node) => node.label,
      ),
      containsAll([
        'Automatic keyboard-map root',
        'Automatic keyboard-map frequency',
      ]),
    );

    final mappedScala = await nodesFor(
      'quan',
      'Quantizer',
      'assets/algorithm_controllers/quantizer.lua',
      values: const {'Microtuning': 1},
      displayValues: const {'Scala .kbm': 'concert.kbm'},
    );
    expect(
      mappedScala.whereType<AlgorithmControllerSlider>().map(
        (node) => node.label,
      ),
      isNot(contains('Automatic keyboard-map root')),
    );
    expect(
      mappedScala.whereType<AlgorithmControllerSlider>().map(
        (node) => node.label,
      ),
      isNot(contains('Automatic keyboard-map frequency')),
    );

    final polarQuad = await nodesFor(
      'quad',
      'Quadraphonic Mixer',
      'assets/algorithm_controllers/quadraphonic_mixer.lua',
      values: const {
        '1:Coordinates': 1,
        '2:Coordinates': 1,
        '3:Coordinates': 1,
        '4:Coordinates': 1,
      },
    );
    expect(polarQuad.whereType<AlgorithmControllerXYPad>(), isEmpty);
    expect(
      polarQuad.whereType<AlgorithmControllerSlider>().where(
        (node) => node.label == 'Spinner',
      ),
      hasLength(4),
    );
  });
}

Slot _slotFromMetadata(
  Map<String, dynamic> tables, {
  required String guid,
  required String name,
  Map<String, int> values = const {},
  Map<String, String> displayValues = const {},
}) {
  const algorithmIndex = 7;
  final parameterRows =
      _rows(
        tables,
        'parameters',
      ).where((row) => row['algorithmGuid'] == guid).toList()..sort(
        (left, right) => _int(
          left['parameterNumber'],
        ).compareTo(_int(right['parameterNumber'])),
      );
  final enumRows = _rows(
    tables,
    'parameterEnums',
  ).where((row) => row['algorithmGuid'] == guid).toList();
  final enumsByParameter = <int, List<String>>{};
  for (final row in enumRows) {
    final parameterNumber = _int(row['parameterNumber']);
    final enumIndex = _int(row['enumIndex']);
    final values = enumsByParameter.putIfAbsent(
      parameterNumber,
      () => <String>[],
    );
    while (values.length <= enumIndex) {
      values.add('');
    }
    values[enumIndex] = (row['enumString'] as String? ?? '').trim();
  }

  final specificationRows =
      _rows(
        tables,
        'specifications',
      ).where((row) => row['algorithmGuid'] == guid).toList()..sort(
        (left, right) =>
            _int(left['specIndex']).compareTo(_int(right['specIndex'])),
      );
  final pageRows =
      _rows(
        tables,
        'parameterPages',
      ).where((row) => row['algorithmGuid'] == guid).toList()..sort(
        (left, right) =>
            _int(left['pageIndex']).compareTo(_int(right['pageIndex'])),
      );
  final pageItemRows = _rows(
    tables,
    'parameterPageItems',
  ).where((row) => row['algorithmGuid'] == guid).toList();

  return Slot(
    algorithm: Algorithm(
      algorithmIndex: algorithmIndex,
      guid: guid,
      name: name,
      specifications: [
        for (final row in specificationRows) _int(row['defaultValue']),
      ],
    ),
    routing: RoutingInfo.filler(),
    pages: ParameterPages(
      algorithmIndex: algorithmIndex,
      pages: [
        for (final page in pageRows)
          ParameterPage(
            name: page['name'] as String? ?? '',
            parameters: [
              for (final item in pageItemRows)
                if (_int(item['pageIndex']) == _int(page['pageIndex']))
                  _int(item['parameterNumber']),
            ]..sort(),
          ),
      ],
    ),
    parameters: [
      for (final row in parameterRows)
        ParameterInfo(
          algorithmIndex: algorithmIndex,
          parameterNumber: _int(row['parameterNumber']),
          min: _int(row['minValue']),
          max: _int(row['maxValue']),
          defaultValue: _int(row['defaultValue']),
          unit: _int(row['rawUnitIndex']),
          name: row['name'] as String? ?? '',
          powerOfTen: _int(row['powerOfTen']),
          ioFlags: _int(row['ioFlags']),
        ),
    ],
    values: [
      for (final row in parameterRows)
        ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: _int(row['parameterNumber']),
          value:
              values[row['name'] as String? ?? ''] ?? _int(row['defaultValue']),
        ),
    ],
    enums: [
      for (final row in parameterRows)
        ParameterEnumStrings(
          algorithmIndex: algorithmIndex,
          parameterNumber: _int(row['parameterNumber']),
          values: enumsByParameter[_int(row['parameterNumber'])] ?? const [],
        ),
    ],
    mappings: [for (final _ in parameterRows) Mapping.filler()],
    valueStrings: [
      for (final row in parameterRows)
        ParameterValueString(
          algorithmIndex: algorithmIndex,
          parameterNumber: _int(row['parameterNumber']),
          value: displayValues[row['name'] as String? ?? ''] ?? '',
        ),
    ],
  );
}

List<Map<String, dynamic>> _rows(Map<String, dynamic> tables, String name) => [
  for (final row in tables[name] as List) Map<String, dynamic>.from(row as Map),
];

int _int(Object? value) => (value as num?)?.toInt() ?? 0;

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
      case AlgorithmControllerXYPad():
        break;
    }
  }

  visit(root);
  return nodes;
}

void _expectNoControllerBypass(
  List<AlgorithmControllerNode> nodes, {
  required String reason,
}) {
  for (final node in nodes) {
    final parameterNumbers = switch (node) {
      AlgorithmControllerSlider(:final parameterNumber) => [parameterNumber],
      AlgorithmControllerChoice(:final parameterNumber) => [parameterNumber],
      AlgorithmControllerToggle(:final parameterNumber) => [parameterNumber],
      AlgorithmControllerButton(:final action) => [action.parameterNumber],
      AlgorithmControllerXYPad(
        :final xParameterNumber,
        :final yParameterNumber,
      ) =>
        [xParameterNumber, yParameterNumber],
      _ => const <int>[],
    };
    expect(parameterNumbers, isNot(contains(0)), reason: reason);
  }
}
