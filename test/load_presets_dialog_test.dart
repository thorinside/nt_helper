import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nt_helper/load_preset_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateNiceMocks([MockSpec<SharedPreferences>()])
import 'load_presets_dialog_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoadPresetDialog', () {
    testWidgets('Should display initial text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: LoadPresetDialog(initialName: "initial preset"),
          ),
        ),
      );

      final titleInputText = find.byKey(const Key('preset-name-text-field'));
      expect(titleInputText, findsOneWidget);
      final title =
          (tester.element(titleInputText).widget as TextField).controller?.text;
      expect(title, equals('initial preset'));
    });

    testWidgets('When cancel button pushed, widget returns null',
        (WidgetTester tester) async {
      late dynamic returnValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(builder: (context) {
              return ElevatedButton(
                  onPressed: () async {
                    returnValue = await showDialog(
                        context: context,
                        builder: (context) =>
                            LoadPresetDialog(initialName: ""));
                  },
                  child: Text("Show"));
            }),
          ),
        ),
      );

      final showButton = find.text("Show");
      await tester.tap(showButton);
      await tester.pumpAndSettle();

      final cancelButton =
          find.byKey(const Key('load_preset_dialog_cancel_button'));
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(returnValue, isNull);
    });

    testWidgets(
        'When append button pushed, widget returns text and indicates append',
        (WidgetTester tester) async {
      late dynamic value;
      SharedPreferences preferences = MockSharedPreferences();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(builder: (context) {
              return ElevatedButton(
                  onPressed: () async {
                    value = await showDialog(
                        context: context,
                        builder: (context) => LoadPresetDialog(
                              initialName: "",
                              preferences: preferences,
                            ));
                  },
                  child: Text("Show"));
            }),
          ),
        ),
      );

      when(preferences.setStringList("presetHistory", ["/presets/Turing.json"]))
          .thenAnswer((_) => Future.value(true));

      final showButton = find.text("Show");
      await tester.tap(showButton);
      await tester.pumpAndSettle();

      final titleInputText = find.byKey(const Key('preset-name-text-field'));
      expect(titleInputText, findsOneWidget);

      await tester.enterText(titleInputText, "/presets/Turing.json   ");

      final appendButton =
          find.byKey(const Key('load_preset_dialog_append_button'));
      expect(appendButton, findsOneWidget);
      await tester.tap(appendButton);
      await tester.pumpAndSettle();

      expect(value, isNotNull);
      expect(value,
          equals({"name": "/presets/Turing.json   ".trim(), "append": true}));
    });

    testWidgets(
        'When load button pushed, widget returns text and indicates to load',
            (WidgetTester tester) async {
          late dynamic value;
          SharedPreferences preferences = MockSharedPreferences();
          await tester.pumpWidget(
            MaterialApp(
              home: Material(
                child: Builder(builder: (context) {
                  return ElevatedButton(
                      onPressed: () async {
                        value = await showDialog(
                            context: context,
                            builder: (context) => LoadPresetDialog(
                              initialName: "",
                              preferences: preferences,
                            ));
                      },
                      child: Text("Show"));
                }),
              ),
            ),
          );

          when(preferences.setStringList("presetHistory", ["/presets/Turing.json"]))
              .thenAnswer((_) => Future.value(true));

          final showButton = find.text("Show");
          await tester.tap(showButton);
          await tester.pumpAndSettle();

          final titleInputText = find.byKey(const Key('preset-name-text-field'));
          expect(titleInputText, findsOneWidget);

          await tester.enterText(titleInputText, "/presets/Turing.json   ");

          final appendButton =
          find.byKey(const Key('load_preset_dialog_load_button'));
          expect(appendButton, findsOneWidget);
          await tester.tap(appendButton);
          await tester.pumpAndSettle();

          expect(value, isNotNull);
          expect(value,
              equals({"name": "/presets/Turing.json   ".trim(), "append": false}));
        });
  });
}
