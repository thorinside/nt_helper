import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/ui/template_manager/current_preset_template_source.dart';

class _MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  test('current preset template source keeps slot specifications', () {
    final state = DistingStateSynchronized(
      disting: _MockDistingMidiManager(),
      distingVersion: '1.17.0',
      firmwareVersion: FirmwareVersion('1.17.0'),
      presetName: 'Four Channel Quantizer',
      algorithms: const [],
      slots: [
        Slot(
          algorithm: Algorithm(
            algorithmIndex: 0,
            guid: 'quan',
            name: 'Quantizer',
            specifications: const [4],
          ),
          routing: RoutingInfo.filler(),
          pages: ParameterPages(algorithmIndex: 0, pages: const []),
          parameters: const [],
          values: const [],
          enums: const [],
          mappings: const [],
          valueStrings: const [],
        ),
      ],
      unitStrings: const [],
      offline: false,
    );

    final source = fullPresetDetailsFromDistingState(state);

    expect(source!.slots.single.specificationValues, const [4]);
  });
}
