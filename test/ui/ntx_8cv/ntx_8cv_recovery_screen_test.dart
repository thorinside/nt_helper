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
        confirmedEs5Enabled: false,
        attemptedEs5Enabled: true,
        es5Message:
            'The ES-5 change was not confirmed by device readback. The '
            'actual device state is uncertain.',
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
}
