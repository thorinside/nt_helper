import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/ntx_8cv_settings_cubit.dart';
import 'package:nt_helper/ui/ntx_8cv/ntx_8cv_screen.dart';

void main() {
  testWidgets(
    'keeps Retry send unavailable while disconnected and enables it after reconnect',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
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
        find.textContaining('does not replace the disting NT’s granular'),
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
      await tester.binding.setSurfaceSize(const Size(800, 1200));
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
}
