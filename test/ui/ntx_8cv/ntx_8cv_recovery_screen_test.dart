import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/ntx_8cv_settings_cubit.dart';
import 'package:nt_helper/ui/ntx_8cv/ntx_8cv_screen.dart';

void main() {
  testWidgets(
    'keeps Retry send unavailable while disconnected and enables it after reconnect',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var retryCount = 0;
      final pendingState = Ntx8cvSettingsState(
        es5: const Ntx8cvSettingChange(
          confirmedValue: 0,
          attemptedValue: 1,
          message:
              'The ES-5 change was not confirmed by device readback. The '
              'actual device state is uncertain.',
        ),
      );

      Widget buildSection({required bool isConnected}) => MaterialApp(
        home: Scaffold(
          body: Ntx8cvSettingsSection(
            isConnected: isConnected,
            state: pendingState,
            onChannelGroupChanged: (_) async {},
            onRetryChannelGroupChange: () async {},
            onEs5Changed: (_) async {},
            onRetryEs5Change: () async {
              retryCount += 1;
            },
            onModeChanged: (_) async {},
            onRetryModeChange: () async {},
            onReboot: () async {},
          ),
        ),
      );

      await tester.pumpWidget(buildSection(isConnected: false));

      final retry = find.byKey(const Key('ntx8cv-retry-es5-change'));
      expect(retry, findsOneWidget);
      expect(find.bySemanticsLabel('Retry send'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(retry).onPressed, isNull);
      expect(
        find.textContaining('Attempted ES-5 value: enabled'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Last device-confirmed value: disabled'),
        findsOneWidget,
      );

      await tester.pumpWidget(buildSection(isConnected: true));
      expect(tester.widget<OutlinedButton>(retry).onPressed, isNotNull);

      await tester.tap(retry);
      expect(retryCount, 1);
    },
  );

  testWidgets(
    'offers exactly three Mode choices while ES-5 remains available in each',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Widget buildSection(Ntx8cvExpansionMode mode) => MaterialApp(
        home: Scaffold(
          body: Ntx8cvSettingsSection(
            isConnected: true,
            state: Ntx8cvSettingsState(
              es5: const Ntx8cvSettingChange(confirmedValue: 1),
              mode: Ntx8cvSettingChange(confirmedValue: mode.value),
              modeCapabilityEvidenced: true,
            ),
            onChannelGroupChanged: (_) async {},
            onRetryChannelGroupChange: () async {},
            onEs5Changed: (_) async {},
            onRetryEs5Change: () async {},
            onModeChanged: (_) async {},
            onRetryModeChange: () async {},
            onReboot: () async {},
          ),
        ),
      );

      for (final mode in Ntx8cvExpansionMode.values) {
        await tester.pumpWidget(buildSection(mode));

        final modePickerFinder = find.byType(
          DropdownButtonFormField<Ntx8cvExpansionMode>,
        );
        final modePicker = tester
            .widget<DropdownButtonFormField<Ntx8cvExpansionMode>>(
              modePickerFinder,
            );
        expect(modePicker.onChanged, isNotNull);
        await tester.tap(modePickerFinder);
        await tester.pumpAndSettle();
        for (final label in ['8x8 CV', '1x8 32bit Audio', '2x8 16bit Audio']) {
          expect(find.text(label), findsWidgets);
        }
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();

        final es5Switch = tester.widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, 'Enable ES-5'),
        );
        expect(es5Switch.value, isTrue);
        expect(es5Switch.onChanged, isNotNull);
      }
    },
  );

  testWidgets(
    'offers released Channel Group blocks and explains their separate role',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      Ntx8cvChannelGroup? selectedGroup;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Ntx8cvSettingsSection(
              isConnected: true,
              state: const Ntx8cvSettingsState(
                channelGroup: Ntx8cvSettingChange(confirmedValue: 0),
              ),
              onChannelGroupChanged: (group) async {
                selectedGroup = group;
              },
              onRetryChannelGroupChange: () async {},
              onEs5Changed: (_) async {},
              onRetryEs5Change: () async {},
              onModeChanged: (_) async {},
              onRetryModeChange: () async {},
              onReboot: () async {},
            ),
          ),
        ),
      );

      final pickerFinder = find.byType(
        DropdownButtonFormField<Ntx8cvChannelGroup>,
      );
      final picker = tester.widget<DropdownButtonFormField<Ntx8cvChannelGroup>>(
        pickerFinder,
      );
      expect(find.text('Channel Group'), findsOneWidget);
      expect(
        find.textContaining('does not enable individual audio channels'),
        findsOneWidget,
      );
      expect(picker.onChanged, isNotNull);
      await tester.tap(pickerFinder);
      await tester.pumpAndSettle();
      for (final label in [
        '1–8',
        '9–16',
        '17–24',
        '25–32',
        '33–40',
        '41–48',
        '49–56',
        '57–64',
      ]) {
        expect(find.text(label), findsWidgets);
      }

      await tester.tap(find.text('57–64').last);
      await tester.pumpAndSettle();
      expect(selectedGroup, Ntx8cvChannelGroup.channels57To64);
    },
  );

  testWidgets(
    'shows a pending Mode separately from its confirmed value and reboot state',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var retryCount = 0;
      Widget buildSection(Ntx8cvSettingsState state) => MaterialApp(
        home: Scaffold(
          body: Ntx8cvSettingsSection(
            isConnected: true,
            state: state,
            onChannelGroupChanged: (_) async {},
            onRetryChannelGroupChange: () async {},
            onEs5Changed: (_) async {},
            onRetryEs5Change: () async {},
            onModeChanged: (_) async {},
            onRetryModeChange: () async {
              retryCount += 1;
            },
            onReboot: () async {},
          ),
        ),
      );
      final pendingMode = Ntx8cvSettingsState(
        modeCapabilityEvidenced: true,
        mode: const Ntx8cvSettingChange(
          confirmedValue: 2,
          attemptedValue: 0,
          message:
              'The Mode change was not confirmed by device readback. The '
              'actual device state is uncertain.',
        ),
      );

      await tester.pumpWidget(buildSection(pendingMode));

      final retry = find.byKey(const Key('ntx8cv-retry-mode-change'));
      expect(retry, findsOneWidget);
      expect(tester.widget<OutlinedButton>(retry).onPressed, isNotNull);
      expect(
        find.textContaining('Attempted NT expansion mode: 8x8 CV'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Last device-confirmed value: 2x8 16bit Audio'),
        findsOneWidget,
      );
      await tester.tap(retry);
      expect(retryCount, 1);

      await tester.pumpWidget(
        buildSection(
          const Ntx8cvSettingsState(
            modeCapabilityEvidenced: true,
            modeRebootRequired: true,
            mode: Ntx8cvSettingChange(confirmedValue: 0),
          ),
        ),
      );
      expect(find.textContaining('Reboot required'), findsOneWidget);
    },
  );

  testWidgets(
    'reboots the selected NTX-8CV with one activation and no dialog',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var rebootCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Ntx8cvSettingsSection(
              isConnected: true,
              state: const Ntx8cvSettingsState(
                modeRebootRequired: true,
                modeCapabilityEvidenced: true,
                mode: Ntx8cvSettingChange(confirmedValue: 0),
              ),
              onChannelGroupChanged: (_) async {},
              onRetryChannelGroupChange: () async {},
              onEs5Changed: (_) async {},
              onRetryEs5Change: () async {},
              onModeChanged: (_) async {},
              onRetryModeChange: () async {},
              onReboot: () async {
                rebootCount += 1;
              },
            ),
          ),
        ),
      );

      final reboot = find.byKey(const Key('ntx8cv-reboot'));
      expect(reboot, findsOneWidget);
      expect(find.text('Reboot NTX-8CV'), findsOneWidget);
      expect(tester.widget<FilledButton>(reboot).onPressed, isNotNull);

      await tester.tap(reboot);
      expect(rebootCount, 1);
      expect(find.byType(AlertDialog), findsNothing);
    },
  );

  testWidgets(
    'shows all released audio channels, confirms their states, and disables them in CV mode',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final changes = <(Ntx8cvAudioChannel, bool)>[];
      final audioState = Ntx8cvSettingsState(
        modeCapabilityEvidenced: true,
        mode: const Ntx8cvSettingChange(confirmedValue: 2),
        audioChannels: const [
          Ntx8cvSettingChange(confirmedValue: 1),
          Ntx8cvSettingChange(confirmedValue: 0),
          Ntx8cvSettingChange(confirmedValue: 1),
          Ntx8cvSettingChange(confirmedValue: 0),
          Ntx8cvSettingChange(confirmedValue: 1),
          Ntx8cvSettingChange(confirmedValue: 0),
          Ntx8cvSettingChange(confirmedValue: 1),
          Ntx8cvSettingChange(confirmedValue: 0),
        ],
      );
      Widget buildSection(Ntx8cvSettingsState state) => MaterialApp(
        home: Scaffold(
          body: Ntx8cvSettingsSection(
            isConnected: true,
            state: state,
            onChannelGroupChanged: (_) async {},
            onRetryChannelGroupChange: () async {},
            onEs5Changed: (_) async {},
            onRetryEs5Change: () async {},
            onModeChanged: (_) async {},
            onRetryModeChange: () async {},
            onAudioChannelChanged: (channel, enabled) async {
              changes.add((channel, enabled));
            },
            onRetryAudioChannelChange: (_) async {},
            onReboot: () async {},
          ),
        ),
      );

      await tester.pumpWidget(buildSection(audioState));
      for (final channel in Ntx8cvAudioChannel.values) {
        expect(
          find.byKey(Key('ntx8cv-audio-channel-${channel.number}')),
          findsOneWidget,
        );
        expect(find.text(channel.label), findsOneWidget);
      }
      expect(
        find.textContaining('Device-confirmed: enabled.'),
        findsNWidgets(4),
      );
      expect(
        find.textContaining('Device-confirmed: disabled.'),
        findsNWidgets(4),
      );

      final channel2 = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Audio channel 2'),
      );
      expect(channel2.onChanged, isNotNull);
      channel2.onChanged!(true);
      expect(changes, [(Ntx8cvAudioChannel.channel2, true)]);

      await tester.pumpWidget(
        buildSection(
          const Ntx8cvSettingsState(
            modeCapabilityEvidenced: true,
            mode: Ntx8cvSettingChange(confirmedValue: 0),
          ),
        ),
      );
      final unavailableChannel = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Audio channel 1'),
      );
      expect(unavailableChannel.onChanged, isNull);
      expect(
        find.textContaining(
          'Audio channels are not applicable while the device-confirmed Mode is 8x8 CV.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps settings geometry stable through loading, pending failure, and reboot feedback on narrow and wide layouts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 2200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final loading = const Ntx8cvSettingsState(
        mode: Ntx8cvSettingChange(isLoading: true),
        es5: Ntx8cvSettingChange(isLoading: true),
      );
      final recovering = Ntx8cvSettingsState(
        modeCapabilityEvidenced: true,
        mode: const Ntx8cvSettingChange(
          confirmedValue: 2,
          attemptedValue: 0,
          message:
              'The Mode change was not confirmed by device readback. The actual device state is uncertain.',
        ),
        es5: const Ntx8cvSettingChange(
          confirmedValue: 0,
          attemptedValue: 1,
          message:
              'The ES-5 change was not confirmed by device readback. The actual device state is uncertain.',
        ),
        audioChannels: const [
          Ntx8cvSettingChange(
            confirmedValue: 1,
            attemptedValue: 0,
            message:
                'The Audio channel 1 change was not confirmed by device readback. The actual device state is uncertain.',
          ),
          Ntx8cvSettingChange(),
          Ntx8cvSettingChange(),
          Ntx8cvSettingChange(),
          Ntx8cvSettingChange(),
          Ntx8cvSettingChange(),
          Ntx8cvSettingChange(),
          Ntx8cvSettingChange(),
        ],
        isRebooting: true,
        rebootMessage:
            'Could not complete the NTX-8CV reboot and refresh. Check the selected MIDI endpoints and reconnect the device.',
      );
      Widget buildSection(Ntx8cvSettingsState state, bool isNarrow) =>
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Ntx8cvSettingsSection(
                  isConnected: true,
                  isNarrow: isNarrow,
                  state: state,
                  onChannelGroupChanged: (_) async {},
                  onRetryChannelGroupChange: () async {},
                  onEs5Changed: (_) async {},
                  onRetryEs5Change: () async {},
                  onModeChanged: (_) async {},
                  onRetryModeChange: () async {},
                  onReboot: () async {},
                ),
              ),
            ),
          );

      await tester.pumpWidget(buildSection(loading, false));
      final wideLoadingSize = tester.getSize(
        find.byType(Ntx8cvSettingsSection),
      );
      await tester.pumpWidget(buildSection(recovering, false));
      expect(
        tester.getSize(find.byType(Ntx8cvSettingsSection)),
        wideLoadingSize,
      );

      await tester.binding.setSurfaceSize(const Size(500, 2200));
      await tester.pumpWidget(buildSection(loading, true));
      final narrowLoadingSize = tester.getSize(
        find.byType(Ntx8cvSettingsSection),
      );
      await tester.pumpWidget(buildSection(recovering, true));
      expect(
        tester.getSize(find.byType(Ntx8cvSettingsSection)),
        narrowLoadingSize,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
