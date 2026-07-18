import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/db/daos/presets_dao.dart';
import 'package:nt_helper/db/database.dart';

/// Builds a transient preset DTO from the current in-memory Disting state.
///
/// This is used by the hoisted Template Manager entry point so creating a
/// template from the current preset does not require first saving the preset
/// locally or re-fetching it from the device.
FullPresetDetails? fullPresetDetailsFromDistingState(DistingState state) {
  if (state is! DistingStateSynchronized) return null;

  return FullPresetDetails(
    preset: PresetEntry(
      id: -1,
      name: state.presetName,
      lastModified: DateTime.now(),
      isTemplate: false,
    ),
    slots: [
      for (var index = 0; index < state.slots.length; index++)
        _fullPresetSlotFromSlot(state.slots[index], index),
    ],
  );
}

FullPresetSlot _fullPresetSlotFromSlot(Slot slot, int index) {
  final parameterValues = <int, int>{};
  for (final value in slot.values) {
    if (value.parameterNumber >= 0) {
      parameterValues[value.parameterNumber] = value.value;
    }
  }

  final parameterStringValues = <int, String>{};
  for (final valueString in slot.valueStrings) {
    if (valueString.parameterNumber >= 0 && valueString.value.isNotEmpty) {
      parameterStringValues[valueString.parameterNumber] = valueString.value;
    }
  }

  final mappings = {
    for (final mapping in slot.mappings)
      if (mapping.parameterNumber >= 0 && mapping.packedMappingData.isMapped())
        mapping.parameterNumber: mapping.packedMappingData,
  };

  return FullPresetSlot(
    slot: PresetSlotEntry(
      id: -1,
      presetId: -1,
      slotIndex: index,
      algorithmGuid: slot.algorithm.guid,
      customName: slot.algorithm.name,
    ),
    algorithm: AlgorithmEntry(
      guid: slot.algorithm.guid,
      name: slot.algorithm.name,
      numSpecifications: slot.algorithm.specifications.length,
    ),
    specificationValues: List<int>.from(slot.algorithm.specifications),
    parameterValues: parameterValues,
    parameterStringValues: parameterStringValues,
    mappings: mappings,
    routing: PresetRoutingEntry(
      presetSlotId: -1,
      routingInfoJson: List<int>.from(slot.routing.routingInfo),
    ),
  );
}
