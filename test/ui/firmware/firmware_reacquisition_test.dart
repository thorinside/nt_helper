import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/cubit/firmware_update_cubit.dart';
import 'package:nt_helper/cubit/firmware_update_state.dart';
import 'package:nt_helper/ui/firmware/firmware_update_screen.dart';

class _MockFirmwareUpdateCubit extends MockCubit<FirmwareUpdateState>
    implements FirmwareUpdateCubit {}

class _MockDistingCubit extends MockCubit<DistingState>
    implements DistingCubit {}

void main() {
  late _MockFirmwareUpdateCubit firmwareCubit;

  setUp(() {
    firmwareCubit = _MockFirmwareUpdateCubit();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> pumpState(WidgetTester tester, FirmwareUpdateState state) async {
    when(() => firmwareCubit.state).thenReturn(state);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<FirmwareUpdateCubit>.value(
          value: firmwareCubit,
          child: Scaffold(body: FirmwareUpdateStateContent(state: state)),
        ),
      ),
    );
  }

  testWidgets('shows the shared waiting state after firmware completes', (
    tester,
  ) async {
    await pumpState(
      tester,
      const FirmwareUpdateState.verifyingMidi(
        newVersion: '1.16.0',
        completedAttempts: 5,
      ),
    );

    expect(find.text('Waiting for Disting NT'), findsOneWidget);
    expect(find.textContaining('completed successfully'), findsOneWidget);
    expect(find.text('Check 6 of 12'), findsOneWidget);
  });

  testWidgets('shows generic recovery without Windows service instructions', (
    tester,
  ) async {
    await pumpState(
      tester,
      const FirmwareUpdateState.midiRecoveryRequired(
        newVersion: '1.16.0',
        isWindows: false,
      ),
    );

    expect(find.text('Firmware Installed'), findsOneWidget);
    expect(find.textContaining('USB connection and power'), findsOneWidget);
    expect(find.textContaining('power-cycle'), findsOneWidget);
    expect(find.textContaining('restart the computer'), findsOneWidget);
    expect(find.textContaining('MidiSrv'), findsNothing);
    expect(find.text('Check Again'), findsOneWidget);
  });

  testWidgets('shows Windows MidiSrv recovery and copies the command', (
    tester,
  ) async {
    Object? clipboardArguments;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboardArguments = call.arguments;
          }
          return null;
        });
    when(() => firmwareCubit.checkMidiAgain()).thenAnswer((_) async {});

    await pumpState(
      tester,
      const FirmwareUpdateState.midiRecoveryRequired(
        newVersion: '1.16.0',
        isWindows: true,
      ),
    );

    expect(find.textContaining('PowerShell as Administrator'), findsOneWidget);
    expect(find.text('Restart-Service MidiSrv'), findsOneWidget);
    expect(find.textContaining('Restart Windows'), findsOneWidget);

    await tester.tap(find.text('Copy Command'));
    await tester.pump();

    expect(clipboardArguments, {'text': 'Restart-Service MidiSrv'});
    expect(find.text('PowerShell command copied'), findsOneWidget);

    await tester.tap(find.text('Check Again'));
    verify(() => firmwareCubit.checkMidiAgain()).called(1);
  });

  testWidgets('successful reacquisition refreshes and closes the route', (
    tester,
  ) async {
    final firmwareStates = StreamController<FirmwareUpdateState>.broadcast();
    final distingCubit = _MockDistingCubit();
    whenListen(
      firmwareCubit,
      firmwareStates.stream,
      initialState: const FirmwareUpdateState.verifyingMidi(
        newVersion: '1.16.0',
      ),
    );
    when(() => distingCubit.state).thenReturn(
      const DistingState.selectDevice(
        inputDevices: [],
        outputDevices: [],
        canWorkOffline: false,
      ),
    );
    when(
      () => distingCubit.onFirmwareUpdateComplete(),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('Device Selection'),
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider<FirmwareUpdateCubit>.value(
                            value: firmwareCubit,
                          ),
                          BlocProvider<DistingCubit>.value(value: distingCubit),
                        ],
                        child: FirmwareUpdateCompletionListener(
                          bloc: firmwareCubit,
                          child: const Scaffold(body: Text('Firmware Route')),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open Firmware'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Firmware'));
    await tester.pumpAndSettle();
    expect(find.text('Firmware Route'), findsOneWidget);

    firmwareStates.add(const FirmwareUpdateState.success(newVersion: '1.16.0'));
    await tester.pumpAndSettle();

    expect(find.text('Device Selection'), findsOneWidget);
    expect(find.text('Firmware Route'), findsNothing);
    verify(() => distingCubit.onFirmwareUpdateComplete()).called(1);

    await firmwareStates.close();
    await firmwareCubit.close();
    await distingCubit.close();
  });
}
