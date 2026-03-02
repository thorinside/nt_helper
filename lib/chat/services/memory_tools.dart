import 'dart:convert';

import 'package:nt_helper/chat/services/memory_service.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

/// Registers memory tool handlers with the ToolRegistry.
void registerMemoryTools(List<ToolRegistryEntry> entries, MemoryService memoryService) {
  entries.add(ToolRegistryEntry(
    name: 'memory_read',
    description: 'Read the persistent semantic memory file.',
    inputSchema: {'properties': {}},
    handler: (_) async {
      final content = await memoryService.readMemory();
      return jsonEncode({
        'success': true,
        'content': content.isEmpty ? '(empty — no memory saved yet)' : content,
      });
    },
  ));

  entries.add(ToolRegistryEntry(
    name: 'memory_write',
    description:
        'Replace the persistent semantic memory file. Read first to avoid losing content. '
        'Use for stable facts, preferences, and setup info. 200-line cap enforced.',
    inputSchema: {
      'properties': {
        'content': {
          'type': 'string',
          'description': 'Full replacement content for memory.md.',
        },
      },
      'required': ['content'],
    },
    handler: (args) async {
      final raw = args['content'];
      final content = raw is String ? raw : raw?.toString();
      if (content == null || content.isEmpty) {
        return jsonEncode({'success': false, 'error': 'content is required'});
      }
      await memoryService.writeMemory(content);
      return jsonEncode({'success': true});
    },
  ));

  entries.add(ToolRegistryEntry(
    name: 'memory_append_daily',
    description:
        'Append an entry to today\'s daily log. '
        'Use for session notes, what was worked on, and temporary context.',
    inputSchema: {
      'properties': {
        'entry': {
          'type': 'string',
          'description': 'Log entry to append (timestamped automatically).',
        },
      },
      'required': ['entry'],
    },
    handler: (args) async {
      final raw = args['entry'];
      final entry = raw is String ? raw : raw?.toString();
      if (entry == null || entry.isEmpty) {
        return jsonEncode({'success': false, 'error': 'entry is required'});
      }
      await memoryService.appendDailyLog(entry);
      return jsonEncode({'success': true});
    },
  ));

  entries.add(ToolRegistryEntry(
    name: 'memory_read_daily',
    description: 'Read today\'s and yesterday\'s daily log entries.',
    inputSchema: {'properties': {}},
    handler: (_) async {
      final content = await memoryService.readDailyLogs();
      return jsonEncode({
        'success': true,
        'content': content.isEmpty ? '(no daily logs found)' : content,
      });
    },
  ));
}
