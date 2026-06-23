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
        .map(
          (e) => LlmToolDefinition(
            name: e.name,
            description: e.description,
            inputSchema: e.inputSchema,
          ),
        )
        .toList();
  }

  /// Execute a tool by name with the given arguments.
  Future<String> executeTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    return _registry.executeTool(name, arguments);
  }
}
