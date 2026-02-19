import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

void main() {
  group('MCP showSlot - empty slot consistency', () {
    late MockDistingCubit cubit;
    late MCPAlgorithmTools tools;

    setUp(() {
      cubit = MockDistingCubit();
      final manager = MockDistingMidiManager();

      final synchronizedState = DistingState.synchronized(
        disting: manager,
        distingVersion: '1.0.0',
        firmwareVersion: FirmwareVersion('1.0.0'),
        presetName: 'Test Preset',
        algorithms: const [],
        slots: [
          Slot(
            algorithm: Algorithm(
              algorithmIndex: 0,
              guid: 'test-guid',
              name: 'Test Algorithm',
            ),
            routing: RoutingInfo(algorithmIndex: 0, routingInfo: const []),
            pages: ParameterPages(algorithmIndex: 0, pages: const []),
            parameters: const [],
            values: const [],
            enums: const [],
            mappings: const [],
            valueStrings: const [],
          ),
        ],
        unitStrings: const [],
      );

      when(() => cubit.state).thenReturn(synchronizedState);

      final controller = DistingControllerImpl(cubit);
      tools = MCPAlgorithmTools(controller, cubit);
    });

    test(
      'returns empty slot JSON for valid but unallocated slot index',
      () async {
        final result = await tools.showSlot(5);
        final json = jsonDecode(result) as Map<String, dynamic>;

        expect(json['slot_index'], equals(5));
        expect(json['parameters'], isEmpty);
        expect(json['algorithm'], isA<Map<String, dynamic>>());
        expect((json['algorithm'] as Map<String, dynamic>)['guid'], equals(''));
        expect((json['algorithm'] as Map<String, dynamic>)['name'], equals(''));
      },
    );
  });
}
