import 'dart:convert';

import 'package:nt_helper/chat/models/llm_types.dart';
import 'package:nt_helper/mcp/tool_registry.dart';

/// Bridges the shared ToolRegistry to the LLM interface.
///
/// Converts [ToolRegistryEntry] definitions to [LlmToolDefinition]s and
/// dispatches tool execution requests.
class ToolBridgeService {
  final ToolRegistry _registry;

  ToolBridgeService(this._registry);

  /// Get all tool definitions for sending to the LLM.
  List<LlmToolDefinition> get toolDefinitions {
    return _registry.entries
        .map((e) => LlmToolDefinition(
              name: e.name,
              description: e.description,
              inputSchema: e.inputSchema,
            ))
        .toList();
  }

  /// Execute a tool by name with the given arguments.
  Future<String> executeTool(String name, Map<String, dynamic> arguments) async {
    final entry = _registry.findByName(name);
    if (entry == null) {
      return jsonEncode({
        'success': false,
        'error': 'Unknown tool: $name',
      });
    }

    try {
      return await entry.handler(arguments).timeout(
        entry.timeout,
        onTimeout: () => jsonEncode({
          'success': false,
          'error':
              'Tool execution timed out after ${entry.timeout.inSeconds} seconds',
        }),
      );
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': 'Tool execution failed: $e',
      });
    }
  }
}
