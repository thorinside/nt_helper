import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';

// Add a custom extension to access the server from the RequestHandlerExtra
// This might not be needed if the server instance is managed differently or passed via RequestHandlerExtra itself.
// For this refactor, we are creating a new McpServer per session (transport), so direct access via extra might be less relevant.
extension McpRequestHandlerExtra on RequestHandlerExtra {
  McpServer? get mcpServer =>
      null; // Placeholder, actual server instance comes from transport.connect
}

// Simple in-memory event store for resumability (from example)
class InMemoryEventStore implements EventStore {
  final Map<String, List<({EventId id, JsonRpcMessage message})>> _events = {};
  int _eventCounter = 0;

  @override
  Future<EventId> storeEvent(StreamId streamId, JsonRpcMessage message) async {
    final eventId = (++_eventCounter).toString();
    _events.putIfAbsent(streamId, () => []);
    _events[streamId]!.add((id: eventId, message: message));
    return eventId;
  }

  @override
  Future<StreamId> replayEventsAfter(
    EventId lastEventId, {
    required Future<void> Function(EventId eventId, JsonRpcMessage message)
        send,
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

/// Singleton that lets a Flutter app start/stop an MCP server using StreamableHTTPServerTransport.
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

  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _sub;
  final Map<String, StreamableHTTPServerTransport> _activeTransports = {};

  final DistingCubit _distingCubit;

  bool get isRunning => _httpServer != null;

  static void initialize({required DistingCubit distingCubit}) {
    if (_instance != null) {
      debugPrint('Warning: McpServerService already initialized.');
      return;
    }
    _instance = McpServerService._(distingCubit);
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
      _httpServer = await HttpServer.bind(address, port);
      debugPrint(
          '[MCP] Streamable HTTP Server listening on http://${address.address}:$port/mcp');

      _sub = _httpServer!.listen(
        (HttpRequest request) async {
          if (request.uri.path != '/mcp') {
            _sendHttpError(
                request, HttpStatus.notFound, 'Not Found. Use /mcp endpoint.');
            return;
          }

          switch (request.method) {
            case 'POST':
              await _handlePostRequest(request);
              break;
            case 'GET':
              await _handleGetRequest(request);
              break;
            case 'DELETE':
              await _handleDeleteRequest(request);
              break;
            default:
              _sendHttpError(request, HttpStatus.methodNotAllowed,
                  'Method Not Allowed. Use GET, POST, or DELETE.');
          }
        },
        onError: (error, stackTrace) {
          debugPrint(
              '[MCP] Critical error in HttpServer listener: $error\n$stackTrace');
          stop();
        },
        onDone: () {
          debugPrint('[MCP] HttpServer listener stream closed.');
          if (_httpServer != null) {
            _sub = null;
            _httpServer = null;
            _clearAllTransports();
            notifyListeners();
            debugPrint(
                '[MCP] Service effectively stopped due to HttpServer listener onDone.');
          }
        },
        cancelOnError: false,
      );
      notifyListeners();
    } catch (e, s) {
      debugPrint('[MCP] Failed to start McpServerService: $e\n$s');
      await stop(); // Ensure cleanup if start fails
      rethrow;
    }
  }

  Future<void> _handlePostRequest(HttpRequest request) async {
    try {
      final bodyBytes = await _collectBytes(request);
      final bodyString = utf8.decode(bodyBytes);
      final body = jsonDecode(bodyString);

      final sessionId = request.headers.value('mcp-session-id');
      StreamableHTTPServerTransport? transport;

      if (sessionId != null && _activeTransports.containsKey(sessionId)) {
        transport = _activeTransports[sessionId]!;
        debugPrint('[MCP] POST: Reusing transport for session $sessionId');
      } else if (sessionId == null && _isInitializeRequest(body)) {
        debugPrint('[MCP] POST: New initialize request. Creating transport.');
        final eventStore = InMemoryEventStore();
        transport = StreamableHTTPServerTransport(
          options: StreamableHTTPServerTransportOptions(
            sessionIdGenerator: () => generateUUID(),
            eventStore: eventStore,
            onsessioninitialized: (newSessionId) {
              debugPrint(
                  '[MCP] Session initialized with ID: $newSessionId. Storing transport.');
              _activeTransports[newSessionId] = transport!;
            },
          ),
        );

        transport.onclose = () {
          final sid = transport?.sessionId;
          if (sid != null && _activeTransports.containsKey(sid)) {
            debugPrint(
                '[MCP] Transport closed for session $sid, removing from active transports.');
            _activeTransports.remove(sid);
          }
        };

        final mcpServer = _buildServer();
        await mcpServer.connect(transport);
        debugPrint('[MCP] New McpServer connected to transport.');
      } else {
        _sendJsonError(request, HttpStatus.badRequest,
            'Bad Request: No valid session ID for non-initialize request, or missing session ID for initialize.');
        return;
      }

      await transport.handleRequest(request, body);
      debugPrint(
          '[MCP] POST request for session ${transport.sessionId} handled by transport.');
    } catch (e, s) {
      debugPrint('[MCP] Error handling POST /mcp request: $e\n$s');
      // Avoid sending error if headers already sent by transport.handleRequest
      if (request.response.connectionInfo != null &&
          request.response.headers.contentType?.mimeType !=
              'text/event-stream') {
        try {
          _sendJsonError(request, HttpStatus.internalServerError,
              'Internal server error processing POST request.');
        } catch (_) {
          /* Response likely closed */
        }
      }
    }
  }

  Future<void> _handleGetRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null || !_activeTransports.containsKey(sessionId)) {
      _sendHttpError(request, HttpStatus.badRequest,
          'Invalid or missing mcp-session-id for GET request.');
      return;
    }

