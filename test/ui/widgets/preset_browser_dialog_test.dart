import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/cubit/preset_browser_cubit.dart';
import 'package:nt_helper/ui/widgets/preset_browser_dialog.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPresetBrowserCubit extends Mock implements PresetBrowserCubit {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class FakeDirectoryEntry extends Fake implements DirectoryEntry {}

void main() {
  late MockPresetBrowserCubit mockCubit;

  setUpAll(() {
    registerFallbackValue(FakeDirectoryEntry());
    registerFallbackValue(PanelPosition.left);
  });

  setUp(() {
    mockCubit = MockPresetBrowserCubit();
    // Mock loadRootDirectory to return a Future<void>
    when(() => mockCubit.loadRootDirectory()).thenAnswer((_) async {});
    // Mock getSelectedPath to return empty string by default
    when(() => mockCubit.getSelectedPath()).thenReturn('');
  });

  Widget createTestWidget({required Widget child}) {
    return MaterialApp(
      home: BlocProvider<PresetBrowserCubit>.value(
        value: mockCubit,
        child: child,
      ),
    );
  }

  group('PresetBrowserDialog', () {
    testWidgets('displays three panels in row layout', (tester) async {
      when(() => mockCubit.state).thenReturn(
        PresetBrowserState.loaded(
          currentPath: '/presets',
          leftPanelItems: const [],
          centerPanelItems: const [],
          rightPanelItems: const [],
          selectedLeftItem: null,
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: const [],
          sortByDate: false,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PresetBrowserDialog(),
        ),
      );

      // Should find three panel containers
      expect(find.byType(DirectoryPanel), findsNWidgets(3));
      
      // Should be in a Row
      expect(
        find.descendant(
          of: find.byType(Row),
          matching: find.byType(DirectoryPanel),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('displays loading indicator when loading', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const PresetBrowserState.loading(),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PresetBrowserDialog(),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays error message when error state', (tester) async {
      when(() => mockCubit.state).thenReturn(
        const PresetBrowserState.error(
          message: 'Test error message',
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PresetBrowserDialog(),
        ),
      );

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('displays back button and sort toggle', (tester) async {
      when(() => mockCubit.state).thenReturn(
        PresetBrowserState.loaded(
          currentPath: '/presets',
          leftPanelItems: const [],
          centerPanelItems: const [],
          rightPanelItems: const [],
          selectedLeftItem: null,
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: const ['/'],
          sortByDate: false,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(
        createTestWidget(
          child: const PresetBrowserDialog(),
        ),
      );

      // Mock the navigateBack and toggleSortMode methods
      when(() => mockCubit.navigateBack()).thenAnswer((_) async {});
      when(() => mockCubit.toggleSortMode()).thenReturn(null);
      
      // Back button should be visible when history exists
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      
      // Sort toggle should be visible
      expect(find.byIcon(Icons.sort_by_alpha), findsOneWidget);
    });

    testWidgets('calls selectDirectory when directory tapped', (tester) async {
      final testEntry = DirectoryEntry(
        name: 'TestFolder/',
        attributes: 0x10,
        date: 0,
        time: 0,
        size: 0,
      );

      when(() => mockCubit.state).thenReturn(
        PresetBrowserState.loaded(
          currentPath: '/presets',
          leftPanelItems: [testEntry],
          centerPanelItems: const [],
          rightPanelItems: const [],
          selectedLeftItem: null,
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: const [],
          sortByDate: false,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.selectDirectory(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: ThreePanelNavigator(
              leftPanelItems: [testEntry],
              centerPanelItems: const [],
              rightPanelItems: const [],
              selectedLeftItem: null,
              selectedCenterItem: null,
              selectedRightItem: null,
              onItemSelected: (item, position) {
                mockCubit.selectDirectory(item, position);
              },
            ),
          ),
        ),
      );

      // Clean the display name (remove trailing slash) - widget shows "TestFolder" not "TestFolder/"
      await tester.tap(find.text('TestFolder'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.selectDirectory(testEntry, PanelPosition.left)).called(1);
    });

    testWidgets('calls selectFile when file tapped', (tester) async {
      final testFile = DirectoryEntry(
        name: 'preset.json',
        attributes: 0,
        date: 0,
        time: 0,
        size: 1024,
      );

      when(() => mockCubit.state).thenReturn(
        PresetBrowserState.loaded(
          currentPath: '/presets',
          leftPanelItems: [testFile],
          centerPanelItems: const [],
          rightPanelItems: const [],
          selectedLeftItem: null,
          selectedCenterItem: null,
          selectedRightItem: null,
          navigationHistory: const [],
          sortByDate: false,
        ),
      );
      when(() => mockCubit.stream).thenAnswer((_) => const Stream.empty());
      when(() => mockCubit.getSelectedPath()).thenReturn('/presets/preset.json');
      when(() => mockCubit.selectFile(any(), any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: ThreePanelNavigator(
              leftPanelItems: [testFile],
              centerPanelItems: const [],
              rightPanelItems: const [],
              selectedLeftItem: null,
              selectedCenterItem: null,
              selectedRightItem: null,
              onItemSelected: (item, position) {
                mockCubit.selectFile(item, position);
              },
            ),
          ),
        ),
      );

      // Tap on the file
      await tester.tap(find.text('preset.json'));
      await tester.pumpAndSettle();

      verify(() => mockCubit.selectFile(testFile, PanelPosition.left)).called(1);
    });
  });

  group('DirectoryPanel', () {
    testWidgets('displays folder icons for directories', (tester) async {
      final testDirectory = DirectoryEntry(
        name: 'Folder/',
        attributes: 0x10,
        date: 0,
        time: 0,
        size: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectoryPanel(
              items: [testDirectory],
              selectedItem: null,
              onItemTap: (_) {},
              position: PanelPosition.left,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('displays file icons for files', (tester) async {
      final testFile = DirectoryEntry(
        name: 'file.json',
        attributes: 0,
        date: 0,
        time: 0,
        size: 1024,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectoryPanel(
              items: [testFile],
              selectedItem: null,
              onItemTap: (_) {},
              position: PanelPosition.left,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.insert_drive_file), findsOneWidget);
    });

    testWidgets('highlights selected item', (tester) async {
      final testItem = DirectoryEntry(
        name: 'selected.json',
        attributes: 0,
        date: 0,
        time: 0,
        size: 1024,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DirectoryPanel(
              items: [testItem],
              selectedItem: testItem,
              onItemTap: (_) {},
              position: PanelPosition.left,
            ),
          ),
        ),
      );

      // Find the ListTile and check if it's selected
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.selected, true);
    });
  });
}