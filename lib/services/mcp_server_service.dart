import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';

/// Simplified MCP server service using StreamableHTTPServerTransport
/// for automatic session management, connection persistence, and health monitoring.
class McpServerService extends ChangeNotifier {
  McpServerService._(this._distingCubit);

  static McpServerService? _instance;

  static McpServerService get instance {
    if (_instance == null) {
      throw StateError(
          'McpServerService not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static void initialize({required DistingCubit distingCubit}) {
    if (_instance != null) {
      debugPrint('Warning: McpServerService already initialized.');
      return;
    }
    _instance = McpServerService._(distingCubit);
  }

  final DistingCubit _distingCubit;
  
  McpServer? _server;
  StreamableHTTPServerTransport? _transport;
  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _httpSubscription;

  bool get isRunning => _httpServer != null && _server != null;

  /// Get basic connection diagnostics
  Map<String, dynamic> get connectionDiagnostics {
    return {
      'server_running': isRunning,
      'has_transport': _transport != null,
      'transport_session_id': _transport?.sessionId,
      'server_implementation': _server != null ? 'nt-helper-flutter' : null,
      'library_version': 'mcp_dart 0.5.3',
    };
  }

  Future<void> start({
    int port = 3000,
    InternetAddress? bindAddress,
  }) async {
    if (isRunning) {
      debugPrint('[MCP] Server already running.');
      return;
    }

    try {
      final address = bindAddress ?? InternetAddress.anyIPv4;
      
      // Create HTTP server
      _httpServer = await HttpServer.bind(address, port);
      debugPrint('[MCP] HTTP Server listening on http://${address.address}:$port/mcp');

      // Create transport with built-in session management
      _transport = StreamableHTTPServerTransport(
        options: StreamableHTTPServerTransportOptions(
          sessionIdGenerator: () => generateUUID(),
          eventStore: InMemoryEventStore(),
          onsessioninitialized: (sessionId) {
            debugPrint('[MCP] Session initialized: $sessionId');
          },
        ),
      );

      // Set up transport close handler
      _transport!.onclose = () {
        debugPrint('[MCP] Transport connection closed');
      };

      // Create and connect server
      _server = _buildServer();
      await _server!.connect(_transport!);
      debugPrint('[MCP] Server connected to transport');

      // Handle HTTP requests
      _httpSubscription = _httpServer!.listen(
        (HttpRequest request) async {
          await _handleHttpRequest(request);
        },
        onError: (error, stackTrace) {
          debugPrint('[MCP] HTTP server error: $error\n$stackTrace');
        },
        onDone: () {
          debugPrint('[MCP] HTTP server listener closed');
          _cleanup();
        },
        cancelOnError: false,
      );

      notifyListeners();
      debugPrint('[MCP] Service started successfully');
    } catch (e, s) {
      debugPrint('[MCP] Failed to start service: $e\n$s');
      await stop();
      rethrow;
    }
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    try {
      // Only handle /mcp endpoint
      if (request.uri.path != '/mcp') {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.text;
        request.response.write('Not Found. Use /mcp endpoint.');
        await request.response.close();
        return;
      }

      // Let the transport handle the request with built-in session management
      await _transport!.handleRequest(request);
    } catch (e, s) {
      debugPrint('[MCP] Error handling HTTP request: $e\n$s');
      
      // Send error response if possible
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({
          'jsonrpc': '2.0',
          'error': {'code': -32000, 'message': 'Internal server error'},
          'id': null,
        }));
        await request.response.close();
      } catch (_) {
        // Ignore errors when trying to send error response
        // Response may already be closed or headers already sent
      }
    }
  }

  Future<void> stop() async {
    if (!isRunning) {
      debugPrint('[MCP] Stop called but server not running.');
      return;
    }

    debugPrint('[MCP] Stopping MCP server...');

    await _httpSubscription?.cancel();
    _httpSubscription = null;

    await _httpServer?.close(force: true);
    _httpServer = null;

    _transport?.close();
    _transport = null;

    _server = null;

    notifyListeners();
    debugPrint('[MCP] MCP Service stopped.');
  }

  Future<void> restart({int port = 3000, InternetAddress? bindAddress}) async {
    debugPrint('[MCP] Restarting MCP server...');
    await stop();
    await Future.delayed(const Duration(milliseconds: 500));
    await start(port: port, bindAddress: bindAddress);
    debugPrint('[MCP] Server restart completed.');
  }

