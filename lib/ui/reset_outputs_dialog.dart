import 'package:flutter/material.dart';

/// Shows a dialog to reset all outputs with CV input selection
Future<void> showResetOutputsDialog({
  required BuildContext context,
  required int initialCvInput,
  required void Function(int selectedInput) onReset,
}) {
  int selectedInput = initialCvInput;

  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Reset all Outputs'),
        content: SizedBox(
          width: double.infinity,
          child: DropdownMenu<int>(
            initialSelection: selectedInput,
            requestFocusOnTap: false,
            label: const Text('CV Input'),
            onSelected: (newValue) {
              if (newValue == null) return;
              setState(() {
                selectedInput = newValue;
              });
            },
            dropdownMenuEntries: List.generate(29, (index) {
              if (index == 0) {
                return const DropdownMenuEntry<int>(
                  value: 0,
                  label: 'None',
                );
              } else if (index >= 1 && index <= 12) {
                return DropdownMenuEntry<int>(
                  value: index,
                  label: 'Input $index',
                );
              } else if (index >= 13 && index <= 20) {
                return DropdownMenuEntry<int>(
                  value: index,
                  label: 'Output ${index - 12}',
                );
              } else {
                return DropdownMenuEntry<int>(
                  value: index,
                  label: 'Aux ${index - 20}',
                );
              }
            }),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              onReset(selectedInput);
              Navigator.of(context).pop();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    ),
  );
}
