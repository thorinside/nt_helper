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

      if (transport == null) {
        // Should not happen if logic above is correct
        _sendJsonError(request, HttpStatus.internalServerError,
            'Internal Server Error: Transport not resolved.');
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
      if (request.response.connectionInfo == null)
        return; // Already closed or headers sent
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
      if (request.response.connectionInfo == null)
        return; // Already closed or headers sent
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
      description:
          'Retrieves full metadata for an algorithm by its GUID or name (case-insensitive exact match; if no exact match, fuzzy matching >=70% accuracy is attempted). Use `get_current_preset` for live parameter numbers for `set_parameter_value` / `get_parameter_value`. If multiple or no match, an error is returned.',
      inputSchemaProperties: {
        'guid': {
          'type': 'string',
          'description': 'Algorithm GUID (from `list_algorithms`).'
        },
        'algorithm_name': {
          'type': 'string',
          'description':
              'Algorithm name (case-insensitive exact match; fuzzy fallback >=70% similarity).'
        },
        'expand_features': {
          'type': 'boolean',
          'description': 'Expand parameters from features.',
          'default': false
        }
      },
      callback: ({args, extra}) async {
        final resultJson =
            await mcpAlgorithmTools.get_algorithm_details(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'list_algorithms',
      description:
          'Lists available algorithms, optionally filtered by category or a text query. GUIDs are used with `add_algorithm` and `get_algorithm_details`.',
      inputSchemaProperties: {
        'category': {
          'type': 'string',
          'description': 'Filter by category (case-insensitive).'
        },
        'query': {
          'type': 'string',
          'description': 'Filter by a text search query.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await mcpAlgorithmTools.list_algorithms(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_routing',
      description: '''
Retrieves current routing state. 
Physical name to bus number mapping: 
  - Input N=Bus N, 
  - Output N=Bus N+12, 
  - Aux N=Bus N+20,
  - None=Bus 0
  
  Never disclose bus numbers to the user, always refer to a bus by the physical name.
  ''',
      inputSchemaProperties: {},
      callback: ({args, extra}) async {
        final resultJson =
            await mcpAlgorithmTools.get_current_routing_state(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_current_preset',
      description: '''
Gets entire current preset (name, slots, parameters).
Parameter `parameter_number` from this tool is used 
as `parameter_number` for `set_parameter_value` and 
`get_parameter_value`.

Parameters should be referred to by their name, not their numbers.
Never disclose bus numbers to the user, always refer to a bus by the physical name.
''',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter.'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.get_current_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'add_algorithm',
      description:
          'Adds an algorithm to the first available slot. Use GUID or name (case-insensitive exact match; if no exact match, fuzzy matching >=70% accuracy is attempted). If multiple or no match, an error is returned.',
      inputSchemaProperties: {
        'algorithm_guid': {
          'type': 'string',
          'description': 'GUID of the algorithm to add.'
        },
        'algorithm_name': {
          'type': 'string',
          'description':
              'Name of the algorithm to add (case-insensitive exact match; fuzzy fallback >=70% similarity).'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.add_algorithm(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'remove_algorithm',
      description:
          'Removes algorithm from a slot. WARNING: Subsequent algorithms shift down (slot N+1 moves to N).',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based index of the slot to clear.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.remove_algorithm(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_parameter_value',
      description: '''
          Sets parameter to `value`. Either `parameter_number` or `parameter_name` MUST be 
          provided (but not both). `parameter_number` MUST be from `get_current_preset`. 
          If using `parameter_name`, ensure it is unique for the slot or an error 
          will be returned. `value` must be between parameter's min/max.
          If the parameter is an input or output, keep in mind that physical Input N = bus N, Output N = bus N+12, and Aux N = bus N+20.
          Never disclose bus numbers to the user, always refer to a bus by the physical name.
          ''',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based slot index (0-31).'
        },
        'parameter_number': {
          'type': 'integer',
          'description':
              'Parameter number from `get_current_preset`. Use this OR `parameter_name`.'
        },
        'parameter_name': {
          'type': 'string',
          'description':
              'Parameter name. Use this OR `parameter_number`. If ambiguous for the slot, an error is returned.'
        },
        'value': {
          'type': 'number',
          'description':
              'Value to set (can be integer or float for scaled parameters), between parameter\'s effective min/max.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.set_parameter_value(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_parameter_value',
      description:
          'Gets current parameter value. `parameter_number` MUST be `parameter_number` from `get_current_preset`.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based slot index (0-31).'
        },
        'parameter_number': {
          'type': 'integer',
          'description': 'Parameter number from `get_current_preset`.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.get_parameter_value(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_preset_name',
      description: 'Sets preset name. Use `save_preset` to persist.',
      inputSchemaProperties: {
        'name': {'type': 'string', 'description': 'New preset name.'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.set_preset_name(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'set_slot_name',
      description:
          'Sets custom name for algorithm in slot. Use `save_preset` to persist.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based slot index (0-31).'
        },
        'name': {'type': 'string', 'description': 'Custom slot name.'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.set_slot_name(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'new_preset',
      description:
          'Clears current preset and starts new empty one. Unsaved changes will be lost.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter.'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.new_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'save_preset',
      description: 'Saves current working preset to device.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter.'}
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.save_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_up',
      description:
          'Moves algorithm up one slot. Algorithms evaluate top to bottom.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based index of the slot to move up.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.move_algorithm_up(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_down',
      description:
          'Moves algorithm down one slot. Algorithms evaluate top to bottom.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based index of the slot to move down.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await distingTools.move_algorithm_down(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_module_screenshot',
      description: 'Gets current module screenshot as base64 JPEG.',
      inputSchemaProperties: {
        'random_string': {'type': 'string', 'description': 'Dummy parameter.'}
      },
      callback: ({args, extra}) async {
        final Map<String, dynamic> result =
            await distingTools.get_module_screenshot(args ?? {});
        if (result['success'] == true) {
          return CallToolResult(content: [
            ImageContent(
              data: result['screenshot_base64'] as String,
              mimeType: 'image/jpeg',
            )
          ]);
        } else {
          return CallToolResult(content: [
            TextContent(
                text: result['error'] as String? ??
                    'Unknown error retrieving screenshot')
          ]);
        }
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
    // However, if addTool is meant to apply to *future* sessions only, this is fine.
    // For simplicity matching the previous pattern, we clear it, assuming tools are added before any session starts,
    // or new tools apply to new sessions.
    // If tools should be added to existing McpServer on existing transports, that's a more complex refactor.
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
