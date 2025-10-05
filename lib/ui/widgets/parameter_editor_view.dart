import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/widgets/parameter_view_row.dart';

class ParameterEditorView extends StatelessWidget {
  final Slot slot;
  final ParameterInfo parameterInfo;
  final ParameterValue value;
  final ParameterEnumStrings enumStrings;
  final Mapping? mapping;
  final ParameterValueString valueString;
  final String? unit;

  const ParameterEditorView({
    super.key,
    required this.slot,
    required this.parameterInfo,
    required this.value,
    required this.enumStrings,
    required this.mapping,
    required this.valueString,
    this.unit,
  });

  @override
  Widget build(BuildContext context) {
    // For string-type parameters (units 13, 14, 17), don't pass unit
    // These parameters rely entirely on value strings or raw values
    final shouldShowUnit =
        parameterInfo.unit != 13 &&
        parameterInfo.unit != 14 &&
        parameterInfo.unit != 17;

    // Check if we have a complete set of enum strings (all non-empty)
    // Partial enums (e.g., ["Off", "", "", ...]) should not be treated as dropdowns
    final hasCompleteEnumStrings =
        enumStrings.values.isNotEmpty &&
        enumStrings.values.every((s) => s.isNotEmpty);

    // For the current value, check if there's a valid enum string to display
    // This handles partial enums where only some indices have strings (e.g., only index 0 = "Off")
    final currentValueHasEnumString =
        enumStrings.values.isNotEmpty &&
        value.value >= 0 &&
        value.value < enumStrings.values.length &&
        enumStrings.values[value.value].isNotEmpty;

    // Determine the display string to use
    // For partial enums (like unit 14), prefer enum string over valueString,
    // but only if the enum string is non-empty
    // For unit 14: only use valueString if value is 0 (the only value with a valid string "Off")
    // Otherwise show raw integer for values 1-6
    final effectiveDisplayString = currentValueHasEnumString
        ? enumStrings.values[value.value]
        : (parameterInfo.unit == 14
              ? (value.value == 0 && valueString.value.isNotEmpty
                    ? valueString.value
                    : null)
              : (valueString.value.isNotEmpty ? valueString.value : null));

    return ParameterViewRow(
      name: parameterInfo.name,
      min: parameterInfo.min,
      max: parameterInfo.max,
      algorithmIndex: parameterInfo.algorithmIndex,
      parameterNumber: parameterInfo.parameterNumber,
      powerOfTen: parameterInfo.powerOfTen,
      defaultValue: parameterInfo.defaultValue,
      displayString: effectiveDisplayString,
      dropdownItems: hasCompleteEnumStrings ? enumStrings.values : null,
      isOnOff:
          (hasCompleteEnumStrings &&
          enumStrings.values.length >= 2 &&
          enumStrings.values[0] == "Off" &&
          enumStrings.values[1] == "On"),
      initialValue:
          (value.value >= parameterInfo.min && value.value <= parameterInfo.max)
          ? value.value
          : parameterInfo.defaultValue,
      unit: shouldShowUnit ? unit : null,
      mappingData: mapping?.packedMappingData,
      slot: slot,
    );
  }
}