    final transport = _activeTransports[sessionId]!;
    final lastEventId = request.headers.value('Last-Event-ID');
    if (lastEventId != null) {
      debugPrint(
          '[MCP] GET: Client reconnecting for session $sessionId with Last-Event-ID: $lastEventId');
    } else {
      debugPrint(
          '[MCP] GET: Establishing new SSE stream for session $sessionId');
    }
    try {
      await transport.handleRequest(request);
      debugPrint(
          '[MCP] GET request for session $sessionId handled by transport.');
    } catch (e, s) {
      debugPrint(
          '[MCP] Error handling GET /mcp request for session $sessionId: $e\n$s');
      // Transport.handleRequest for GET typically sets up SSE and might not allow further error writes here.
    }
  }

  Future<void> _handleDeleteRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null || !_activeTransports.containsKey(sessionId)) {
      _sendHttpError(request, HttpStatus.badRequest,
          'Invalid or missing mcp-session-id for DELETE request.');
      return;
    }

    debugPrint(
        '[MCP] DELETE: Received termination request for session $sessionId');
    final transport = _activeTransports[sessionId]!;
    try {
      await transport
          .handleRequest(request); // This should trigger onclose and cleanup
      debugPrint(
          '[MCP] DELETE request for session $sessionId handled by transport.');
    } catch (e, s) {
      debugPrint(
          '[MCP] Error handling DELETE /mcp request for session $sessionId: $e\n$s');
      // Transport.handleRequest for DELETE might also not allow further error writes.
    }
  }

  bool _isInitializeRequest(dynamic body) {
    return body is Map<String, dynamic> &&
        body.containsKey('method') &&
        body['method'] == 'initialize';
  }

  Future<List<int>> _collectBytes(HttpRequest request) {
    final completer = Completer<List<int>>();
    final bytes = <int>[];
    request.listen(
      bytes.addAll,
      onDone: () => completer.complete(bytes),
      onError: completer.completeError,
      cancelOnError: true,
    );
    return completer.future;
  }

  void _sendHttpError(HttpRequest request, int statusCode, String message) {
    try {
      if (request.response.connectionInfo == null) {
        return; // Already closed or headers sent
      }
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.text;
      request.response.write(message);
      request.response.close();
    } catch (e) {
      debugPrint('[MCP] Error sending plain HTTP error: $e');
    }
  }

  void _sendJsonError(HttpRequest request, int statusCode, String message,
      {String? id}) {
    try {
      if (request.response.connectionInfo == null) {
        return; // Already closed or headers sent
      }
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'jsonrpc': '2.0',
        'error': {'code': -32000, 'message': message},
        'id': id,
      }));
      request.response.close();
    } catch (e) {
      debugPrint('[MCP] Error sending JSON error: $e');
    }
  }

  Future<void> stop() async {
    if (!isRunning) {
      debugPrint(
          '[MCP] Stop called but server not running or already stopped.');
      return;
    }
    debugPrint('[MCP] Stopping MCP Streamable HTTP server...');

    await _sub?.cancel();
    _sub = null;

    await _httpServer?.close(force: true);
    _httpServer = null;

    _clearAllTransports();

    notifyListeners();
    debugPrint('[MCP] MCP Streamable HTTP Service stopped.');
  }

  void _clearAllTransports() {
    debugPrint('[MCP] Clearing ${_activeTransports.length} active transports.');
    for (final transport in _activeTransports.values) {
      try {
        transport.close(); // This should trigger their onclose handler
      } catch (e) {
        debugPrint('[MCP] Error closing transport during stop: $e');
      }
    }
    _activeTransports.clear();
  }

  final List<_ToolSpec> _pendingTools = [];

  void addTool(
    String name, {
    required String description,
    required Map<String, dynamic> inputSchemaProperties,
    required ToolCallback callback,
  }) {
    // In this model, tools are added to each McpServer instance when it's built.
    // So, _pendingTools will be used by _buildServer for new server instances.
    _pendingTools.add(
      _ToolSpec(name, description, inputSchemaProperties, callback),
    );
    // If a server is already running with transports, this new tool won't be available
    // on existing sessions. This matches the _buildServer per session model.
  }

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit);
    final distingTools = DistingTools(distingControllerForTools);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.25.0'),
      options: ServerOptions(capabilities: ServerCapabilities()),
    );

    // Register existing tools
    server.tool(
      'get_algorithm_details',
      description: 'Get algorithm metadata by GUID or name. Supports fuzzy matching >=70%.',
      inputSchemaProperties: {
        'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
        'algorithm_name': {'type': 'string', 'description': 'Algorithm name'},
        'expand_features': {'type': 'boolean', 'description': 'Expand parameters', 'default': false}
      },
      callback: ({args, extra}) async {
        final resultJson =
            await mcpAlgorithmTools.getAlgorithmDetails(args ?? {});
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
        final resultJson = await mcpAlgorithmTools.listAlgorithms(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_routing',
      description: 'Get current routing state. Always use physical names (Input N, Output N, Aux N, None).',
      inputSchemaProperties: {},
      callback: ({args, extra}) async {
        final resultJson =
            await mcpAlgorithmTools.getCurrentRoutingState(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_current_preset',
      description: 'Get preset with slots and parameters. Use parameter_number from this for set/get_parameter_value.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.getCurrentPreset(args ?? {});
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
        final resultJson = await distingTools.addAlgorithm(args ?? {});
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
        final resultJson = await distingTools.removeAlgorithm(args ?? {});
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
        final resultJson = await distingTools.setParameterValue(args ?? {});
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
        final resultJson = await distingTools.getParameterValue(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_preset_name',
      description: 'Set preset name. Use save_preset to persist.',
      inputSchemaProperties: {
        'name': {'type': 'string', 'description': 'Preset name'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.setPresetName(args ?? {});
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
        final resultJson = await distingTools.setSlotName(args ?? {});
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
        final resultJson = await distingTools.newPreset(args ?? {});
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
        final resultJson = await distingTools.savePreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_up',
      description: 'Move algorithm up one slot. Algorithms evaluate top to bottom.',
      inputSchemaProperties: {
        'slot_index': {'type': 'integer', 'description': '0-based slot index'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.moveAlgorithmUp(args ?? {});
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
        final resultJson = await distingTools.moveAlgorithmDown(args ?? {});
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
        final resultJson = await distingTools.moveAlgorithm(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_module_screenshot',
      description: 'Get current module screenshot as base64 JPEG.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter'}
      },
      callback: ({args, extra}) async {
        final Map<String, dynamic> result =
            await distingTools.getModuleScreenshot(args ?? {});
        if (result['success'] == true) {
          return CallToolResult.fromContent(content: [
            ImageContent(
              data: result['screenshot_base64'] as String,
              mimeType: 'image/jpeg',
            )
          ]);
        } else {
          return CallToolResult.fromContent(content: [
            TextContent(
                text: result['error'] as String? ??
                    'Unknown error retrieving screenshot')
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
        final resultJson = await distingTools.getCpuUsage(args ?? {});
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
        final resultJson = await distingTools.setNotes(args ?? {});
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
        final resultJson = await distingTools.getNotes(args ?? {});
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
        final resultJson = await distingTools.getPresetName(args ?? {});
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
        final resultJson = await distingTools.getSlotName(args ?? {});
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
        final resultJson = await distingTools.findAlgorithmInPreset(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

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
        final resultJson = await distingTools.setMultipleParameters(args ?? {});
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
        final resultJson = await distingTools.getMultipleParameters(args ?? {});
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
        final resultJson = await distingTools.buildPresetFromJson(args ?? {});
        return CallToolResult.fromContent(content: [TextContent(text: resultJson)]);
      },
    );

    // Add any tools dynamically added via addTool()
    for (final t in _pendingTools) {
      server.tool(
        t.name,
        description: t.description,
        inputSchemaProperties: t.inputSchemaProperties,
        callback: t.callback,
      );
    }
    // Unlike the single server model, _pendingTools shouldn't be cleared here
    // as _buildServer can be called multiple times for new sessions.
    // Keep tools available for future sessions by NOT clearing _pendingTools
    // _pendingTools.clear(); // REMOVED: This was causing tools to disappear on reconnection

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
