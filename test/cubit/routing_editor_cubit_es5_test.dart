import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/routing_editor_cubit.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/core/routing/models/connection.dart';

/// Helper function to create a test Slot with minimal required parameters
Slot createTestSlot({
  required String guid,
  String? name,
}) {
  return Slot(
    algorithm: Algorithm(
      algorithmIndex: 0,
      guid: guid,
      name: name ?? guid,
    ),
    routing: RoutingInfo(algorithmIndex: 0, routingInfo: List.filled(6, 0)),
    pages: ParameterPages(algorithmIndex: 0, pages: []),
    parameters: [],
    values: [],
    enums: [],
    mappings: [],
    valueStrings: [],
  );
}

void main() {
  group('RoutingEditorCubit ES-5 Detection', () {
    late RoutingEditorCubit cubit;

    setUp(() {
      // Create cubit without DistingCubit for unit testing
      cubit = RoutingEditorCubit(null);
    });

    tearDown(() {
      cubit.close();
    });

    test('shouldShowEs5Node returns true when usbf algorithm present', () {
      final slots = [
        createTestSlot(guid: 'usbf', name: 'USB From Host'),
      ];

      expect(cubit.shouldShowEs5Node(slots), isTrue);
    });

    test('shouldShowEs5Node returns true when clck algorithm present', () {
      final slots = [
        createTestSlot(guid: 'clck', name: 'Clock'),
      ];

      expect(cubit.shouldShowEs5Node(slots), isTrue);
    });

    test('shouldShowEs5Node returns true when eucp algorithm present', () {
      final slots = [
        createTestSlot(guid: 'eucp', name: 'Euclidean'),
      ];

      expect(cubit.shouldShowEs5Node(slots), isTrue);
    });

    test('shouldShowEs5Node returns true when es5e algorithm present', () {
      final slots = [
        createTestSlot(guid: 'es5e', name: 'ES-5 Encoder'),
      ];

      expect(cubit.shouldShowEs5Node(slots), isTrue);
    });

    test('shouldShowEs5Node returns false when no ES-5 algorithms present', () {
      final slots = [
        createTestSlot(guid: 'adsr', name: 'ADSR Envelope'),
        createTestSlot(guid: 'midi', name: 'MIDI'),
      ];

      expect(cubit.shouldShowEs5Node(slots), isFalse);
    });

    test('shouldShowEs5Node returns true when multiple ES-5 algorithms present', () {
      final slots = [
        createTestSlot(guid: 'usbf', name: 'USB From Host'),
        createTestSlot(guid: 'clck', name: 'Clock'),
      ];

      expect(cubit.shouldShowEs5Node(slots), isTrue);
    });

    test('shouldShowEs5Node returns true when ES-5 algorithm mixed with non-ES-5', () {
      final slots = [
        createTestSlot(guid: 'adsr', name: 'ADSR Envelope'),
        createTestSlot(guid: 'usbf', name: 'USB From Host'),
        createTestSlot(guid: 'midi', name: 'MIDI'),
      ];

      expect(cubit.shouldShowEs5Node(slots), isTrue);
    });

    test('shouldShowEs5Node returns false for empty slots list', () {
      final slots = <Slot>[];

      expect(cubit.shouldShowEs5Node(slots), isFalse);
    });
  });

  group('RoutingEditorCubit ES-5 L/R Connection Support', () {
    late RoutingEditorCubit cubit;

    setUp(() {
      cubit = RoutingEditorCubit(null);
    });

    tearDown(() {
      cubit.close();
    });

    test('_determineConnectionType recognizes es5_L as hardwareOutput', () {
      final connectionType = cubit.testDetermineConnectionType(
        'algo_usbf_1_usb_ch1',
        'es5_L',
      );

      expect(connectionType, ConnectionType.hardwareOutput);
    });

    test('_determineConnectionType recognizes es5_R as hardwareOutput', () {
      final connectionType = cubit.testDetermineConnectionType(
        'algo_usbf_1_usb_ch1',
        'es5_R',
      );

      expect(connectionType, ConnectionType.hardwareOutput);
    });

    test('_determineConnectionType still recognizes hw_out_ as hardwareOutput', () {
      final connectionType = cubit.testDetermineConnectionType(
        'algo_usbf_1_usb_ch1',
        'hw_out_1',
      );

      expect(connectionType, ConnectionType.hardwareOutput);
    });

    test('_determineConnectionType recognizes algorithm to algorithm', () {
      final connectionType = cubit.testDetermineConnectionType(
        'algo_usbf_1_usb_ch1',
        'algo_adsr_1_input',
      );

      expect(connectionType, ConnectionType.algorithmToAlgorithm);
    });
  });
}
