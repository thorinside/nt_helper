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
    required this.distingCubit,
    required this.data,
    required this.slots,
    required this.algorithmIndex,
    required this.parameterNumber,
  });

  final MidiListenerCubit myMidiCubit;
  final DistingCubit distingCubit;
  final PackedMappingData data;
  final List<Slot> slots;
  final int algorithmIndex;
  final int parameterNumber;

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
          child: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: myMidiCubit),
              BlocProvider.value(value: distingCubit),
            ],
            child: PackedMappingDataEditor(
              initialData: data,
              slots: slots,
              algorithmIndex: algorithmIndex,
              parameterNumber: parameterNumber,
              onSave: (updatedData) async {
                // Save directly to cubit without closing the dialog
                distingCubit.saveMapping(algorithmIndex, parameterNumber, updatedData);
              },
            ),
          ),
        ),
      ),
    );
  }
}
