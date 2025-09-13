import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nt_helper/ui/midi_listener/midi_listener_cubit.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/ui/widgets/packed_mapping_data_editor.dart';

class MappingEditorBottomSheet extends StatelessWidget {
  const MappingEditorBottomSheet({
    super.key,
    required this.myMidiCubit,
    required this.data,
    required this.slots,
  });

  final MidiListenerCubit myMidiCubit;
  final PackedMappingData data;
  final List<Slot> slots;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom > 0
              ? MediaQuery.of(context).viewInsets.bottom
              : MediaQuery.of(context).padding.bottom,
        ),
        child: SingleChildScrollView(
          child: BlocProvider.value(
            value: myMidiCubit,
            child: PackedMappingDataEditor(
              initialData: data,
              slots: slots,
              onSave: (updatedData) {
                // do something with updatedData
                Navigator.of(context).pop(updatedData);
              },
            ),
          ),
        ),
      ),
    );
  }
}
