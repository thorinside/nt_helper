import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/cc_reverse_lookup.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

Slot _makeSlot({
  required int algorithmIndex,
  required List<_ParamSpec> params,
}) {
  final parameters = <ParameterInfo>[];
  final values = <ParameterValue>[];
  final enums = <ParameterEnumStrings>[];
  final mappings = <Mapping>[];
  final valueStrings = <ParameterValueString>[];

  for (final p in params) {
    parameters.add(ParameterInfo(
      algorithmIndex: algorithmIndex,
      parameterNumber: p.paramNumber,
      min: p.paramMin,
      max: p.paramMax,
      defaultValue: p.paramMin,
      unit: 0,
      name: 'param${p.paramNumber}',
      powerOfTen: 0,
    ));
    values.add(ParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: p.paramNumber,
      value: p.paramMin,
    ));
    enums.add(ParameterEnumStrings(
      algorithmIndex: algorithmIndex,
      parameterNumber: p.paramNumber,
      values: [],
    ));
    mappings.add(Mapping(
      algorithmIndex: algorithmIndex,
      parameterNumber: p.paramNumber,
      packedMappingData: p.mapping,
    ));
    valueStrings.add(ParameterValueString(
      algorithmIndex: algorithmIndex,
      parameterNumber: p.paramNumber,
      value: '',
    ));
  }

  return Slot(
    algorithm: Algorithm(algorithmIndex: algorithmIndex, guid: 'test', name: 'test'),
    routing: RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: []),
    pages: ParameterPages(algorithmIndex: algorithmIndex, pages: []),
    parameters: parameters,
    values: values,
    enums: enums,
    mappings: mappings,
    valueStrings: valueStrings,
  );
}

class _ParamSpec {
  final int paramNumber;
  final int paramMin;
  final int paramMax;
  final PackedMappingData mapping;

  _ParamSpec({
    required this.paramNumber,
    required this.paramMin,
    required this.paramMax,
    required this.mapping,
  });
}

PackedMappingData _ccMapping({
  int channel = 0,
  int cc = 1,
  int midiMin = 0,
  int midiMax = 127,
  bool enabled = true,
  bool symmetric = false,
  bool relative = false,
  MidiMappingType type = MidiMappingType.cc,
}) {
  return PackedMappingData(
    source: 0,
    cvInput: 0,
    isUnipolar: false,
    isGate: false,
    volts: 0,
    delta: 0,
    midiChannel: channel,
    midiMappingType: type,
    midiCC: cc,
    isMidiEnabled: enabled,
    isMidiSymmetric: symmetric,
    isMidiRelative: relative,
    midiMin: midiMin,
    midiMax: midiMax,
    i2cCC: 0,
    isI2cEnabled: false,
    isI2cSymmetric: false,
    i2cMin: 0,
    i2cMax: 0,
    perfPageIndex: 0,
    version: 5,
  );
}

