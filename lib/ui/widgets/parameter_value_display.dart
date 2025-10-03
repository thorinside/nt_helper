import 'package:flutter/material.dart';
import 'package:nt_helper/util/ui_helpers.dart';

/// Widget that displays parameter values with appropriate formatting.
///
/// Handles all parameter value display cases including:
/// - On/Off checkboxes
/// - Enum dropdowns
/// - MIDI note names
/// - MIDI channels
/// - Hardware displayStrings
/// - Unit-based formatting with powerOfTen scaling
/// - Raw integer values
class ParameterValueDisplay extends StatelessWidget {
  final int currentValue;
  final int min;
  final int max;
  final String name;
  final String? unit;
  final int powerOfTen;
  final String? displayString;
  final List<String>? dropdownItems;
  final bool isOnOff;
  final bool widescreen;
  final bool isBpmUnit;
  final bool hasFileEditor;
  final bool showAlternateEditor;
  final Function(int) onValueChanged;
  final VoidCallback onLongPress;

  const ParameterValueDisplay({
    super.key,
    required this.currentValue,
    required this.min,
    required this.max,
    required this.name,
    this.unit,
    this.powerOfTen = 0,
    this.displayString,
    this.dropdownItems,
    this.isOnOff = false,
    required this.widescreen,
    this.isBpmUnit = false,
    this.hasFileEditor = false,
    this.showAlternateEditor = false,
    required this.onValueChanged,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final textStyle =
        widescreen ? textTheme.labelLarge : textTheme.labelSmall;

    // If BPM or file editor, hide default display (handled elsewhere)
    if (isBpmUnit || hasFileEditor) {
      return const SizedBox.shrink();
    }

    // On/Off checkbox
    if (isOnOff) {
      return Checkbox(
        value: currentValue == 1,
        onChanged: (value) {
          onValueChanged(value! ? 1 : 0);
        },
      );
    }

    // Enum dropdown
    if (dropdownItems != null) {
      return DropdownMenu(
        requestFocusOnTap: false,
        initialSelection: dropdownItems![currentValue],
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 8.0,
          ),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        textStyle: widescreen ? textTheme.labelLarge : textTheme.labelMedium,
        dropdownMenuEntries: dropdownItems!
            .map(
              (item) => DropdownMenuEntry(value: item, label: item),
            )
            .toList(),
        onSelected: (value) {
          final newValue = dropdownItems!.indexOf(value!).clamp(min, max);
          onValueChanged(newValue);
        },
      );
    }

    // MIDI note parameters (but not percentages)
    if (name.toLowerCase().contains("note") && unit != "%") {
      return Text(
        midiNoteToNoteString(currentValue),
        style: textStyle,
      );
    }

    // MIDI channel parameters
    if (name.toLowerCase().contains("midi channel")) {
      return Text(
        currentValue == 0 ? "None" : currentValue.toString(),
        style: textStyle,
      );
    }

    // Hardware-provided display string
    if (displayString != null) {
      return GestureDetector(
        onLongPress: onLongPress,
        child: Text(
          displayString!,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      );
    }

    // Unit-based formatting with powerOfTen scaling (RESTORED)
    if (unit != null) {
      return Text(
        formatWithUnit(
          currentValue,
          name: name,
          min: min,
          max: max,
          unit: unit,
          powerOfTen: powerOfTen,
        ),
        style: textStyle,
      );
    }

    // Default: raw integer value
    return Text(
      currentValue.toString(),
      style: textStyle,
    );
  }
}
