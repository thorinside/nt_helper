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
  Widget build(BuildContext context) => ParameterViewRow(
    name: parameterInfo.name,
    min: parameterInfo.min,
    max: parameterInfo.max,
    algorithmIndex: parameterInfo.algorithmIndex,
    parameterNumber: parameterInfo.parameterNumber,
    powerOfTen: parameterInfo.powerOfTen,
    defaultValue: parameterInfo.defaultValue,
    displayString: valueString.value.isNotEmpty ? valueString.value : null,
    dropdownItems: enumStrings.values.isNotEmpty ? enumStrings.values : null,
    isOnOff:
        (enumStrings.values.isNotEmpty &&
        enumStrings.values[0] == "Off" &&
        enumStrings.values[1] == "On"),
    initialValue:
        (value.value >= parameterInfo.min && value.value <= parameterInfo.max)
        ? value.value
        : parameterInfo.defaultValue,
    unit: unit,
    mappingData: mapping?.packedMappingData,
    slot: slot,
  );
}