void main() {
  group('CcReverseLookup', () {
    test('build creates lookup from slot mappings', () {
      final slots = [
        _makeSlot(algorithmIndex: 0, params: [
          _ParamSpec(
            paramNumber: 0,
            paramMin: 0,
            paramMax: 1000,
            mapping: _ccMapping(channel: 0, cc: 1),
          ),
        ]),
      ];

      final lookup = CcReverseLookup.build(slots);
      expect(lookup.isEmpty, isFalse);

      final targets = lookup.lookup(0, 1);
      expect(targets, isNotNull);
      expect(targets!.length, 1);
      expect(targets[0].algorithmIndex, 0);
      expect(targets[0].parameterNumber, 0);
    });

    test('build ignores disabled MIDI mappings', () {
      final slots = [
        _makeSlot(algorithmIndex: 0, params: [
          _ParamSpec(
            paramNumber: 0,
            paramMin: 0,
            paramMax: 100,
            mapping: _ccMapping(enabled: false),
          ),
        ]),
      ];

      final lookup = CcReverseLookup.build(slots);
      expect(lookup.isEmpty, isTrue);
    });

    test('build ignores note mappings', () {
      final slots = [
        _makeSlot(algorithmIndex: 0, params: [
          _ParamSpec(
            paramNumber: 0,
            paramMin: 0,
            paramMax: 100,
            mapping: _ccMapping(type: MidiMappingType.noteMomentary),
          ),
        ]),
      ];

      final lookup = CcReverseLookup.build(slots);
      expect(lookup.isEmpty, isTrue);
    });

    test('build registers 14-bit CC on both MSB and LSB', () {
      final slots = [
        _makeSlot(algorithmIndex: 0, params: [
          _ParamSpec(
            paramNumber: 0,
            paramMin: 0,
            paramMax: 16383,
            mapping: _ccMapping(cc: 1, type: MidiMappingType.cc14BitHigh),
          ),
        ]),
      ];

      final lookup = CcReverseLookup.build(slots);
      expect(lookup.lookup(0, 1), isNotNull);
      expect(lookup.lookup(0, 33), isNotNull); // cc + 32
    });

    test('lookup returns null for unregistered channel/cc', () {
      final slots = [
        _makeSlot(algorithmIndex: 0, params: [
          _ParamSpec(
            paramNumber: 0,
            paramMin: 0,
            paramMax: 100,
            mapping: _ccMapping(channel: 0, cc: 1),
          ),
        ]),
      ];

      final lookup = CcReverseLookup.build(slots);
      expect(lookup.lookup(0, 99), isNull);
      expect(lookup.lookup(1, 1), isNull);
    });

    test('multiple params on same channel/cc returns multiple targets', () {
      final slots = [
        _makeSlot(algorithmIndex: 0, params: [
          _ParamSpec(
            paramNumber: 0,
            paramMin: 0,
            paramMax: 100,
            mapping: _ccMapping(channel: 0, cc: 7),
          ),
          _ParamSpec(
            paramNumber: 1,
            paramMin: -50,
            paramMax: 50,
            mapping: _ccMapping(channel: 0, cc: 7),
          ),
        ]),
      ];

      final lookup = CcReverseLookup.build(slots);
      final targets = lookup.lookup(0, 7);
      expect(targets!.length, 2);
    });
  });

  group('CcReverseLookup.convertCcToParamValue', () {
    test('standard linear: CC 0 → paramMin, CC 127 → paramMax', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 0,
        midiMax: 127,
        isMidiSymmetric: false,
        isMidiRelative: false,
        paramMin: 0,
        paramMax: 1000,
      );

      expect(CcReverseLookup.convertCcToParamValue(target, 0), 0);
      expect(CcReverseLookup.convertCcToParamValue(target, 127), 1000);
      expect(CcReverseLookup.convertCcToParamValue(target, 64), closeTo(504, 1));
    });

    test('standard linear with custom midi range', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 10,
        midiMax: 117,
        isMidiSymmetric: false,
        isMidiRelative: false,
        paramMin: 0,
        paramMax: 100,
      );

      expect(CcReverseLookup.convertCcToParamValue(target, 10), 0);
      expect(CcReverseLookup.convertCcToParamValue(target, 117), 100);
    });

    test('symmetric: CC 64 maps to midpoint', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 0,
        midiMax: 127,
        isMidiSymmetric: true,
        isMidiRelative: false,
        paramMin: -100,
        paramMax: 100,
      );

      expect(CcReverseLookup.convertCcToParamValue(target, 64), 0);
      expect(CcReverseLookup.convertCcToParamValue(target, 0), -100);
      expect(CcReverseLookup.convertCcToParamValue(target, 127), 100);
    });

    test('relative: positive delta from low values', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 0,
        midiMax: 127,
        isMidiSymmetric: false,
        isMidiRelative: true,
        paramMin: 0,
        paramMax: 100,
      );

      expect(
        CcReverseLookup.convertCcToParamValue(target, 3, currentParamValue: 50),
        53,
      );
    });

    test('relative: negative delta from high values', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 0,
        midiMax: 127,
        isMidiSymmetric: false,
        isMidiRelative: true,
        paramMin: 0,
        paramMax: 100,
      );

      // CC 127 = -1, CC 126 = -2
      expect(
        CcReverseLookup.convertCcToParamValue(target, 127, currentParamValue: 50),
        49,
      );
      expect(
        CcReverseLookup.convertCcToParamValue(target, 126, currentParamValue: 50),
        48,
      );
    });

    test('relative: clamps to param range', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 0,
        midiMax: 127,
        isMidiSymmetric: false,
        isMidiRelative: true,
        paramMin: 0,
        paramMax: 100,
      );

      expect(
        CcReverseLookup.convertCcToParamValue(target, 10, currentParamValue: 95),
        100,
      );
      expect(
        CcReverseLookup.convertCcToParamValue(target, 120, currentParamValue: 5),
        0,
      );
    });

    test('equal midi range returns paramMin', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 64,
        midiMax: 64,
        isMidiSymmetric: false,
        isMidiRelative: false,
        paramMin: 0,
        paramMax: 100,
      );

      expect(CcReverseLookup.convertCcToParamValue(target, 64), 0);
    });

    test('CC value below midiMin clamps to paramMin', () {
      final target = CcTarget(
        algorithmIndex: 0,
        parameterNumber: 0,
        midiMappingType: MidiMappingType.cc,
        midiMin: 20,
        midiMax: 100,
        isMidiSymmetric: false,
        isMidiRelative: false,
        paramMin: 0,
        paramMax: 1000,
      );

      expect(CcReverseLookup.convertCcToParamValue(target, 0), 0);
    });
  });
}
