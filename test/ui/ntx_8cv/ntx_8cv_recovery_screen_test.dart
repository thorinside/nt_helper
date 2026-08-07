import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/cubit/ntx_8cv_settings_cubit.dart';
import 'package:nt_helper/ui/ntx_8cv/ntx_8cv_screen.dart';

void main() {
  testWidgets(
    'keeps Retry send unavailable while disconnected and enables it after reconnect',
    (tester) async {
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
    'shows a pending Mode separately from its confirmed value and reboot state',
    (tester) async {
      var retryCount = 0;
      Widget buildSection(Ntx8cvSettingsState state) => MaterialApp(
        home: Scaffold(
          body: Ntx8cvSettingsSection(
            isConnected: true,
            state: state,
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
