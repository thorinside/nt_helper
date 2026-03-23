import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';

class CcTarget {
  final int algorithmIndex;
  final int parameterNumber;
  final MidiMappingType midiMappingType;
  final int midiMin;
  final int midiMax;
  final bool isMidiSymmetric;
  final bool isMidiRelative;
  final int paramMin;
  final int paramMax;

  const CcTarget({
    required this.algorithmIndex,
    required this.parameterNumber,
    required this.midiMappingType,
    required this.midiMin,
    required this.midiMax,
    required this.isMidiSymmetric,
    required this.isMidiRelative,
    required this.paramMin,
    required this.paramMax,
  });

  bool get is14Bit =>
      midiMappingType == MidiMappingType.cc14BitLow ||
      midiMappingType == MidiMappingType.cc14BitHigh;
}

class CcReverseLookup {
  final Map<int, List<CcTarget>> _lookup;

  CcReverseLookup._(this._lookup);

  static int _key(int channel, int cc) => channel * 256 + cc;

  factory CcReverseLookup.build(List<Slot> slots) {
    final map = <int, List<CcTarget>>{};

    for (int slotIdx = 0; slotIdx < slots.length; slotIdx++) {
      final slot = slots[slotIdx];
      for (int paramIdx = 0; paramIdx < slot.mappings.length; paramIdx++) {
        final mapping = slot.mappings[paramIdx];
        final pmd = mapping.packedMappingData;

        if (!pmd.isMidiEnabled) continue;
        if (pmd.midiMappingType == MidiMappingType.noteMomentary ||
            pmd.midiMappingType == MidiMappingType.noteToggle) {
          continue;
        }

        final paramInfo = paramIdx < slot.parameters.length
            ? slot.parameters[paramIdx]
            : null;
        if (paramInfo == null) continue;

        final target = CcTarget(
          algorithmIndex: slotIdx,
          parameterNumber: paramIdx,
          midiMappingType: pmd.midiMappingType,
          midiMin: pmd.midiMin,
          midiMax: pmd.midiMax,
          isMidiSymmetric: pmd.isMidiSymmetric,
          isMidiRelative: pmd.isMidiRelative,
          paramMin: paramInfo.min,
          paramMax: paramInfo.max,
        );

        final key = _key(pmd.midiChannel, pmd.midiCC);
        (map[key] ??= []).add(target);

        // For 14-bit mappings, also register the LSB CC# (cc + 32)
        if (target.is14Bit && pmd.midiCC < 32) {
          final lsbKey = _key(pmd.midiChannel, pmd.midiCC + 32);
          (map[lsbKey] ??= []).add(target);
        }
      }
    }

    return CcReverseLookup._(map);
  }

  List<CcTarget>? lookup(int channel, int cc) => _lookup[_key(channel, cc)];

  bool get isEmpty => _lookup.isEmpty;

  int get size => _lookup.length;

  static int convertCcToParamValue(
    CcTarget target,
    int ccValue, {
    int? currentParamValue,
  }) {
    if (target.isMidiRelative) {
      final delta = ccValue < 64 ? ccValue : ccValue - 128;
      final current = currentParamValue ?? target.paramMin;
      return (current + delta).clamp(target.paramMin, target.paramMax);
    }

    final midiMin = target.midiMin;
    final midiMax = target.midiMax;
    final paramMin = target.paramMin;
    final paramMax = target.paramMax;

    if (target.isMidiSymmetric) {
      // Midpoint of the MIDI CC range maps to midpoint of param range.
      // Use ceiling so that for a 0-127 range the integer midpoint (64)
      // lands in the lower half and maps exactly to paramMid.
      final midiMidInt = ((midiMin + midiMax + 1) / 2).ceil();
      final paramMid = (paramMin + paramMax) / 2.0;
      if (ccValue <= midiMidInt) {
        final range = (midiMidInt - midiMin).toDouble();
        final t = range == 0 ? 1.0 : (ccValue - midiMin) / range;
        return (paramMin + t * (paramMid - paramMin)).round().clamp(paramMin, paramMax);
      } else {
        final range = (midiMax - midiMidInt).toDouble();
        final t = range == 0 ? 1.0 : (ccValue - midiMidInt) / range;
        return (paramMid + t * (paramMax - paramMid)).round().clamp(paramMin, paramMax);
      }
    }

    // Standard linear mapping: [midiMin..midiMax] → [paramMin..paramMax]
    final effectiveMidiMin = midiMin;
    final effectiveMidiMax = midiMax;
    if (effectiveMidiMax == effectiveMidiMin) return paramMin;

    final t = (ccValue - effectiveMidiMin) / (effectiveMidiMax - effectiveMidiMin);
    final clamped = t.clamp(0.0, 1.0);
    return (paramMin + clamped * (paramMax - paramMin)).round().clamp(paramMin, paramMax);
  }
}
