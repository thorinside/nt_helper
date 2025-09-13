import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
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
        final parameter = slot.parameters.elementAt(index);
        final value = slot.values.elementAt(index);
        final enumStrings = slot.enums.elementAt(index);
        final mapping = slot.mappings.elementAtOrNull(index);
        final valueString = slot.valueStrings.elementAt(index);
        final unit = parameter.getUnitString(units);

        return ParameterEditorView(
          slot: slot,
          parameterInfo: parameter,
          value: value,
          enumStrings: enumStrings,
          mapping: mapping,
          valueString: valueString,
          unit: unit,
        );
      },
    );
  }
}
