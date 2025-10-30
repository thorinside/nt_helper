import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/ui/widgets/parameter_editor_view.dart';

class ParameterListView extends StatelessWidget {
  final Slot slot;
  final List<String> units;

  const ParameterListView({super.key, required this.slot, required this.units});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      cacheExtent: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      itemCount: slot.parameters.length,
      itemBuilder: (context, index) {
        // Use safe access with bounds checking
        final parameter = slot.parameters.elementAtOrNull(index);
        final value = slot.values.elementAtOrNull(index);
        final enumStrings = slot.enums.elementAtOrNull(index);
        final mapping = slot.mappings.elementAtOrNull(index);
        final valueString = slot.valueStrings.elementAtOrNull(index);

        // Skip this parameter if we don't have essential data
        // Note: valueString and enumStrings can be empty/filler for many parameters
        if (parameter == null || value == null) {
          return const SizedBox.shrink();
        }

        // Use filler/empty data if not available
        final safeEnumStrings = enumStrings ?? ParameterEnumStrings.filler();
        final safeValueString = valueString ?? ParameterValueString.filler();

        // For string-type parameters (units 13, 14, 17), don't fetch unit
        // These parameters rely entirely on value strings or raw values
        final shouldShowUnit =
            parameter.unit != 13 &&
            parameter.unit != 14 &&
            parameter.unit != 17;
        final unit = shouldShowUnit ? parameter.getUnitString(units) : null;

        return ParameterEditorView(
          slot: slot,
          parameterInfo: parameter,
          value: value,
          enumStrings: safeEnumStrings,
          mapping: mapping,
          valueString: safeValueString,
          unit: unit,
        );
      },
    );
  }
}
