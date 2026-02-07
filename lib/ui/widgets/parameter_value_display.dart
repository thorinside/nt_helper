import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
    final textStyle = widescreen ? textTheme.labelLarge : textTheme.labelSmall;

    // If BPM or file editor, hide default display (handled elsewhere)
    if (isBpmUnit || hasFileEditor) {
      return const SizedBox.shrink();
    }

    // On/Off checkbox
    if (isOnOff) {
      return Semantics(
        label: '$name: ${currentValue == 1 ? "On" : "Off"}',
        toggled: currentValue == 1,
        child: Checkbox(
          value: currentValue == 1,
          onChanged: (value) {
            onValueChanged(value! ? 1 : 0);
          },
        ),
      );
    }

    // Enum dropdown
    if (dropdownItems != null) {
      return Semantics(
        label: name,
        value: dropdownItems![currentValue],
        child: DropdownMenu(
          requestFocusOnTap: false,
          initialSelection: dropdownItems![currentValue],
          inputDecorationTheme: const InputDecorationTheme(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          textStyle: widescreen ? textTheme.labelLarge : textTheme.labelMedium,
          dropdownMenuEntries: dropdownItems!
              .map((item) => DropdownMenuEntry(value: item, label: item))
              .toList(),
          onSelected: (value) {
            final newValue = dropdownItems!.indexOf(value!).clamp(min, max);
            onValueChanged(newValue);
          },
        ),
      );
    }

    // MIDI note parameters (but not percentages)
    if (name.toLowerCase().contains("note") && unit != "%") {
      final noteStr = midiNoteToNoteString(currentValue);
      return Semantics(
        liveRegion: true,
        label: '$name: $noteStr',
        child: Text(noteStr, style: textStyle),
      );
    }

    // MIDI channel parameters
    if (name.toLowerCase().contains("midi channel")) {
      final channelStr = currentValue == 0 ? "None" : currentValue.toString();
      return Semantics(
        liveRegion: true,
        label: '$name: $channelStr',
        child: Text(channelStr, style: textStyle),
      );
    }

    // Hardware-provided display string
    if (displayString != null) {
      return Semantics(
        liveRegion: true,
        label: '$name: $displayString',
        customSemanticsActions: {
          CustomSemanticsAction(label: 'Switch to step editor'):
              onLongPress,
        },
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Text(
            displayString!,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
          ),
        ),
      );
    }

    // Unit-based formatting with powerOfTen scaling
    if (unit != null) {
      final formatted = formatWithUnit(
        currentValue,
        name: name,
        min: min,
        max: max,
        unit: unit,
        powerOfTen: powerOfTen,
      );
      return Semantics(
        liveRegion: true,
        label: '$name: $formatted',
        child: Text(formatted, style: textStyle),
      );
    }

    // Default: raw integer value
    return Semantics(
      liveRegion: true,
      label: '$name: $currentValue',
      child: Text(currentValue.toString(), style: textStyle),
    );
  }
}
