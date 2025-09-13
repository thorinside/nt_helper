import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart' show DisplayMode;
import 'package:nt_helper/services/settings_service.dart';
import 'package:nt_helper/ui/widgets/rename_slot_dialog.dart';
import 'package:nt_helper/util/extensions.dart';

class AlgorithmListView extends StatelessWidget {
  final List<Slot> slots;
  final int selectedIndex;
  final ValueChanged<int> onSelectionChanged;

  const AlgorithmListView({
    super.key,
    required this.slots,
    required this.selectedIndex,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DistingCubit, DistingState>(
      builder: (context, state) {
        return switch (state) {
          DistingStateSynchronized(slots: final _) => ListView.builder(
            padding: const EdgeInsets.only(top: 8.0),
            itemCount: slots.length,
            itemBuilder: (context, index) {
              final slot = slots[index];
              final displayName = slot.algorithm.name;

              return GestureDetector(
                onDoubleTap: () async {
                  var cubit = context.read<DistingCubit>();
                  cubit.disting()?.let((manager) {
                    manager.requestSetFocus(index, 0);
                    manager.requestSetDisplayMode(DisplayMode.algorithmUI);
                  });
                  if (SettingsService().hapticsEnabled) {
                    Haptics.vibrate(HapticsType.medium);
                  }
                },
                child: ListTile(
                  title: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  selected: index == selectedIndex,
                  selectedTileColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                  onTap: () => onSelectionChanged(index),
                  onLongPress: () async {
                    var cubit = context.read<DistingCubit>();
                    final newName = await showDialog<String>(
                      context: context,
                      builder: (dialogCtx) =>
                          RenameSlotDialog(initialName: displayName),
                    );

                    if (newName != null && newName != displayName) {
                      cubit.renameSlot(index, newName);
                    }
                  },
                ),
              );
            },
          ),
          _ => const Center(child: Text("Loading slots...")),
        };
      },
    );
  }
}
