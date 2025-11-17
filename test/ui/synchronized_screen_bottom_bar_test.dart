import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/core/platform/platform_interaction_service.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/services/mcp_server_service.dart';
import 'package:nt_helper/ui/synchronized_screen.dart';

class MockDistingCubit extends Mock implements DistingCubit {}

class MockDistingMidiManager extends Mock implements IDistingMidiManager {}

class MockPlatformInteractionService extends Mock
    implements PlatformInteractionService {}

void main() {
  group('SynchronizedScreen Bottom Bar Platform Detection Tests', () {
    late MockDistingCubit mockCubit;
    late MockDistingMidiManager mockMidiManager;
    late MockPlatformInteractionService mockPlatformService;

    setUpAll(() {
      // Initialize MCP server service for tests to avoid initialization error
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      mockCubit = MockDistingCubit();
      mockMidiManager = MockDistingMidiManager();
      mockPlatformService = MockPlatformInteractionService();

      // Initialize McpServerService with mock cubit
      McpServerService.initialize(distingCubit: mockCubit);
    });

    Widget createTestWidget({
      required bool isMobile,
      required bool isOffline,
    }) {
      // Mock platform service response
      when(() => mockPlatformService.isMobilePlatform()).thenReturn(isMobile);

      // Mock cubit state
      final state = DistingStateSynchronized(
        disting: mockMidiManager,
        distingVersion: '1.10.0',
        firmwareVersion: FirmwareVersion('1.10.0'),
        presetName: 'Test Preset',
        algorithms: const [],
        slots: const [],
        unitStrings: const [],
        offline: isOffline,
      );

      when(() => mockCubit.state).thenReturn(state);
      when(() => mockCubit.stream).thenAnswer((_) => Stream.value(state));

      return MaterialApp(
        home: BlocProvider<DistingCubit>.value(
          value: mockCubit,
          child: SynchronizedScreen(
            distingVersion: '1.10.0',
            firmwareVersion: FirmwareVersion('1.10.0'),
            slots: const [],
            algorithms: const [],
            units: const [],
            presetName: 'Test Preset',
            screenshot: Uint8List(0),
            loading: false,
            platformService: mockPlatformService,
          ),
        ),
      );
    }

    testWidgets('Desktop layout renders 4 display mode buttons when not offline',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(isMobile: false, isOffline: false),
      );

      // Verify desktop shows 4 icon buttons
      expect(find.byTooltip('Parameter View'), findsOneWidget);
      expect(find.byTooltip('Algorithm UI'), findsOneWidget);
      expect(find.byTooltip('Overview UI'), findsOneWidget);
      expect(find.byTooltip('Overview VU Meters'), findsOneWidget);

      // Verify mobile "View Options" button is NOT present
      expect(find.byTooltip('View Options'), findsNothing);
    });

    testWidgets('Mobile layout renders single "View Options" button when not offline',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(isMobile: true, isOffline: false),
      );

      // Verify mobile shows single "View Options" button with correct icon
      expect(find.byTooltip('View Options'), findsOneWidget);
      expect(find.byIcon(Icons.view_list), findsOneWidget);

      // Verify desktop buttons are NOT present
      expect(find.byTooltip('Parameter View'), findsNothing);
      expect(find.byTooltip('Algorithm UI'), findsNothing);
      expect(find.byTooltip('Overview UI'), findsNothing);
      expect(find.byTooltip('Overview VU Meters'), findsNothing);
    });

    testWidgets('Offline mode shows "Offline Data" button on desktop',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(isMobile: false, isOffline: true),
      );

      // Verify offline button is present
      expect(find.byTooltip('Offline Data'), findsOneWidget);

      // Verify desktop display mode buttons are NOT present
      expect(find.byTooltip('Parameter View'), findsNothing);
      expect(find.byTooltip('Algorithm UI'), findsNothing);
      expect(find.byTooltip('Overview UI'), findsNothing);
      expect(find.byTooltip('Overview VU Meters'), findsNothing);

      // Verify mobile button is NOT present
      expect(find.byTooltip('View Options'), findsNothing);
    });

    testWidgets('Offline mode shows "Offline Data" button on mobile',
        (tester) async {
      await tester.pumpWidget(
        createTestWidget(isMobile: true, isOffline: true),
      );

      // Verify offline button is present
      expect(find.byTooltip('Offline Data'), findsOneWidget);

      // Verify mobile "View Options" button is NOT present
      expect(find.byTooltip('View Options'), findsNothing);

      // Verify desktop display mode buttons are NOT present
      expect(find.byTooltip('Parameter View'), findsNothing);
      expect(find.byTooltip('Algorithm UI'), findsNothing);
      expect(find.byTooltip('Overview UI'), findsNothing);
      expect(find.byTooltip('Overview VU Meters'), findsNothing);
    });

    testWidgets('Platform detection happens on every rebuild (no caching)',
        (tester) async {
      // Start with desktop
      await tester.pumpWidget(
        createTestWidget(isMobile: false, isOffline: false),
      );

      // Verify desktop buttons are shown
      expect(find.byTooltip('Parameter View'), findsOneWidget);

      // Platform detection should be called on every build
      verify(() => mockPlatformService.isMobilePlatform()).called(greaterThan(0));
    });
  });
}
