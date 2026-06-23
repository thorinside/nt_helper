import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/cubit/chat_cubit.dart';
import 'package:nt_helper/chat/services/memory_service.dart';
import 'package:nt_helper/chat/ui/chat_panel.dart';
import 'package:nt_helper/mcp/tool_registry.dart';
import 'package:nt_helper/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockToolRegistry extends Mock implements ToolRegistry {}

class _MockMemoryService extends Mock implements MemoryService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatCubit cubit;
  late _MockToolRegistry toolRegistry;
  late _MockMemoryService memoryService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService().init();
    toolRegistry = _MockToolRegistry();
    memoryService = _MockMemoryService();
    when(() => toolRegistry.entries).thenReturn(const []);
    when(
      () => memoryService.saveSessionSnapshot(any()),
    ).thenAnswer((_) async {});
    cubit = ChatCubit(toolRegistry: toolRegistry, memoryService: memoryService);
  });

  tearDown(() async {
    await cubit.close();
  });

  testWidgets('header uses context status arc instead of clear icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ChatCubit>.value(
            value: cubit,
            child: const ChatPanel(),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byTooltip('Context status'), findsOneWidget);

    await tester.tap(find.byTooltip('Context status'));
    await tester.pumpAndSettle();

    expect(find.text('Context'), findsOneWidget);
    expect(find.text('Breakdown'), findsOneWidget);
    expect(find.text('Compact'), findsOneWidget);
    expect(find.text('Clear'), findsOneWidget);
  });
}