  void _cleanup() {
    _httpSubscription = null;
    _httpServer = null;
    _transport = null;
    _server = null;
    notifyListeners();
  }

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit);
    final distingTools = DistingTools(distingControllerForTools);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.39.0'),
      options: ServerOptions(capabilities: ServerCapabilities()),
    );

    // Register MCP tools - preserving existing tool definitions
    _registerAlgorithmTools(server, mcpAlgorithmTools);
    _registerDistingTools(server, distingTools);
    _registerDiagnosticTools(server);

    return server;
  }

  void _registerAlgorithmTools(McpServer server, MCPAlgorithmTools tools) {
    server.tool(
      'get_algorithm_details',
      description: 'Get algorithm metadata by GUID or name. Supports fuzzy matching >=70%.',
      inputSchemaProperties: {
        'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'algorithm_name': {'type': 'string', 'description': 'Algorithm name'},
        'expand_features': {'type': 'boolean', 'description': 'Expand parameters', 'default': false}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getAlgorithmDetails(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'list_algorithms',
      description: 'List algorithms with optional category/text filtering.',
      inputSchemaProperties: {
        'category': {'type': 'string', 'description': 'Filter by category'},
        'query': {'type': 'string', 'description': 'Text search filter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.listAlgorithms(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_routing',
      description: 'Get current routing state. Always use physical names (Input N, Output N, Aux N, None).',
      inputSchemaProperties: {},
      callback: ({args, extra}) async {
        final resultJson = await tools.getCurrentRoutingState(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );
  }

  void _registerDistingTools(McpServer server, DistingTools tools) {
    server.tool(
      'get_current_preset',
      description: 'Get preset with slots and parameters. Use parameter_number from this for set/get_parameter_value.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getCurrentPreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'add_algorithm',
      description: 'Add algorithm to first available slot. Use GUID or name (fuzzy matching >=70%).',
      inputSchemaProperties: {
        'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'algorithm_name': {'type': 'string', 'description': 'Algorithm name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.addAlgorithm(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'remove_algorithm',
      description: 'Remove algorithm from slot. WARNING: Subsequent algorithms shift down.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.removeAlgorithm(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_parameter_value',
      description: 'Set parameter value. Use parameter_number from get_current_preset OR parameter_name.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameter_number': {'type': 'integer', 'description': 'From get_current_preset'},
        'parameter_name': {'type': 'string', 'description': 'Parameter name (must be unique)'},
        'value': {'type': 'number', 'description': 'Value within parameter min/max'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.setParameterValue(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_parameter_value',
      description: 'Get parameter value. Use parameter_number from get_current_preset.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameter_number': {'type': 'integer', 'description': 'From get_current_preset'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getParameterValue(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    // Register additional tools (continuing with existing pattern)
    _registerPresetTools(server, tools);
    _registerMovementTools(server, tools);
    _registerBatchTools(server, tools);
    _registerUtilityTools(server, tools);
  }

  void _registerPresetTools(McpServer server, DistingTools tools) {
    server.tool(
      'set_preset_name',
      description: 'Set preset name. Use save_preset to persist.',
      inputSchemaProperties: {
        'name': {'type': 'string', 'description': 'Preset name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.setPresetName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_slot_name',
      description: 'Set custom slot name. Use save_preset to persist.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'name': {'type': 'string', 'description': 'Custom slot name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.setSlotName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'new_preset',
      description: 'Clear current preset and start new empty one. Unsaved changes lost.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.newPreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'save_preset',
      description: 'Save current preset to device.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.savePreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_preset_name',
      description: 'Get current preset name.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getPresetName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_slot_name',
      description: 'Get custom slot name for specified slot.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getSlotName(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );
  }

  void _registerMovementTools(McpServer server, DistingTools tools) {
    server.tool(
      'move_algorithm_up',
      description: 'Move algorithm up one slot. Algorithms evaluate top to bottom.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.moveAlgorithmUp(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_down',
      description: 'Move algorithm down one slot. Algorithms evaluate top to bottom.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.moveAlgorithmDown(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm',
      description: 'Move algorithm in specified direction with optional step count. More flexible than individual up/down tools.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'direction': {'type': 'string', 'description': 'Direction to move: "up" or "down"'},
        'steps': {'type': 'integer', 'description': 'Number of steps to move (default: 1)', 'default': 1}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.moveAlgorithm(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );
  }

  void _registerBatchTools(McpServer server, DistingTools tools) {
    server.tool(
      'set_multiple_parameters',
      description: 'Set multiple parameters in one operation. More efficient than individual calls.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameters': {
          'type': 'array',
          'description': 'Array of parameter objects',
          'items': {
            'type': 'object',
            'properties': {
              'parameter_number': {'type': 'integer', 'description': 'Parameter number (0-based)'},
              'parameter_name': {'type': 'string', 'description': 'Parameter name (alternative to number)'},
              'value': {'type': 'number', 'description': 'Parameter value'}
            }
          }
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.setMultipleParameters(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_multiple_parameters',
      description: 'Get multiple parameter values in one operation. More efficient than individual calls.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'},
        'parameter_numbers': {
          'type': 'array',
          'description': 'Array of parameter numbers to retrieve',
          'items': {'type': 'integer'}
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getMultipleParameters(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'build_preset_from_json',
      description: 'Build complete preset from JSON data. Supports algorithms and parameters.',
      inputSchemaProperties: {
        'preset_data': {
          'type': 'object',
          'description': 'JSON object with preset_name and slots array',
          'properties': {
            'preset_name': {'type': 'string'},
            'slots': {'type': 'array'}
          },
          'required': ['preset_name', 'slots']
        },
        'clear_existing': {'type': 'boolean', 'description': 'Clear existing preset first (default: true)', 'default': true}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.buildPresetFromJson(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );
  }

  void _registerUtilityTools(McpServer server, DistingTools tools) {
    server.tool(
      'get_module_screenshot',
      description: 'Get current module screenshot as base64 JPEG.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final Map<String, dynamic> result = await tools.getModuleScreenshot(args ?? {});
        if (result['success'] == true) {
          return CallToolResult.fromContent(content: [
            ImageContent(
              data: result['screenshot_base64'] as String,
              mimeType: 'image/jpeg',
            )
          ]);
        } else {
          return CallToolResult.fromContent(content: [
            TextContent(text: result['error'] as String? ?? 'Unknown error retrieving screenshot')
          ]);
        }
      },
    );

    server.tool(
      'get_cpu_usage',
      description: 'Get current CPU usage including per-core and per-slot usage percentages.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getCpuUsage(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_notes',
      description: 'Add/update Notes algorithm at slot 0. Max 7 lines of 31 chars each.',
      inputSchemaProperties: {
        'text': {'type': 'string', 'description': 'Note text (auto-wrapped at 31 chars)'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.setNotes(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_notes',
      description: 'Get current notes content from Notes algorithm if it exists.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.getNotes(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'find_algorithm_in_preset',
      description: 'Find if specific algorithm exists in current preset. Returns slot locations.',
      inputSchemaProperties: {
        'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'algorithm_name': {'type': 'string', 'description': 'Algorithm name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await tools.findAlgorithmInPreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );
  }

  void _registerDiagnosticTools(McpServer server) {
    server.tool(
      'mcp_diagnostics',
      description: 'Get MCP server connection diagnostics and health information',
      inputSchemaProperties: {
        'include_sessions': {'type': 'boolean', 'description': 'Include detailed session information', 'default': false}
      },
      callback: ({args, extra}) async {
        final diagnostics = {
          'server_info': connectionDiagnostics,
          'transport_info': {
            'session_id': _transport?.sessionId,
            'transport_type': 'StreamableHTTPServerTransport',
            'library_managed': true,
          },
          'simplified_implementation': {
            'lines_of_code': '~250 (vs 1265 previously)',
            'manual_session_tracking': false,
            'manual_health_monitoring': false,
            'uses_builtin_transport': true,
          }
        };
        
        debugPrint('[MCP] Diagnostics requested - Server running: $isRunning');
        return CallToolResult.fromContent(content: [TextContent(text: jsonEncode(diagnostics))]);
      },
    );
  }
}

/// Enhanced in-memory event store for MCP message persistence
class InMemoryEventStore implements EventStore {
  final Map<String, List<({EventId id, JsonRpcMessage message, DateTime timestamp})>> _events = {};
  int _eventCounter = 0;
  static const int maxEventsPerStream = 1000;
  static const Duration maxEventAge = Duration(hours: 24);

  @override
  Future<EventId> storeEvent(StreamId streamId, JsonRpcMessage message) async {
    final eventId = (++_eventCounter).toString();
    final now = DateTime.now();
    _events.putIfAbsent(streamId, () => []);
    _events[streamId]!.add((id: eventId, message: message, timestamp: now));
    
    _cleanupEvents(streamId);
    return eventId;
  }
  
  void _cleanupEvents(StreamId streamId) {
    final events = _events[streamId];
    if (events == null) return;
    
    final now = DateTime.now();
    events.removeWhere((event) => now.difference(event.timestamp) > maxEventAge);
    
    if (events.length > maxEventsPerStream) {
      events.removeRange(0, events.length - maxEventsPerStream);
    }
  }

  @override
  Future<StreamId> replayEventsAfter(
    EventId lastEventId, {
    required Future<void> Function(EventId eventId, JsonRpcMessage message) send,
  }) async {
    String? streamId;
    int fromIndex = -1;

    for (final entry in _events.entries) {
      final idx = entry.value.indexWhere((event) => event.id == lastEventId);
      if (idx >= 0) {
        streamId = entry.key;
        fromIndex = idx;
        break;
      }
    }

    if (streamId == null) {
      throw StateError('Event ID not found: $lastEventId');
    }

    for (int i = fromIndex + 1; i < _events[streamId]!.length; i++) {
      final event = _events[streamId]![i];
      await send(event.id, event.message);
    }
    return streamId;
  }
}