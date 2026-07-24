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
          guid: 'env2',
          name: 'Envelope (AR/AD)',
          asset: 'assets/algorithm_controllers/envelope_ar_ad.lua',
        ),
        (
          guid: 'djfi',
          name: 'DJ Filter',
          asset: 'assets/algorithm_controllers/dj_filter.lua',
        ),
        (
          guid: 'eqpa',
          name: 'EQ Parametric',
          asset: 'assets/algorithm_controllers/parametric_eq.lua',
        ),
        (
          guid: 'mix1',
          name: 'Mixer Mono',
          asset: 'assets/algorithm_controllers/mixer_mono.lua',
        ),
        (
          guid: 'mix2',
          name: 'Mixer Stereo',
          asset: 'assets/algorithm_controllers/mixer_stereo.lua',
        ),
        (
          guid: 'mac2',
          name: 'Macro Oscillator 2',
          asset: 'assets/algorithm_controllers/macro_oscillator_2.lua',
        ),
        (
          guid: 'pym2',
          name: 'Poly Macro Oscillator 2',
          asset: 'assets/algorithm_controllers/macro_oscillator_2.lua',
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
        (
          guid: 'ssjw',
          name: 'Seaside Jawari',
          asset: 'assets/algorithm_controllers/seaside_jawari.lua',
        ),
        (
          guid: 'stpw',
          name: 'Stopwatch',
          asset: 'assets/algorithm_controllers/stopwatch.lua',
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
      expect(quantizer.whereType<AlgorithmControllerNoteMask>(), hasLength(1));
      final noteMask = quantizer
          .whereType<AlgorithmControllerNoteMask>()
          .single;
      expect(noteMask.layout, AlgorithmControllerNoteMaskLayout.piano);
      expect(noteMask.notes, hasLength(12));
      expect(quantizer.whereType<AlgorithmControllerButton>(), isEmpty);

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

  test('new controllers expose focused, truthful interaction models', () async {
    Future<List<AlgorithmControllerNode>> nodesFor(
      String guid,
      String name,
      String asset, {
      Map<String, int> values = const {},
    }) async {
      final document = engine.evaluate(
        source: await File(asset).readAsString(),
        slot: _slotFromMetadata(tables, guid: guid, name: name, values: values),
        slotIndex: 7,
        units: const [],
      );
      return _flatten(document.root);
    }

    final envelope = await nodesFor(
      'env2',
      'Envelope (AR/AD)',
      'assets/algorithm_controllers/envelope_ar_ad.lua',
    );
    final envelopeCanvas = envelope
        .whereType<AlgorithmControllerCanvas>()
        .single;
    expect(envelopeCanvas.aspectRatio, 6);
    expect(envelopeCanvas.semanticsLabel, contains('not live output'));
    expect(envelopeCanvas.semanticsLabel, contains('externally held gate'));
    expect(
      envelope.whereType<AlgorithmControllerSection>().first.title,
      'Envelope shape',
    );

    final independentEnvelope = await nodesFor(
      'env2',
      'Envelope (AR/AD)',
      'assets/algorithm_controllers/envelope_ar_ad.lua',
      values: const {'Time mode': 2},
    );
    final independentLabels = independentEnvelope
        .whereType<AlgorithmControllerSlider>()
        .map((node) => node.label);
    expect(independentLabels, containsAll(['Attack time', 'Release time']));
    expect(independentLabels, isNot(contains('Joint time')));

    final djFilter = await nodesFor(
      'djfi',
      'DJ Filter',
      'assets/algorithm_controllers/dj_filter.lua',
    );
    final djPad = djFilter.whereType<AlgorithmControllerXYPad>().single;
    expect(djPad.aspectRatio, 1.6);
    expect(djPad.xLabel, 'Sweep');
    expect(djPad.yLabel, 'Resonance');
    expect(
      djFilter.whereType<AlgorithmControllerSlider>().map((node) => node.label),
      containsAll(['Sweep', 'Resonance']),
    );

    final monoMixer = await nodesFor(
      'mix1',
      'Mixer Mono',
      'assets/algorithm_controllers/mixer_mono.lua',
    );
    final mixerSections = monoMixer
        .whereType<AlgorithmControllerSection>()
        .toList();
    expect(
      mixerSections.map((section) => section.title),
      containsAll(['Main mix', 'Aux sends', 'Channel 1']),
    );
    expect(mixerSections.take(2).map((section) => section.title), [
      'Main mix',
      'Aux sends',
    ]);
    expect(
      monoMixer.whereType<AlgorithmControllerCanvas>().single.semanticsLabel,
      contains('not live signal meters'),
    );

    for (final testCase in const [
      (
        guid: 'mac2',
        name: 'Macro Oscillator 2',
        asset: 'assets/algorithm_controllers/macro_oscillator_2.lua',
      ),
      (
        guid: 'pym2',
        name: 'Poly Macro Oscillator 2',
        asset: 'assets/algorithm_controllers/macro_oscillator_2.lua',
      ),
    ]) {
      final macro = await nodesFor(
        testCase.guid,
        testCase.name,
        testCase.asset,
      );
      final pad = macro.whereType<AlgorithmControllerXYPad>().single;
      expect(pad.aspectRatio, 1, reason: testCase.guid);
      expect(pad.xLabel, 'Timbre', reason: testCase.guid);
      expect(pad.yLabel, 'Morph', reason: testCase.guid);
      expect(
        macro.whereType<AlgorithmControllerSection>().map(
          (section) => section.title,
        ),
        containsAll(['Engine', 'Tone', 'Voice', 'Modulation depth']),
        reason: testCase.guid,
      );
      expect(
        macro.whereType<AlgorithmControllerSlider>().map((node) => node.label),
        contains('Model'),
        reason: '${testCase.guid} keeps its 24 models compact',
      );
      expect(
        macro.whereType<AlgorithmControllerChoice>().map((node) => node.label),
        isNot(contains('Model')),
        reason: '${testCase.guid} must not render 24 model chips',
      );
    }

    final jawari = await nodesFor(
      'ssjw',
      'Seaside Jawari',
      'assets/algorithm_controllers/seaside_jawari.lua',
    );
    final jawariButtons = jawari
        .whereType<AlgorithmControllerButton>()
        .toList();
    expect(
      jawariButtons.map((button) => button.label),
      containsAll(['Strum next string', 'Reset string sequence']),
    );
    expect(
      jawariButtons.every(
        (button) =>
            button.action.type == AlgorithmControllerActionType.pulseParameter,
      ),
      isTrue,
    );
    expect(
      jawari.whereType<AlgorithmControllerText>().map((node) => node.text),
      isNot(anyElement(contains('current string'))),
    );

    final stopwatch = await nodesFor(
      'stpw',
      'Stopwatch',
      'assets/algorithm_controllers/stopwatch.lua',
    );
    expect(
      stopwatch.whereType<AlgorithmControllerToggle>().map(
        (node) => node.label,
      ),
      contains('Run while gate is on'),
    );
    expect(
      stopwatch.whereType<AlgorithmControllerSlider>(),
      isEmpty,
      reason: 'countdown fields stay hidden in timer mode',
    );
    expect(
      stopwatch.whereType<AlgorithmControllerText>().map((node) => node.text),
      anyElement(contains('does not receive a live clock')),
    );
    expect(
      stopwatch.whereType<AlgorithmControllerSection>().map(
        (section) => section.title,
      ),
      ['Controls', 'Setup'],
    );

    final countdownStopwatch = await nodesFor(
      'stpw',
      'Stopwatch',
      'assets/algorithm_controllers/stopwatch.lua',
      values: const {'Mode': 1, 'Start/stop mode': 1},
    );
    expect(
      countdownStopwatch.whereType<AlgorithmControllerSlider>().map(
        (node) => node.label,
      ),
      containsAll([
        'Countdown hours',
        'Countdown minutes',
        'Countdown seconds',
      ]),
    );
    expect(countdownStopwatch.whereType<AlgorithmControllerToggle>(), isEmpty);
    expect(
      countdownStopwatch.whereType<AlgorithmControllerButton>().map(
        (node) => node.label,
      ),
      containsAll(['Trigger start or stop', 'Reset countdown']),
    );
    expect(
      countdownStopwatch.whereType<AlgorithmControllerSection>().map(
        (section) => section.title,
      ),
      ['Controls', 'Setup', 'Countdown'],
      reason: 'stable sections retain their paths when Countdown appears',
    );
  });

  test(
    'new controllers bind only their intentional behavior vocabulary',
    () async {
      const allowedNames = <String, Set<String>>{
        'env2': {
          'Trigger mode',
          'Time mode',
          'Joint time',
          'Attack time',
          'Release time',
          'Attack shape',
          'Release shape',
          'Enable',
          'Amplitude',
          'Offset',
          'Velocity depth',
        },
        'djfi': {'Sweep', 'Resonance'},
        'mix1': {
          'Output gain',
          'Pre/post',
          'Gain',
          'Mute',
          'Solo',
          'Send gain',
        },
        'mac2': {
          'Model',
          'Coarse tune',
          'Fine tune',
          'Harmonics',
          'Timbre',
          'Morph',
          'FM',
          'Timbre mod',
          'Morph mod',
          'Low-pass gate',
          'Time/decay',
        },
        'pym2': {
          'Model',
          'Coarse tune',
          'Fine tune',
          'Harmonics',
          'Timbre',
          'Morph',
          'FM',
          'Timbre mod',
          'Morph mod',
          'Low-pass gate',
          'Time/decay',
        },
        'ssjw': {
          'Bridge shape',
          'Tuning (1st string)',
          'Transpose',
          'Fine tune',
          'Strum',
          'Reset',
          'Velocity',
          'Damping',
          'Length',
          'Bounce count',
          'Strum level',
          'Bounce level',
          'Start harmonic',
          'End harmonic',
          'Strum type',
        },
        'stpw': {
          'Mode',
          'Start/stop mode',
          'Hours',
          'Minutes',
          'Seconds',
          'Start/stop',
          'Reset',
        },
      };
      const cases = [
        (
          guid: 'env2',
          name: 'Envelope (AR/AD)',
          asset: 'assets/algorithm_controllers/envelope_ar_ad.lua',
          values: <String, int>{},
        ),
        (
          guid: 'env2',
          name: 'Envelope (AR/AD)',
          asset: 'assets/algorithm_controllers/envelope_ar_ad.lua',
          values: {'Time mode': 2},
        ),
        (
          guid: 'djfi',
          name: 'DJ Filter',
          asset: 'assets/algorithm_controllers/dj_filter.lua',
          values: <String, int>{},
        ),
        (
          guid: 'mix1',
          name: 'Mixer Mono',
          asset: 'assets/algorithm_controllers/mixer_mono.lua',
          values: <String, int>{},
        ),
        (
          guid: 'mac2',
          name: 'Macro Oscillator 2',
          asset: 'assets/algorithm_controllers/macro_oscillator_2.lua',
          values: <String, int>{},
        ),
        (
          guid: 'pym2',
          name: 'Poly Macro Oscillator 2',
          asset: 'assets/algorithm_controllers/macro_oscillator_2.lua',
          values: <String, int>{},
        ),
        (
          guid: 'ssjw',
          name: 'Seaside Jawari',
          asset: 'assets/algorithm_controllers/seaside_jawari.lua',
          values: <String, int>{},
        ),
        (
          guid: 'stpw',
          name: 'Stopwatch',
          asset: 'assets/algorithm_controllers/stopwatch.lua',
          values: <String, int>{},
        ),
        (
          guid: 'stpw',
          name: 'Stopwatch',
          asset: 'assets/algorithm_controllers/stopwatch.lua',
          values: {'Mode': 1, 'Start/stop mode': 1},
        ),
      ];

      for (final testCase in cases) {
        final slot = _slotFromMetadata(
          tables,
          guid: testCase.guid,
          name: testCase.name,
          values: testCase.values,
        );
        final document = engine.evaluate(
          source: await File(testCase.asset).readAsString(),
          slot: slot,
          slotIndex: 7,
          units: const [],
        );
        final parametersByNumber = {
          for (final parameter in slot.parameters)
            parameter.parameterNumber: parameter,
        };

        for (final parameterNumber in _boundParameterNumbers(
          _flatten(document.root),
        )) {
          final parameter = parametersByNumber[parameterNumber]!;
          final name = parameter.name.split(':').last;
          expect(
            allowedNames[testCase.guid],
            contains(name),
            reason:
                '${testCase.guid} unexpectedly exposes '
                '${parameter.name} ($parameterNumber)',
          );
          expect(
            parameter.ioFlags,
            0,
            reason:
                '${testCase.guid} must not expose '
                '${parameter.name} ($parameterNumber) as I/O',
          );
        }
      }
    },
  );

  test('Dream Machine shows truthful configured voice readouts', () async {
    Future<List<AlgorithmControllerText>> readouts({
      Map<String, int> values = const {},
    }) async {
      final document = engine.evaluate(
        source: await File(
          'assets/algorithm_controllers/dream_machine.lua',
        ).readAsString(),
        slot: _slotFromMetadata(
          tables,
          guid: 'drea',
          name: 'Dream Machine',
          values: values,
        ),
        slotIndex: 7,
        units: const [],
      );
      final nodes = _flatten(document.root);
      expect(nodes.whereType<AlgorithmControllerCanvas>(), isEmpty);
      return nodes.whereType<AlgorithmControllerText>().toList();
    }

    expect((await readouts()).map((node) => node.text), [
      'Fundamental\n58.27 Hz\n1/1\nGate Off',
      'Tone 1\n76.48 Hz\n21/16\nGate Off',
      'Tone 2\n101.97 Hz\n7/4\nGate Off',
      'Tone 3\n112.90 Hz\n31/16\nGate Off',
      'Tone 4\n114.72 Hz\n63/32\nGate Off',
    ]);
    expect(
      (await readouts(
        values: const {'Numerator 1': 48},
      )).map((node) => node.text),
      contains('Tone 1\n87.41 Hz\n3/2\nGate Off'),
    );
    expect(
      (await readouts(
        values: const {'Transpose': 12, 'Gate 1': 1, 'Gain 1': 6},
      )).map((node) => node.text),
      [
        'Fundamental\n116.54 Hz\n1/1\nGate Off',
        'Tone 1\n152.96 Hz\n21/16\nGate On',
        'Tone 2\n203.95 Hz\n7/4\nGate Off',
        'Tone 3\n225.80 Hz\n31/16\nGate Off',
        'Tone 4\n229.44 Hz\n63/32\nGate Off',
      ],
    );
  });

  test(
    'Filter Bank chart maps frequency and engineering gain honestly',
    () async {
      Future<AlgorithmControllerCanvas> chart({
        Map<String, int> values = const {},
      }) async {
        final document = engine.evaluate(
          source: await File(
            'assets/algorithm_controllers/filter_bank.lua',
          ).readAsString(),
          slot: _slotFromMetadata(
            tables,
            guid: 'fbnk',
            name: 'Filter bank',
            values: values,
          ),
          slotIndex: 7,
          units: const [],
        );
        return _flatten(
          document.root,
        ).whereType<AlgorithmControllerCanvas>().single;
      }

      final configured = await chart(
        values: const {
          '1:Pitch': 0,
          '1:Gain': -400,
          '2:Pitch': 69,
          '2:Gain': 0,
          '3:Pitch': 127,
          '3:Gain': 240,
        },
      );
      final markers = configured.shapes
          .whereType<AlgorithmControllerCircle>()
          .toList();
      expect(markers[0].x, closeTo(0.06, 1e-9));
      expect(markers[0].y, closeTo(0.90, 1e-9));
      expect(markers[1].x, closeTo(0.5381102362, 1e-9));
      expect(markers[1].y, closeTo(0.40, 1e-9));
      expect(markers[2].x, closeTo(0.94, 1e-9));
      expect(markers[2].y, closeTo(0.10, 1e-9));
      expect(markers.map((marker) => marker.radius).toSet(), {0.026});
      expect(configured.semanticsLabel, contains('independent'));
      expect(configured.semanticsLabel, contains('not a summed response'));
      expect(configured.semanticsLabel, contains('live envelope'));
      expect(configured.semanticsLabel, contains('bandwidth is not available'));
      expect(
        configured.shapes.whereType<AlgorithmControllerLine>().where(
          (line) => line.x1 != line.x2 && line.y1 != line.y2,
        ),
        isEmpty,
      );

      final multiband = await chart(values: const {'Mode': 2});
      expect(multiband.semanticsLabel, contains('crossover'));

      final scala = await chart(values: const {'Microtuning': 1});
      expect(scala.semanticsLabel, contains('reference axis'));
      expect(
        scala.semanticsLabel,
        contains('actual frequencies are unavailable'),
      );
    },
  );

  test(
    'Quantizer maps scale degrees and excludes all routing controls',
    () async {
      final document = engine.evaluate(
        source: await File(
          'assets/algorithm_controllers/quantizer.lua',
        ).readAsString(),
        slot: _slotFromMetadata(
          tables,
          guid: 'quan',
          name: 'Quantizer',
          values: const {'Key': 2, 'Mode': 1, 'Scale': 3},
          disabledParameters: const {29, 30, 31, 32, 33},
        ),
        slotIndex: 7,
        units: const [],
      );
      final nodes = _flatten(document.root);
      final noteMask = nodes.whereType<AlgorithmControllerNoteMask>().single;

      expect(noteMask.layout, AlgorithmControllerNoteMaskLayout.piano);
      expect(
        [
          for (final note in noteMask.notes)
            (note.parameterNumber, note.pitchClass, note.label),
        ],
        [
          (22, 2, 'D'),
          (23, 4, 'E'),
          (24, 6, 'F sharp'),
          (25, 7, 'G'),
          (26, 9, 'A'),
          (27, 11, 'B'),
          (28, 1, 'C sharp'),
        ],
      );
      expect(
        nodes.whereType<AlgorithmControllerSection>().map(
          (section) => section.title,
        ),
        isNot(contains('Channels')),
      );

      final bindings = _boundParameterNumbers(nodes);
      expect(bindings, containsAll([150, 151]));
      for (var parameter = 16; parameter <= 20; parameter++) {
        expect(bindings, isNot(contains(parameter)));
      }
      for (var parameter = 152; parameter <= 163; parameter++) {
        expect(bindings, isNot(contains(parameter)));
      }
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
  Set<int> disabledParameters = const {},
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
          isDisabled: disabledParameters.contains(_int(row['parameterNumber'])),
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
      case AlgorithmControllerNoteMask():
        break;
    }
  }

  visit(root);
  return nodes;
}

Set<int> _boundParameterNumbers(Iterable<AlgorithmControllerNode> nodes) => {
  for (final node in nodes)
    ...switch (node) {
      AlgorithmControllerSlider(:final parameterNumber) => [parameterNumber],
      AlgorithmControllerChoice(:final parameterNumber) => [parameterNumber],
      AlgorithmControllerToggle(:final parameterNumber) => [parameterNumber],
      AlgorithmControllerButton(:final action) => [action.parameterNumber],
      AlgorithmControllerXYPad(
        :final xParameterNumber,
        :final yParameterNumber,
      ) =>
        [xParameterNumber, yParameterNumber],
      AlgorithmControllerNoteMask(:final notes) => [
        for (final note in notes) note.parameterNumber,
      ],
      _ => const <int>[],
    },
};

void _expectNoControllerBypass(
  List<AlgorithmControllerNode> nodes, {
  required String reason,
}) {
  expect(_boundParameterNumbers(nodes), isNot(contains(0)), reason: reason);
}
