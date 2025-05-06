import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/disting_controller.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';

/// Singleton that lets a Flutter app start/stop an SSE MCP server.
class McpServerService extends ChangeNotifier {
  McpServerService._(this._distingCubit)
      : _distingController = DistingControllerImpl(_distingCubit),
        _mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit),
        _distingTools = DistingTools(DistingControllerImpl(_distingCubit)) {}

  static McpServerService? _instance;
  static McpServerService get instance {
    if (_instance == null) {
      throw StateError(
          'McpServerService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  McpServer? _mcpServer;
  SseServerManager? _sseManager;
  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _sub;

  final DistingCubit _distingCubit;

  final MCPAlgorithmTools _mcpAlgorithmTools;
  final DistingTools _distingTools;
  final DistingController _distingController;

  bool get isRunning => _httpServer != null;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialize the singleton instance.
  /// Call this early in the app lifecycle (e.g., main.dart).
  static void initialize({required DistingCubit distingCubit}) {
    if (_instance != null) {
      debugPrint('Warning: McpServerService already initialized.');
      return;
    }
    _instance = McpServerService._(distingCubit);
  }

  /// Start the server on [port] and (optionally) [bindAddress].
  Future<void> start({
    int port = 3000,
    InternetAddress? bindAddress,
  }) async {
    if (_instance == null) {
      throw StateError(
          'McpServerService not initialized. Call initialize() first.');
    }
    if (isRunning) return;

    _mcpServer = _buildServer();
    _sseManager = SseServerManager(_mcpServer!);

    final address = bindAddress ?? InternetAddress.anyIPv4;
    _httpServer = await HttpServer.bind(address, port);
    _sub = _httpServer!.listen(_sseManager!.handleRequest);

    debugPrint('[MCP] listening on http://${address.address}:$port');
    notifyListeners();
  }

  /// Stop and dispose resources.
  Future<void> stop() async {
    await _sub?.cancel();
    await _httpServer?.close(force: true);
    _sub = null;
    _httpServer = null;
    _mcpServer = null;
    _sseManager = null;
    notifyListeners();
    debugPrint('[MCP] stopped');
  }

  /// Register additional tools **before** `start()`.
  /// Note: Dynamic tool addition after start is not supported by this structure.
  void addTool(
    String name, {
    required String description,
    required Map<String, dynamic> inputSchemaProperties,
    required ToolCallback callback,
  }) {
    if (isRunning) {
      debugPrint('Warning: Cannot add tools after the MCP server has started.');
      return;
    }
    _pendingTools.add(
      _ToolSpec(name, description, inputSchemaProperties, callback),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internals
  // ──────────────────────────────────────────────────────────────────────────

  final List<_ToolSpec> _pendingTools = [];

  McpServer _buildServer() {
    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.23.0'),
      options: ServerOptions(capabilities: ServerCapabilities()),
    );

    server.tool(
      'get_algorithm_details',
      description:
          'Retrieves full metadata for a specific algorithm by its GUID.',
      inputSchemaProperties: {
        'guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'expand_features': {
          'type': 'boolean',
          'description': 'Expand parameters from features',
          'default': false
        }
      },
      callback: ({args, extra}) async {
        final resultJson =
            await _mcpAlgorithmTools.get_algorithm_details(args ?? {});
        if (resultJson == null) {
          return CallToolResult(
              content: [TextContent(text: 'Error: Algorithm not found')]);
        }
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'list_algorithms',
      description:
          'Returns a list of available algorithms, optionally filtered.',
      inputSchemaProperties: {
        'category': {
          'type': 'string',
          'description': 'Filter by category (case-insensitive)'
        },
        'feature_guid': {
          'type': 'string',
          'description': 'Filter by included feature GUID'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _mcpAlgorithmTools.list_algorithms(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'find_algorithms',
      description: 'Performs text search across algorithm metadata.',
      inputSchemaProperties: {
        'query': {'type': 'string', 'description': 'Search query text'}
      },
      callback: ({args, extra}) async {
        final resultJson = await _mcpAlgorithmTools.find_algorithms(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_current_routing_state',
      description:
          'Retrieves the current routing state decoded into RoutingInformation objects.',
      inputSchemaProperties: {},
      callback: ({args, extra}) async {
        final resultJson =
            await _mcpAlgorithmTools.get_current_routing_state(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'getCurrentPreset',
      description:
          'Gets the entire current preset state (name, slots, parameters).',
      inputSchemaProperties: {
        'random_string': {
          'type': 'string',
          'description': 'Dummy parameter for no-parameter tools'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.get_current_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'addAlgorithm',
      description: 'Adds an algorithm to the first available empty slot.',
      inputSchemaProperties: {
        'algorithm_guid': {
          'type': 'string',
          'description': 'GUID of the algorithm to add'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.add_algorithm(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'removeAlgorithm',
      description: 'Removes (clears) the algorithm from a specific slot.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': 'Index of the slot to clear'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.remove_algorithm(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'setParameterValue',
      description:
          'Sets the value of a specific parameter in a slot, using its display value (handles powerOfTen scaling automatically).',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based index of the slot containing the algorithm.'
        },
        'parameter_index': {
          'type': 'integer',
          'description':
              "0-based index of the parameter within the algorithm's list."
        },
        'display_value': {
          'type': 'number', // Can be int or double (e.g., 5 or 2.5 for Hz)
          'description':
              'The human-readable display value for the parameter (e.g., 5 for 5Hz, 2.5 for 2.5s).'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.set_parameter_value(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'getParameterValue',
      description:
          'Gets the current value of a specific parameter from the device.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based index of the slot containing the algorithm.'
        },
        'parameter_index': {
          'type': 'integer',
          'description':
              "0-based index of the parameter within the algorithm's list."
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.get_parameter_value(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'setCurrentPresetName',
      description:
          'Sets the name of the currently loaded preset on the device.',
      inputSchemaProperties: {
        'name': {
          'type': 'string',
          'description': 'The new name for the preset.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson =
            await _distingTools.set_current_preset_name(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'setSlotName',
      description: 'Sets a custom name for the algorithm in a specific slot.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based index of the slot to name.'
        },
        'name': {
          'type': 'string',
          'description': 'The desired custom name for the slot.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.set_slot_name(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'newPreset',
      description:
          'Tells the device to clear the current preset and start a new, empty one.',
      inputSchemaProperties: {
        // No specific parameters needed, but schema can be empty
        'random_string': {
          // Gemini seems to prefer at least one dummy param for no-arg tools
          'type': 'string',
          'description':
              'Dummy parameter for no-parameter tools (can be any string).'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.new_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'savePreset',
      description: 'Tells the device to save the current working preset.',
      inputSchemaProperties: {
        'random_string': {
          // Dummy parameter
          'type': 'string',
          'description':
              'Dummy parameter for no-parameter tools (can be any string).'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.save_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    for (final t in _pendingTools) {
      server.tool(
        t.name,
        description: t.description,
        inputSchemaProperties: t.inputSchemaProperties,
        callback: t.callback,
      );
    }
    _pendingTools.clear();

    return server;
  }
}

class _ToolSpec {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchemaProperties;
  final ToolCallback callback;
  _ToolSpec(
      this.name, this.description, this.inputSchemaProperties, this.callback);
}
