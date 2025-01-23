import 'package:flutter/material.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

class AlgorithmViewRegistry {
  static Widget? findViewFor(Slot slot) {
    switch (slot.algorithm.guid) {
      case 'note':
        return NotesAlgorithmView(slot: slot);
    }
    return null;
  }
}

class NotesAlgorithmView extends StatelessWidget {
  final Slot slot;

  const NotesAlgorithmView({
    super.key,
    required this.slot,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < slot.valueStrings.length; i++)
            Text(
              slot.valueStrings[i].value,
              style: Theme.of(context).textTheme.titleMedium,
            )
        ],
      ),
    );
  }
}
