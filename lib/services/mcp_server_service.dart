import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';

/// Singleton that lets a Flutter app start/stop an SSE MCP server.
class McpServerService extends ChangeNotifier {
  McpServerService._();
  static final McpServerService instance = McpServerService._();

  McpServer? _mcpServer;
  SseServerManager? _sseManager;
  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _sub;

  // TODO: Determine how to inject/obtain the DistingCubit instance reliably.
  // Option 1: Pass during initialization or start().
  // Option 2: Use a global service locator.
  // For now, assuming it's available when _buildServer is called.
  DistingCubit? _distingCubit; // Placeholder for the cubit instance

  bool get isRunning => _httpServer != null;

  // ──────────────────────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────────────────────

  /// Initialize the service, potentially providing dependencies.
  /// Call this early in the app lifecycle.
  void initialize({required DistingCubit distingCubit}) {
    _distingCubit = distingCubit;
  }

  /// Start the server on [port] and (optionally) [bindAddress].
  Future<void> start({
    int port = 3000,
    InternetAddress? bindAddress,
  }) async {
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
    notifyListeners();
    debugPrint('[MCP] stopped');
  }

  /// Register additional tools **before** `start()`.
  void addTool(
    String name, {
    required String description,
    required Map<String, dynamic> inputSchemaProperties,
    required ToolCallback callback,
  }) {
    if (_mcpServer == null) {
      _pendingTools.add(
        _ToolSpec(name, description, inputSchemaProperties, callback),
      );
    } else {
      _mcpServer!.tool(
        name,
        description: description,
        inputSchemaProperties: inputSchemaProperties,
        callback: callback,
      );
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internals
  // ──────────────────────────────────────────────────────────────────────────

  final List<_ToolSpec> _pendingTools = [];

  McpServer _buildServer() {
    // Ensure DistingCubit is available
    if (_distingCubit == null) {
      throw StateError(
          'McpServerService not initialized with DistingCubit. Call initialize() first.');
    }

    // Instantiate tools class with the cubit
    final mcpTools = MCPAlgorithmTools(_distingCubit!);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.23.0'),
      options: ServerOptions(capabilities: ServerCapabilities()),
    );

    // --- Example "calculate" tool ------------------------------------------
    server.tool(
      'calculate',
      description: 'Perform basic arithmetic operations',
      inputSchemaProperties: {
        'operation': {
          'type': 'string',
          'enum': ['add', 'subtract', 'multiply', 'divide'],
        },
        'a': {'type': 'number'},
        'b': {'type': 'number'},
      },
      callback: ({args, extra}) {
        final op = args!['operation'] as String;
        final num a = args['a'];
        final num b = args['b'];
        final result = switch (op) {
          'add' => a + b,
          'subtract' => a - b,
          'multiply' => a * b,
          'divide' => a / b,
          _ => throw ArgumentError('Invalid op: $op')
        };
        return CallToolResult(
          content: [TextContent(text: 'Result: $result')],
        );
      },
    );

    // --- Register Algorithm Metadata Tools --- (Update to use instance methods)
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
            await mcpTools.get_algorithm_details(args ?? {}); // Use instance
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
        final resultJson =
            await mcpTools.list_algorithms(args ?? {}); // Use instance
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
        final resultJson =
            await mcpTools.find_algorithms(args ?? {}); // Use instance
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    // --- Register NEW Routing Tool ---
    server.tool(
      'get_current_routing_state',
      description:
          'Retrieves the current routing state decoded into RoutingInformation objects.',
      inputSchemaProperties: {}, // No input parameters
      callback: ({args, extra}) async {
        final resultJson = await mcpTools
            .get_current_routing_state(args ?? {}); // Use instance
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    // Pending user-added tools
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
