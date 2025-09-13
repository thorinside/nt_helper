import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';

import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/widgets/mapping_editor_bottom_sheet.dart';
import 'package:nt_helper/ui/widgets/parameter_view_row.dart';

class MappingEditButton extends StatelessWidget {
  const MappingEditButton({super.key, required this.widget});

  final ParameterViewRow widget;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.6,
      child: Builder(
        builder: (context) {
          final bool hasMapping =
              widget.mappingData != null &&
              widget.mappingData != PackedMappingData.filler() &&
              widget.mappingData?.isMapped() == true;

          // Define your two styles:
          final ButtonStyle defaultStyle = IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          );
          final ButtonStyle mappedStyle = IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primaryContainer, // or any color you prefer
          );

          return IconButton.filledTonal(
            // Decide which style to use based on `hasMapping`
            style: hasMapping ? mappedStyle : defaultStyle,
            icon: const Icon(Icons.map_sharp),
            tooltip: 'Edit mapping',
            onPressed: () async {
              final cubit = context.read<DistingCubit>();
              final currentState = cubit.state;
              List<Slot> currentSlots = [];
              if (currentState is DistingStateSynchronized) {
                currentSlots = currentState.slots;
              }

              final data = widget.mappingData ?? PackedMappingData.filler();
              final myMidiCubit = context.read<MidiListenerCubit>();
              final updatedData = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) {
                  return MappingEditorBottomSheet(
                    myMidiCubit: myMidiCubit,
                    data: data,
                    slots: currentSlots,
                  );
                },
              );

              if (updatedData != null) {
                cubit.saveMapping(
                  widget.algorithmIndex,
                  widget.parameterNumber,
                  updatedData,
                );
              }
            },
          );
        },
      ),
    );
  }
}
