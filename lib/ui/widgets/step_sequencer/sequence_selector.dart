import 'package:flutter/material.dart';

/// Control widget for sequence selection in Step Sequencer
///
/// Provides a dropdown for selecting one of 32 stored sequences.
/// Shows loading indicator during sequence switch operations.
///
/// Layout adapts responsively:
/// - Desktop/Tablet: Horizontal row layout with full labels
/// - Mobile: Compact layout with abbreviated labels
///
/// Supports firmware-provided sequence names via enumStrings parameter.
class SequenceSelector extends StatelessWidget {
  final int currentSequence; // 0-31 (hardware value)
  final bool isLoading;
  final ValueChanged<int> onSequenceChanged;
  final Map<int, String>? sequenceNames; // Optional custom names (deprecated - use enumStrings)
  final List<String>? enumStrings; // Firmware-provided sequence names

  const SequenceSelector({
    super.key,
    required this.currentSequence,
    required this.isLoading,
    required this.onSequenceChanged,
    this.sequenceNames,
    this.enumStrings,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 768;

    return Row(
      children: [
        Expanded(
          child: _buildSequenceDropdown(context, isMobile),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildSequenceDropdown(BuildContext context, bool isMobile) {
    // Determine sequence count from enum strings or default to 32
    final sequenceCount = enumStrings?.length ?? 32;

    return DropdownButtonFormField<int>(
      initialValue: currentSequence,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Sequence',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey.shade800
            : Colors.grey.shade50,
      ),
      items: List.generate(sequenceCount, (index) {
        String name;
        if (enumStrings != null && index < enumStrings!.length && enumStrings![index].isNotEmpty) {
          // Use firmware-provided enum string
          name = enumStrings![index];
        } else if (sequenceNames != null && sequenceNames!.containsKey(index)) {
          // Fallback to custom names (deprecated)
          name = sequenceNames![index]!;
        } else {
          // Fallback to numeric label (display as 1-32, value is 0-31)
          name = 'Sequence ${index + 1}';
        }

        return DropdownMenuItem<int>(
          value: index,
          child: Text(name),
        );
      }),
      onChanged: isLoading
          ? null
          : (sequence) {
              if (sequence != null) {
                onSequenceChanged(sequence);
              }
            },
    );
  }
}
