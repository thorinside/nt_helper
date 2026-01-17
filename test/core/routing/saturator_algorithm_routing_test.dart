import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/core/routing/saturator_algorithm_routing.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

void main() {
  group('SaturatorAlgorithmRouting.canHandle', () {
    test('returns true for Saturator algorithm', () {
      final slot = _createSaturatorSlot();
      expect(SaturatorAlgorithmRouting.canHandle(slot), true);
    });

    test('returns false for non-Saturator algorithm', () {
      final slot = _createNonSaturatorSlot();
      expect(SaturatorAlgorithmRouting.canHandle(slot), false);
    });
  });
}

Slot _createSaturatorSlot() {
  final algorithm = Algorithm(
    algorithmIndex: 0,
    guid: 'satu',
    name: 'Saturator',
  );

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: const [],
    values: const [],
    enums: const [],
    mappings: const [],
    valueStrings: const [],
  );
}

Slot _createNonSaturatorSlot() {
  final algorithm = Algorithm(algorithmIndex: 0, guid: 'mixr', name: 'Mixer');

  final routing = RoutingInfo(
    algorithmIndex: 0,
    routingInfo: List.filled(6, 0),
  );

  final pages = ParameterPages(algorithmIndex: 0, pages: []);

  return Slot(
    algorithm: algorithm,
    routing: routing,
    pages: pages,
    parameters: const [],
    values: const [],
    enums: const [],
    mappings: const [],
    valueStrings: const [],
  );
}
