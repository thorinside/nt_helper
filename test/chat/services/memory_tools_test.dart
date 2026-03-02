import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nt_helper/chat/services/memory_service.dart';
import 'package:nt_helper/chat/services/memory_tools.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

class MockMemoryService extends Mock implements MemoryService {}

void main() {
  late MockMemoryService mockService;
  late List<ToolRegistryEntry> entries;

  setUp(() {
    mockService = MockMemoryService();
    entries = [];
    registerMemoryTools(entries, mockService);
  });

  ToolRegistryEntry findTool(String name) =>
      entries.firstWhere((e) => e.name == name);

  group('memory_read', () {
    test('returns success JSON with content', () async {
      when(() => mockService.readMemory())
          .thenAnswer((_) async => 'stored facts');

      final result = await findTool('memory_read').handler({});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      expect(json['content'], equals('stored facts'));
    });

    test('returns placeholder when memory is empty', () async {
      when(() => mockService.readMemory()).thenAnswer((_) async => '');

      final result = await findTool('memory_read').handler({});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      expect(json['content'], contains('empty'));
    });
  });

  group('memory_write', () {
    test('writes string content successfully', () async {
      when(() => mockService.writeMemory(any())).thenAnswer((_) async {});

      final result = await findTool('memory_write').handler({
        'content': 'new memory content',
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      verify(() => mockService.writeMemory('new memory content')).called(1);
    });

    test('returns error JSON for empty content', () async {
      final result = await findTool('memory_write').handler({
        'content': '',
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('required'));
    });

    test('returns error JSON for null content', () async {
      final result = await findTool('memory_write').handler({});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('required'));
    });

    test('handles non-String value without throwing TypeError', () async {
      when(() => mockService.writeMemory(any())).thenAnswer((_) async {});

      final result = await findTool('memory_write').handler({
        'content': 42,
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      verify(() => mockService.writeMemory('42')).called(1);
    });

    test('handles bool value without throwing TypeError', () async {
      when(() => mockService.writeMemory(any())).thenAnswer((_) async {});

      final result = await findTool('memory_write').handler({
        'content': true,
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      verify(() => mockService.writeMemory('true')).called(1);
    });
  });

  group('memory_append_daily', () {
    test('appends string entry successfully', () async {
      when(() => mockService.appendDailyLog(any())).thenAnswer((_) async {});

      final result = await findTool('memory_append_daily').handler({
        'entry': 'worked on routing',
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      verify(() => mockService.appendDailyLog('worked on routing')).called(1);
    });

    test('returns error JSON for empty entry', () async {
      final result = await findTool('memory_append_daily').handler({
        'entry': '',
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('required'));
    });

    test('returns error JSON for null entry', () async {
      final result = await findTool('memory_append_daily').handler({});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['error'], contains('required'));
    });

    test('handles non-String value without throwing TypeError', () async {
      when(() => mockService.appendDailyLog(any())).thenAnswer((_) async {});

      final result = await findTool('memory_append_daily').handler({
        'entry': 123,
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      verify(() => mockService.appendDailyLog('123')).called(1);
    });

    test('handles list value coerced to string', () async {
      when(() => mockService.appendDailyLog(any())).thenAnswer((_) async {});

      final result = await findTool('memory_append_daily').handler({
        'entry': [1, 2, 3],
      });
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      verify(() => mockService.appendDailyLog('[1, 2, 3]')).called(1);
    });
  });

  group('memory_read_daily', () {
    test('returns success JSON with content', () async {
      when(() => mockService.readDailyLogs())
          .thenAnswer((_) async => '### 2026-03-02\n- [10:00] entry');

      final result = await findTool('memory_read_daily').handler({});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      expect(json['content'], contains('entry'));
    });

    test('returns placeholder when no logs exist', () async {
      when(() => mockService.readDailyLogs()).thenAnswer((_) async => '');

      final result = await findTool('memory_read_daily').handler({});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      expect(json['content'], contains('no daily logs'));
    });
  });

  group('tool registration', () {
    test('registers exactly 4 memory tools', () {
      expect(entries, hasLength(4));
    });

    test('registers expected tool names', () {
      final names = entries.map((e) => e.name).toSet();
      expect(names, containsAll([
        'memory_read',
        'memory_write',
        'memory_append_daily',
        'memory_read_daily',
      ]));
    });
  });
}
