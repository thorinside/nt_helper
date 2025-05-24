import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/services/disting_controller_impl.dart'; // Needed for DistingTools

// Define SessionResources to hold per-session data including the ping timer and transport
class SessionResources {
  final McpServer server;
  final SseServerManager manager;
  final SseServerTransport? transport;
  Timer? pingTimer;

  SessionResources({
    required this.server,
    required this.manager,
    this.transport,
    this.pingTimer,
  });
}

/// Singleton that lets a Flutter app start/stop an SSE MCP server.
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

  // SseServerManager? _sseManager; // Removed, managed per session now
  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _sub;

  final DistingCubit _distingCubit;

  bool get isRunning => _httpServer != null;
  Map<String, SessionResources> _activeSessions =
      {}; // To store per-session server and manager

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
    if (isRunning) {
      debugPrint('[MCP] Server already running.');
      return;
    }

    try {
      _activeSessions = {}; // Initialize/clear active sessions on start

      final address = bindAddress ?? InternetAddress.anyIPv4;
      _httpServer = await HttpServer.bind(address, port);

      _sub = _httpServer!.listen(
        (HttpRequest request) async {
          String? sessionIdFromQuery = request.uri.queryParameters['sessionId'];
          // Use the new SessionResources class for type safety
          SessionResources? sessionResources;

          if (request.uri.path == '/sse' && request.method == 'GET') {
            debugPrint('[MCP] Received GET /sse request.');
            McpServer newMcpServer = _buildServer();
            SseServerManager newSseManager = SseServerManager(newMcpServer);

            try {
              await newSseManager.handleRequest(request);
              debugPrint(
                  '[MCP] After newSseManager.handleRequest for GET /sse. Active transports in newSseManager: ${newSseManager.activeSseTransports.keys}');

              if (newSseManager.activeSseTransports.isNotEmpty) {
                final newSessionId =
                    newSseManager.activeSseTransports.keys.first;
                final transport =
                    newSseManager.activeSseTransports[newSessionId];
                debugPrint(
                    '[MCP] Attempting to map using presumed newSessionId: $newSessionId');

                if (transport != null) {
                  final currentSessionResources = SessionResources(
                    server: newMcpServer,
                    manager: newSseManager,
                    transport: transport,
                  );
                  _activeSessions[newSessionId] = currentSessionResources;
                  debugPrint(
                      '[MCP] New SSE session $newSessionId established and mapped with transport.');

                  // Store the original onclose from SseServerManager if any (it sets one)
                  final originalTransportOnClose = transport.onclose;

                  // Set our combined onclose handler
                  transport.onclose = () {
                    debugPrint(
                        '[MCP] SSE transport closed (onclose callback) for session $newSessionId. Cleaning up ping timer.');
                    currentSessionResources.pingTimer?.cancel();
                    originalTransportOnClose
                        ?.call(); // Call SseServerManager's original onclose handler
                  };
                  debugPrint(
                      '[MCP] Combined onclose handler (with ping timer cancellation) set for session $newSessionId.');

                  currentSessionResources.pingTimer =
                      Timer.periodic(const Duration(seconds: 15), (_) {
                    // We can't directly check if transport.isClosed without modifying SseServerTransport.
                    // We will try to send and catch errors if it's already closed.
                    try {
                      final randomString = DateTime.now()
                              .millisecondsSinceEpoch
                              .toRadixString(36) +
                          Random().nextInt(99999).toString();

                      // Ensure using JsonRpcNotification for server-initiated keep-alive
                      final keepAliveNotification = JsonRpcNotification(
                        method: 'ping', // Method is 'ping'
                        params: {
                          'random_string': randomString
                        }, // Params include random_string
                      );

                      // Use the transport directly associated with this session to send.
                      currentSessionResources.transport
                          ?.send(keepAliveNotification)
                          .catchError((e) {
                        debugPrint(
                            '[MCP] Error during transport.send() for keepalive (session $newSessionId): $e. Cancelling timer.');
                        currentSessionResources.pingTimer?.cancel();
                        return null;
                      });
                      debugPrint(
                          '[MCP] Sent keep-alive ping notification for session $newSessionId');
                    } catch (e, s) {
                      debugPrint(
                          '[MCP] Synchronous error attempting to send keepalive (session $newSessionId): $e. Cancelling timer. Stack: $s');
                      currentSessionResources.pingTimer?.cancel();
                    }
                  });
                  debugPrint(
                      '[MCP] Keep-alive timer started for session $newSessionId.');
                } else {
                  debugPrint(
                      '[MCP] WARNING: Could not get transport for session $newSessionId to set onclose handler or start ping timer.');
                }
              } else {
                debugPrint(
                    '[MCP] WARNING: newSseManager.activeSseTransports is EMPTY after GET /sse. Cannot map session.');
              }
            } catch (e, s) {
              debugPrint(
                  '[MCP] Error during new SSE connection processing (newSseManager.handleRequest or mapping): $e\n$s');
              // Attempt to close the response if an error occurs before/during mapping and response isn't sent
              _sendHttpError(request, HttpStatus.internalServerError,
                  'Error establishing SSE connection.');
            }
          } else if (request.uri.path == '/messages' &&
              request.method == 'POST') {
            debugPrint(
                '[MCP] Received POST /messages request with sessionIdFromQuery: $sessionIdFromQuery');
            if (sessionIdFromQuery != null &&
                _activeSessions.containsKey(sessionIdFromQuery)) {
              sessionResources = _activeSessions[sessionIdFromQuery]!;
              try {
                await sessionResources.manager.handleRequest(request);
                debugPrint(
                    '[MCP] POST /messages for session $sessionIdFromQuery processed by its manager.');
              } catch (e, s) {
                debugPrint(
                    '[MCP] Error in session manager for POST ${request.uri}: $e\n$s');
                _sendHttpError(request, HttpStatus.internalServerError,
                    'Error processing message.');
              }
            } else {
              debugPrint(
                  '[MCP] POST to /messages with unknown/missing sessionId: $sessionIdFromQuery. Active sessions: ${_activeSessions.keys}');
              _sendHttpError(request, HttpStatus.notFound,
                  'No active SSE session found for ID: $sessionIdFromQuery');
            }
          } else {
            debugPrint(
                '[MCP] Received unhandled request: ${request.method} ${request.uri.path}');
            _sendHttpError(request, HttpStatus.notFound,
                'Not Found or Method Not Allowed.');
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
            _activeSessions.clear();
            notifyListeners();
            debugPrint(
                '[MCP] Service effectively stopped due to HttpServer listener onDone.');
          }
        },
        cancelOnError: false,
      );

      debugPrint('[MCP] listening on http://${address.address}:$port');
      notifyListeners();
    } catch (e, s) {
      debugPrint('[MCP] Failed to start McpServerService: $e\n$s');
      await _sub?.cancel();
      _sub = null;
      await _httpServer?.close(force: true);
      _httpServer = null;
      _activeSessions.clear();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _sendHttpError(
      HttpRequest request, int statusCode, String message) async {
    // Check if headers are already sent or connection is not suitable for sending error body
    // Removed !request.response.headersSent check as it's not a direct property
    // and relying on the try-catch for cases where headers might be sent.
    try {
      // Check if the response is still open by seeing if a write is permissible.
      // This is a bit of a heuristic. A more robust check might involve a custom flag
      // set before any writes, but for now, this try-catch is the main guard.
      if (request.response.connectionInfo != null) {
        // A basic check if connection is still there
        request.response.statusCode = statusCode;
        request.response.write(message);
        await request.response.close();
      } else {
        debugPrint(
            '[MCP] _sendHttpError: Response already closed or no connection info.');
      }
    } catch (e) {
      debugPrint(
          '[MCP] Error sending HTTP error response (headers might have been sent): $e');
    }
  }

  /// Stop and dispose resources.
  Future<void> stop() async {
    if (!isRunning) {
      debugPrint(
          '[MCP] Stop called but server not running or already stopped.');
      return;
    }

    debugPrint('[MCP] Stopping server...');
    await _sub?.cancel();
    _sub = null;

    await _httpServer?.close(force: true);
    _httpServer = null;

    // Clean up active sessions
    debugPrint(
        '[MCP] Clearing ${_activeSessions.length} active sessions during stop.');
    for (var entry in _activeSessions.entries) {
      final sessionId = entry.key;
      final session = entry.value;
      try {
        // Attempt to close the transport if manager has it and transport has close
        final transport = session.manager.activeSseTransports[sessionId];
        await transport?.close();
        // If McpServer had a dispose method: session.server.dispose();
      } catch (e) {
        debugPrint(
            '[MCP] Error cleaning up transport for session $sessionId during stop: $e');
      }
    }
    _activeSessions.clear();

    notifyListeners();
    debugPrint('[MCP] Service stopped.');
  }

  /// Register additional tools **before** `start()`.
  /// This behavior needs to change slightly. Tools are now registered
  /// on each McpServer instance created by _buildServer().
  /// _pendingTools will be used by _buildServer().
  void addTool(
    String name, {
    required String description,
    required Map<String, dynamic> inputSchemaProperties,
    required ToolCallback callback,
  }) {
    _pendingTools.add(
      _ToolSpec(name, description, inputSchemaProperties, callback),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Internals
  // ──────────────────────────────────────────────────────────────────────────

  final List<_ToolSpec> _pendingTools = [];
  // Map<String, SessionResources> _activeSessions = {}; // Moved to be an instance variable

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit);
    final distingTools = DistingTools(distingControllerForTools);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.23.0'),
      options: ServerOptions(capabilities: ServerCapabilities()),
    );

    server.tool(
      'get_algorithm_details',
      description:
          'Retrieves full metadata for an algorithm by its GUID. Use `get_current_preset` for live parameter numbers for `set_parameter_value` / `get_parameter_value`.',
      inputSchemaProperties: {
        'guid': {
          'type': 'string',
          'description':
              'Algorithm GUID (from `list_algorithms` or `find_algorithms`).'
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
          'Lists available algorithms, optionally filtered by category or feature GUID. Returns only algorithm name and GUID. GUIDs are used with `add_algorithm` and `get_algorithm_details`.',
      inputSchemaProperties: {
        'category': {
          'type': 'string',
          'description': 'Filter by category (case-insensitive).'
        },
        'feature_guid': {
          'type': 'string',
          'description': 'Filter by included feature GUID.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await mcpAlgorithmTools.list_algorithms(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'find_algorithms',
      description:
          'Text search for algorithms. GUIDs found are used with `add_algorithm` and `get_algorithm_details`.',
      inputSchemaProperties: {
        'query': {'type': 'string', 'description': 'Search query text.'}
      },
      callback: ({args, extra}) async {
        final resultJson = await mcpAlgorithmTools.find_algorithms(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_current_routing_state',
      description:
          'Retrieves current routing state. Bus numbering: Inputs 1-12=Bus 1-12, Outputs 1-8=Bus 13-20, Aux 1-8=Bus 21-28, None=Bus 0.',
      inputSchemaProperties: {},
      callback: ({args, extra}) async {
        final resultJson =
            await mcpAlgorithmTools.get_current_routing_state(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_current_preset',
      description:
          'Gets entire current preset (name, slots, parameters). Parameter `parameter_number` from this tool is used as `parameter_number` for `set_parameter_value` and `get_parameter_value`.',
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
          'Adds an algorithm to the first available slot. Use GUID from `list_algorithms` or `find_algorithms`.',
      inputSchemaProperties: {
        'algorithm_guid': {
          'type': 'string',
          'description': 'GUID of the algorithm to add.'
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
      description:
          'Sets parameter to `value`. Either `parameter_number` or `parameter_name` MUST be provided (but not both). `parameter_number` MUST be from `get_current_preset`. If using `parameter_name`, ensure it is unique for the slot or an error will be returned. `value` must be between parameter\'s min/max.',
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

    server.tool(
      'ping',
      description:
          'Responds to a client\'s ping request to verify connection health, as per MCP specification. Returns an empty result.',
      inputSchemaProperties: {
        'random_string': {
          'type': 'string',
          'description':
              'A random string provided by the client, helps ensure request uniqueness if needed by client.'
        }
      },
      callback: ({args, extra}) async {
        // As per MCP spec, a ping response should have an empty result.
        // The mcp_dart library will construct the full JSON-RPC response.
        // We provide a JSON string representing an empty map for the "result" field.
        return CallToolResult(content: [TextContent(text: '{}')]);
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
    return server;
  }

  void _sendHttpErrorSync(HttpRequest request, int statusCode, String message) {
    // Synchronous error sending, use with caution and only if absolutely necessary
    // when an async version cannot be used (e.g. certain error handlers).
    debugPrint('[MCP] Sending HTTP error (sync): $statusCode - $message');
    try {
      request.response.statusCode = statusCode;
      request.response.headers.contentType = ContentType.text;
      request.response.write(message);
      request.response
          .close(); // This is synchronous if no async operations preceded it within this call
    } catch (e) {
      debugPrint('[MCP] Exception sending sync HTTP error: $e');
      // If an error occurs here, it's likely the connection is already broken.
    }
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
