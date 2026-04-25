import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/core/routing/node_layout_algorithm.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/routing_editor_state.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDistingCubit extends Mock implements DistingCubit {}

void main() {
  group('RoutingEditorCubit auto-center on selection', () {
    late RoutingEditorCubit cubit;
    late _MockDistingCubit mockDistingCubit;

    const algoId = 'algo_0';
    const algoNodePos = NodePosition(
      x: 100.0,
      y: 200.0,
      width: 80.0,
      height: 40.0,
    );

    RoutingEditorStateLoaded buildLoadedState() => RoutingEditorState.loaded(
          physicalInputs: const [],
          physicalOutputs: const [],
          algorithms: [
            RoutingAlgorithm(
              id: algoId,
              index: 0,
              algorithm: Algorithm(
                algorithmIndex: 0,
                guid: 'test0',
                name: 'Test Algorithm',
              ),
              inputPorts: const [],
              outputPorts: const [],
            ),
          ],
          connections: const [],
          nodePositions: const {algoId: algoNodePos},
        ) as RoutingEditorStateLoaded;

    Future<void> initWithSetting({required bool autoCenter}) async {
      // Reseed prefs and force the singleton to pick them up.
      SharedPreferences.setMockInitialValues(
        {'auto_center_on_selection': autoCenter},
      );
      await SettingsService().init();

      mockDistingCubit = _MockDistingCubit();
      when(() => mockDistingCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockDistingCubit.state).thenReturn(const DistingState.initial());
      cubit = RoutingEditorCubit(mockDistingCubit);
      cubit.emit(buildLoadedState());
    }

    tearDown(() async {
      await cubit.close();
    });

    test('sets cascadeScrollTarget when setting is enabled', () async {
      await initWithSetting(autoCenter: true);

      cubit.setFocusedAlgorithm(algoId);

      final state = cubit.state as RoutingEditorStateLoaded;
      expect(state.focusedAlgorithmIds, contains(algoId));
      expect(
        state.cascadeScrollTarget,
        // centroid = (x + w/2, y + h/2) = (140, 220)
        equals(const Offset(140.0, 220.0)),
      );
    });

    test('leaves cascadeScrollTarget null when setting is disabled', () async {
      await initWithSetting(autoCenter: false);

      cubit.setFocusedAlgorithm(algoId);

      final state = cubit.state as RoutingEditorStateLoaded;
      expect(state.focusedAlgorithmIds, contains(algoId));
      expect(state.cascadeScrollTarget, isNull);
    });

    test('default (no key persisted) auto-centers, preserving prior behavior',
        () async {
      // No 'auto_center_on_selection' key — getter returns default true.
      SharedPreferences.setMockInitialValues({});
      await SettingsService().init();

      mockDistingCubit = _MockDistingCubit();
      when(() => mockDistingCubit.stream)
          .thenAnswer((_) => const Stream.empty());
      when(() => mockDistingCubit.state).thenReturn(const DistingState.initial());
      cubit = RoutingEditorCubit(mockDistingCubit);
      cubit.emit(buildLoadedState());

      cubit.setFocusedAlgorithm(algoId);

      final state = cubit.state as RoutingEditorStateLoaded;
      expect(state.cascadeScrollTarget, equals(const Offset(140.0, 220.0)));
    });
  });
}
