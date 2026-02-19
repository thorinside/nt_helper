import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/debug_service.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';

/// Helper to bridge legacy Map-based JSON schemas to the typed JsonSchema system.
ToolInputSchema _inputSchema({
  required Map<String, dynamic> properties,
  List<String>? required,
}) {
  return ToolInputSchema.fromJson({
    'type': 'object',
    'properties': properties,
    'required': ?required,
  });
}

/// Generate a unique session ID with secure random number generator
String generateUUID() {
  // Try multiple approaches to get secure randomness
  late math.Random rng;

  try {
    // First try: Use Dart's secure random
    rng = math.Random.secure();
  } catch (e) {
    try {
      // Second try: Create entropy using crypto package and timestamp
      final timestamp = DateTime.now().microsecondsSinceEpoch.toString();
      final processId = DateTime.now().millisecondsSinceEpoch & 0xFFFF;
      final entropy = sha256.convert('$timestamp-$processId'.codeUnits).bytes;
      final seed = entropy.fold<int>(
        0,
        (prev, byte) => prev ^ (byte << (prev % 24)),
      );
      rng = math.Random(seed);
    } catch (e2) {
      try {
        // Third try: Simple timestamp seed
        final timestamp = DateTime.now().microsecondsSinceEpoch;
        final seed = timestamp ^ (timestamp >> 32);
        rng = math.Random(seed);
      } catch (e3) {
        // Final fallback: Regular random
        rng = math.Random();
      }
    }
  }

  // Create a custom UUID v4 with our secure RNG
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));

  // Set version (4) and variant bits according to RFC 4122
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant bits

  // Convert to UUID format
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// MCP server service using Streamable HTTP transport on /mcp.
/// Manages multiple MCP server instances, one per client session.
class McpServerService extends ChangeNotifier {
  McpServerService._(this._distingCubit);

  static McpServerService? _instance;

  static McpServerService get instance {
    if (_instance == null) {
      throw StateError(
        'McpServerService not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  static void initialize({required DistingCubit distingCubit}) {
    if (_instance != null) {
      return;
    }
    _instance = McpServerService._(distingCubit);
  }

  final DistingCubit _distingCubit;

  // Map of session ID to server instance for multi-client support
  final Map<String, McpServer> _servers = {};
  final Map<String, StreamableHTTPServerTransport> _transports = {};

  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _httpSubscription;
  String? _lastError;

  bool get isRunning => _httpServer != null;
  int? get boundPort => _httpServer?.port;
  InternetAddress? get boundAddress => _httpServer?.address;

  /// Returns the last error that occurred when trying to start the server
  String? get lastError => _lastError;

  /// Returns true if MCP is enabled but failed to start
  bool get hasError => _lastError != null;

  /// Get basic connection diagnostics
  Map<String, dynamic> get connectionDiagnostics {
    return {
      'server_running': isRunning,
      'active_servers': _servers.length,
      'active_transports': _transports.length,
      'server_implementation': 'nt-helper-flutter',
      'library_version': 'mcp_dart 1.2.2',
    };
  }

  Future<void> start({int port = 3847, InternetAddress? bindAddress}) async {
    if (isRunning) {
      _lastError = null;
      notifyListeners();
      return;
    }

    // Clear any previous error
    _lastError = null;

    try {
      // Bind to localhost by default to avoid exposing the MCP server on the LAN.
      // Use bindAddress: InternetAddress.anyIPv4 if you explicitly want to expose it.
      final address = bindAddress ?? InternetAddress.loopbackIPv4;

      // Create HTTP server
      _httpServer = await HttpServer.bind(address, port);

      // Handle HTTP requests
      _httpSubscription = _httpServer!.listen(
        (HttpRequest request) async {
          await _handleHttpRequest(request);
        },
        onError: (error, stackTrace) {},
        onDone: () {
          _cleanup();
        },
        cancelOnError: false,
      );

      DebugService().addLocalMessage(
        'MCP server started on port ${_httpServer!.port}',
      );
      notifyListeners();
    } catch (e) {
      // Capture error for display
      if (e is SocketException) {
        if (e.osError?.errorCode == 48 ||
            e.message.contains('Address already in use')) {
          _lastError = 'Port $port is already in use';
        } else {
          _lastError = e.message;
        }
      } else {
        _lastError = e.toString();
      }
      DebugService().addLocalMessage('MCP server error: $_lastError');
      await stop();
      notifyListeners();
    }
  }

  void _log(String message) {
    try {
      stderr.writeln('MCP_LOG: $message');
      final file = File('/tmp/nt_mcp.log');
      file.writeAsStringSync(
        '${DateTime.now()}: $message\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  Future<void> _handleHttpRequest(HttpRequest request) async {
    _log('Request: ${request.method} ${request.uri}');
    // Apply CORS headers to all responses
    _setCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      // Handle CORS preflight request
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    switch (request.uri.path) {
      case '/mcp':
        switch (request.method) {
          case 'POST':
            await _handlePostRequest(request);
          case 'GET':
            await _handleGetRequest(request);
          case 'DELETE':
            await _handleDeleteRequest(request);
          default:
            request.response.statusCode = HttpStatus.methodNotAllowed;
            request.response.headers.set(
              HttpHeaders.allowHeader,
              'GET, POST, DELETE, OPTIONS',
            );
            request.response.write('Method Not Allowed');
            await request.response.close();
        }
      default:
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.text;
        request.response.write('Not Found.');
        await request.response.close();
    }
  }

  void _setCorsHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set(
      'Access-Control-Allow-Methods',
      'GET, POST, DELETE, OPTIONS',
    );
    response.headers.set(
      'Access-Control-Allow-Headers',
      'Origin, X-Requested-With, Content-Type, Accept, mcp-session-id, Last-Event-ID, Authorization',
    );
    response.headers.set('Access-Control-Allow-Credentials', 'true');
    response.headers.set('Access-Control-Max-Age', '86400');
    response.headers.set('Access-Control-Expose-Headers', 'mcp-session-id');
  }

  /// Handle POST requests for JSON-RPC calls (Streamable HTTP).
  /// The transport validates Accept headers and handles the protocol per spec.
  Future<void> _handlePostRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    try {
      StreamableHTTPServerTransport? transport;

      if (sessionId != null && _transports.containsKey(sessionId)) {
        _log('POST /mcp: existing session $sessionId');
        transport = _transports[sessionId]!;
      } else {
        // Read the body to check if this is an init request or a stale session
        final bodyBytes = await request.fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
        final bodyString = utf8.decode(bodyBytes);
        final parsedBody = jsonDecode(bodyString);

        DebugService().addLocalMessage('MCP request: $bodyString');

        final isInit = _isInitializeBody(parsedBody);

        if (!isInit && sessionId != null) {
          // Stale session — auto-reinitialize with the same session ID so
          // clients that don't handle 404 keep working after hot reload.
          _log('POST /mcp: stale session $sessionId, auto-reinitializing');
          DebugService().addLocalMessage(
            'MCP auto-reinit for stale session $sessionId',
          );
          transport = await _createNewTransport(sessionId: sessionId);

          // Pump a synthetic init through the transport to flip _initialized.
          // We must wait for the response to complete (the server processes
          // the init asynchronously via send()).
          final initBody = jsonDecode(
            jsonEncode({
              'jsonrpc': '2.0',
              'id': '_reinit',
              'method': 'initialize',
              'params': {
                'protocolVersion': '2025-03-26',
                'capabilities': {},
                'clientInfo': {'name': 'auto-reinit', 'version': '0.0.0'},
              },
            }),
          );
          final syntheticRequest = _SyntheticHttpRequest(sessionId: null);
          await transport.handleRequest(syntheticRequest, initBody);
          // Wait for the transport to finish writing the init response
          await syntheticRequest.response.done;

          _log(
            'POST /mcp: transport re-initialized, session: ${transport.sessionId}',
          );
          _log('POST /mcp: delegating real request to transport');
          await transport.handleRequest(request, parsedBody);
          _log('POST /mcp: handleRequest completed');
          return;
        }

        _log('POST /mcp: creating new transport (sessionId: $sessionId)');
        transport = await _createNewTransport(sessionId: sessionId);
        _log('POST /mcp: transport created, session: ${transport.sessionId}');

        _log('POST /mcp: delegating to transport.handleRequest');
        await transport.handleRequest(request, parsedBody);
        _log('POST /mcp: handleRequest completed');
        return;
      }

      // Existing session — read body, log, and delegate
      final bodyBytes = await request.fold<List<int>>(
        <int>[],
        (previous, element) => previous..addAll(element),
      );
      final bodyString = utf8.decode(bodyBytes);
      final parsedBody = jsonDecode(bodyString);

      _log('POST /mcp: delegating to transport.handleRequest');
      DebugService().addLocalMessage('MCP request: $bodyString');

      await transport.handleRequest(request, parsedBody);
      _log('POST /mcp: handleRequest completed');
    } catch (e) {
      DebugService().addLocalMessage('MCP error: ${e.toString()}');
      _sendErrorResponse(
        request,
        HttpStatus.internalServerError,
        'Internal server error: ${e.toString()}',
      );
    }
  }

  /// Check if a parsed JSON body contains an initialize request
  bool _isInitializeBody(dynamic parsedBody) {
    if (parsedBody is Map<String, dynamic>) {
      return parsedBody['method'] == 'initialize';
    }
    if (parsedBody is List) {
      return parsedBody.any(
        (msg) => msg is Map<String, dynamic> && msg['method'] == 'initialize',
      );
    }
    return false;
  }

  /// Handle GET requests on /mcp.
  /// Returns 405 — this server does not use server-initiated notifications,
  /// so no SSE stream is needed. Per spec, server MUST return text/event-stream
  /// OR 405; we choose 405 to avoid long-lived SSE connections that cause
  /// HTTP/1.1 head-of-line blocking in clients that reuse TCP connections.
  Future<void> _handleGetRequest(HttpRequest request) async {
    _log('GET /mcp → 405 (SSE streams not supported)');
    request.response.statusCode = HttpStatus.methodNotAllowed;
    request.response.headers.set(
      HttpHeaders.allowHeader,
      'POST, DELETE, OPTIONS',
    );
    request.response.write('Method Not Allowed');
    await request.response.close();
  }

  /// Handle DELETE requests for session termination
  Future<void> _handleDeleteRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null) {
      _sendErrorResponse(
        request,
        HttpStatus.badRequest,
        'Missing session ID for termination',
      );
      return;
    }

    try {
      if (_transports.containsKey(sessionId)) {
        final transport = _transports[sessionId]!;
        await transport.handleRequest(request);
      } else {
        // Session doesn't exist - just return OK since it's already "terminated"
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'status': 'ok', 'message': 'Session already terminated'}),
        );
        await request.response.close();
      }
    } catch (e) {
      _sendErrorResponse(
        request,
        HttpStatus.internalServerError,
        'Error processing session termination',
      );
    }
  }

  /// Helper to send JSON error responses
  void _sendErrorResponse(HttpRequest request, int statusCode, String message) {
    try {
      // Check if headers are already sent
      bool headersSent = false;
      try {
        headersSent = request.response.headers.contentType
            .toString()
            .startsWith('text/event-stream');
      } catch (_) {
        // Ignore errors when checking headers
      }

      if (!headersSent) {
        request.response.statusCode = statusCode;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'jsonrpc': '2.0',
            'error': {'code': -32000, 'message': message},
            'id': null,
          }),
        );
        request.response.close();
      }
    } catch (_) {
      // Ignore errors when sending error response
    }
  }

  Future<void> stop() async {
    if (!isRunning && _lastError == null) {
      return;
    }

    await _httpSubscription?.cancel();
    _httpSubscription = null;

    await _httpServer?.close(force: true);
    _httpServer = null;

    // Close all Streamable HTTP transports and servers
    for (final transport in _transports.values) {
      transport.close();
    }
    _transports.clear();
    _servers.clear();

    // Clear error when explicitly stopped
    _lastError = null;

    DebugService().addLocalMessage('MCP server stopped');
    notifyListeners();
  }

  Future<void> restart({int port = 3847, InternetAddress? bindAddress}) async {
    await stop();
    await Future.delayed(const Duration(milliseconds: 500));
    await start(port: port, bindAddress: bindAddress);
  }

  void _cleanup() {
    _httpSubscription = null;
    _httpServer = null;
    _transports.clear();
    _servers.clear();
    notifyListeners();
  }

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(
      distingControllerForTools,
      _distingCubit,
    );
    final distingTools = DistingTools(distingControllerForTools, _distingCubit);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.39.0'),
      options: McpServerOptions(
        capabilities: ServerCapabilities(tools: ServerCapabilitiesTools()),
      ),
    );

    // Register MCP tools — split into individual, well-named tools
    _registerSearchTools(server, mcpAlgorithmTools, distingTools);
    _registerShowTools(server, mcpAlgorithmTools);
    _registerEditTools(server, distingTools);
    _registerPresetTools(server, distingTools);

    // Register and immediately disable a dummy resource to initialize the
    // resources/list handler. Without this, clients that call resources/list
    // get a "method not found" error that the transport never writes back
    // (mcp_dart bug with enableJsonResponse + error responses).
    server
        .registerResource(
          '_init',
          'nt://init',
          null,
          (uri, extra) => ReadResourceResult(contents: []),
        )
        .disable();

    return server;
  }

  void _registerSearchTools(
    McpServer server,
    MCPAlgorithmTools algoTools,
    DistingTools distingTools,
  ) {
    server.registerTool(
      'search_algorithms',
      description:
          'Search for algorithms by name/category. Uses fuzzy matching (70% threshold). Returns up to 10 results sorted by relevance.',
      inputSchema: _inputSchema(
        properties: {
          'query': {
            'type': 'string',
            'description':
                'Search query: algorithm name, partial name, or category.',
          },
        },
        required: ['query'],
      ),
      callback: (args, extra) async {
        try {
          // searchAlgorithms expects target=algorithm in the args
          final fullArgs = {...args, 'target': 'algorithm'};
          final resultJson = await algoTools
              .searchAlgorithms(fullArgs)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 5 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'search_parameters',
      description:
          'Search for parameters by name within the current preset or a specific slot. Uses exact or partial name matching.',
      inputSchema: _inputSchema(
        properties: {
          'query': {
            'type': 'string',
            'description': 'Parameter name to search for (case-insensitive).',
          },
          'scope': {
            'type': 'string',
            'description':
                'Search scope: "preset" (all slots) or "slot" (specific slot).',
            'enum': ['preset', 'slot'],
          },
          'slot_index': {
            'type': 'integer',
            'description': 'Slot index (0-31). Required when scope is "slot".',
          },
          'partial_match': {
            'type': 'boolean',
            'description':
                'If true, find parameters containing the query. Default: false (exact match).',
          },
        },
        required: ['query', 'scope'],
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await distingTools
              .searchParameters(args)
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 5 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );
  }

  void _registerShowTools(McpServer server, MCPAlgorithmTools tools) {
    server.registerTool(
      'show_preset',
      description:
          'Show the complete preset with all slots, parameters, and enabled mappings.',
      inputSchema: _inputSchema(properties: {}),
      callback: (args, extra) async {
        try {
          final resultJson = await tools.showPreset().timeout(
            const Duration(seconds: 10),
            onTimeout: () => jsonEncode({
              'success': false,
              'error': 'Tool execution timed out after 10 seconds',
            }),
          );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'show_slot',
      description:
          'Show a single slot with its algorithm, parameters, and enabled mappings.',
      inputSchema: _inputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Slot index (0-31).',
          },
        },
        required: ['slot_index'],
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .showSlot(args['slot_index'])
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 10 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'show_parameter',
      description:
          'Show a single parameter with its value, range, unit, and enabled mappings.',
      inputSchema: _inputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Slot index (0-31).',
          },
          'parameter': {
            'type': 'integer',
            'description': 'Parameter number (0-based index).',
          },
        },
        required: ['slot_index', 'parameter'],
      ),
      callback: (args, extra) async {
        try {
          final slotIndex = args['slot_index'] as int;
          final parameter = args['parameter'] as int;
          final resultJson = await tools
              .showParameterByIndex(slotIndex, parameter)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 10 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'show_screen',
      description:
          'Capture and return the current device screen as a base64 JPEG image.',
      inputSchema: _inputSchema(
        properties: {
          'display_mode': {
            'type': 'string',
            'description':
                'Optional display mode to switch to before capturing. Options: "parameter" (hardware parameter list), "algorithm" (custom algorithm interface), "overview" (all slots overview), "vu_meters" (VU meter display)',
            'enum': ['parameter', 'algorithm', 'overview', 'vu_meters'],
          },
        },
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .showScreen(displayMode: args['display_mode'])
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 10 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'show_routing',
      description:
          'Show the current signal routing state with input/output bus assignments for all slots.',
      inputSchema: _inputSchema(properties: {}),
      callback: (args, extra) async {
        try {
          final resultJson = await tools.showRouting().timeout(
            const Duration(seconds: 10),
            onTimeout: () => jsonEncode({
              'success': false,
              'error': 'Tool execution timed out after 10 seconds',
            }),
          );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'show_cpu',
      description:
          'Show CPU usage for the device and per-slot usage breakdown.',
      inputSchema: _inputSchema(properties: {}),
      callback: (args, extra) async {
        try {
          final resultJson = await tools.showCpu().timeout(
            const Duration(seconds: 10),
            onTimeout: () => jsonEncode({
              'success': false,
              'error': 'Tool execution timed out after 10 seconds',
            }),
          );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );
  }

  void _registerEditTools(McpServer server, DistingTools tools) {
    server.registerTool(
      'edit_preset',
      description:
          'Edit the entire preset state including name and all slots. WARNING: Replaces the full preset.',
      inputSchema: _inputSchema(
        properties: {
          'data': {
            'type': 'object',
            'description': 'Full preset data with name and slots array.',
            'properties': {
              'name': {'type': 'string', 'description': 'Preset name'},
              'slots': {
                'type': 'array',
                'description':
                    'Array of slot objects with algorithm and parameters',
              },
            },
          },
        },
        required: ['data'],
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .editPreset({...args, 'target': 'preset'})
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 30 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'edit_slot',
      description:
          'Edit a specific slot: change algorithm, set parameters, or rename. Device must be in connected mode.',
      inputSchema: _inputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Slot index (0-31).',
          },
          'data': {
            'type': 'object',
            'description':
                'Slot data with optional algorithm, parameters, and name.',
            'properties': {
              'algorithm': {
                'type': 'object',
                'description':
                    'Algorithm specification (guid or name, plus optional specifications)',
                'properties': {
                  'guid': {'type': 'string', 'description': 'Algorithm GUID'},
                  'name': {
                    'type': 'string',
                    'description': 'Algorithm name (fuzzy matching)',
                  },
                  'specifications': {
                    'type': 'array',
                    'description': 'Algorithm-specific specification values',
                    'items': {'type': 'integer'},
                  },
                },
              },
              'name': {'type': 'string', 'description': 'Custom slot name'},
              'parameters': {
                'type': 'array',
                'description':
                    'Array of parameter objects with values and/or mappings',
                'items': {
                  'type': 'object',
                  'properties': {
                    'parameter_number': {
                      'type': 'integer',
                      'description': 'Parameter index',
                    },
                    'value': {
                      'type': 'number',
                      'description': 'Parameter value',
                    },
                    'mapping': {
                      'type': 'object',
                      'description':
                          'Mapping with CV, MIDI, i2c, and performance page fields',
                    },
                  },
                },
              },
            },
          },
        },
        required: ['slot_index', 'data'],
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .editSlot({...args, 'target': 'slot'})
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 30 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'edit_parameter',
      description:
          'Edit a single parameter value and/or mapping. Device must be in connected mode.',
      inputSchema: _inputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Slot index (0-31).',
          },
          'parameter': {
            'description':
                'Parameter identifier: integer number (0-based) or string name.',
            'oneOf': [
              {'type': 'string'},
              {'type': 'integer'},
            ],
          },
          'value': {
            'type': 'number',
            'description':
                'Parameter value in display scale (same as returned by show tools). Automatically converted to raw hardware value. If omitted, mapping must be provided.',
          },
          'mapping': {
            'type': 'object',
            'description':
                'Parameter mapping with CV, MIDI, i2c, and performance page controls. Supports partial updates.',
            'properties': {
              'cv': {
                'type': 'object',
                'description':
                    'CV mapping: source, cv_input (0-12), is_unipolar, is_gate, volts, delta',
              },
              'midi': {
                'type': 'object',
                'description':
                    'MIDI mapping: is_midi_enabled, midi_channel (0-15), midi_cc (0-128), midi_type, is_midi_symmetric, is_midi_relative, midi_min, midi_max',
              },
              'i2c': {
                'type': 'object',
                'description':
                    'i2c mapping: is_i2c_enabled, i2c_cc (0-255), is_i2c_symmetric, i2c_min, i2c_max',
              },
              'performance_page': {
                'type': 'integer',
                'description':
                    'Performance page index (0=not assigned, 1-15=page number)',
              },
            },
          },
        },
        required: ['slot_index', 'parameter'],
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .editParameter(args)
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 15 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );
  }

  void _registerPresetTools(McpServer server, DistingTools tools) {
    server.registerTool(
      'new',
      description:
          'Create new blank preset or preset with initial algorithms. WARNING: Clears current preset.',
      inputSchema: _inputSchema(
        properties: {
          'name': {'type': 'string', 'description': 'Name for the new preset.'},
          'algorithms': {
            'type': 'array',
            'description':
                'Algorithms to add. Each: {name: string} or {guid: string}. Added to slots 0, 1, 2, etc.',
            'items': {
              'type': 'object',
              'properties': {
                'guid': {
                  'type': 'string',
                  'description': 'Algorithm GUID (alternative to name)',
                },
                'name': {
                  'type': 'string',
                  'description': 'Algorithm name (fuzzy matching)',
                },
                'specifications': {
                  'type': 'array',
                  'description': 'Algorithm-specific specification values',
                  'items': {'type': 'integer'},
                },
              },
            },
          },
        },
        required: ['name'],
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .newWithAlgorithms(args)
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 30 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'save',
      description: 'Save the current preset to the device.',
      inputSchema: _inputSchema(properties: {}),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .savePreset(args)
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 10 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    // Simple 'add' tool with flat parameter structure for reduced cognitive load
    server.registerTool(
      'add',
      description: 'Add an algorithm to the preset. Requires name or guid.',
      inputSchema: _inputSchema(
        properties: {
          'target': {
            'type': 'string',
            'enum': ['algorithm'],
            'description': 'Must be "algorithm".',
          },
          'name': {
            'type': 'string',
            'description':
                'Algorithm name (fuzzy matching). Required if no guid.',
          },
          'guid': {
            'type': 'string',
            'description': 'Algorithm GUID. Required if no name.',
          },
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Insert position (0-31). Omit for first empty slot.',
          },
          'specifications': {
            'type': 'array',
            'items': {'type': 'integer'},
            'description':
                'Specification values for algorithms that require them (e.g., channel count, max delay time).',
          },
        },
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .addSimple({...args, 'target': 'algorithm'})
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 30 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );

    server.registerTool(
      'remove',
      description:
          'Remove the algorithm from a slot, leaving it empty. Succeeds gracefully if slot is already empty.',
      inputSchema: _inputSchema(
        properties: {
          'target': {
            'type': 'string',
            'enum': ['slot'],
            'description': 'Must be "slot".',
          },
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Slot index to clear (0-31).',
          },
        },
        required: ['slot_index'],
      ),
      callback: (args, extra) async {
        try {
          final resultJson = await tools
              .removeSlot({...args, 'target': 'slot'})
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 10 seconds',
                }),
              );
          return CallToolResult.fromContent([TextContent(text: resultJson)]);
        } catch (e) {
          return CallToolResult.fromContent([
            TextContent(
              text: jsonEncode({
                'success': false,
                'error': 'Tool execution failed: ${e.toString()}',
              }),
            ),
          ]);
        }
      },
    );
  }

  /// Create a new transport and connect server following example pattern
  Future<StreamableHTTPServerTransport> _createNewTransport({
    String? sessionId,
  }) async {
    StreamableHTTPServerTransport? transport;
    McpServer? server;

    // Create new server instance first
    server = _buildServer();

    // Create new transport with event store for resumability.
    // enableJsonResponse: POST responses use application/json instead of SSE
    // streams, which is more compatible with clients that don't handle SSE on POST.
    transport = StreamableHTTPServerTransport(
      options: StreamableHTTPServerTransportOptions(
        enableJsonResponse: true,
        sessionIdGenerator: sessionId != null
            ? () => sessionId
            : () => generateUUID(),
        eventStore: InMemoryEventStore(),
        onsessioninitialized: (initializedSessionId) {
          // Store both transport and server by session ID when session is initialized
          _transports[initializedSessionId] = transport!;
          _servers[initializedSessionId] = server!;
          DebugService().addLocalMessage(
            'MCP client connected (session: $initializedSessionId)',
          );
        },
      ),
    );

    // Set up transport close handler with session cleanup
    transport.onclose = () {
      final sessionId = transport!.sessionId;
      if (sessionId != null && _transports.containsKey(sessionId)) {
        _cleanupSession(sessionId);
      }
    };

    // Wrap transport to log outgoing responses
    final loggingTransport = _LoggingTransport(transport);

    // Connect server to the logging wrapper so send() calls are intercepted
    await server.connect(loggingTransport);

    // Forward onmessage from the real transport to the logging wrapper
    // so handleRequest triggers the server's handler
    transport.onmessage = loggingTransport.onmessage;

    return transport;
  }

  /// Clean up a specific session
  void _cleanupSession(String sessionId) {
    DebugService().addLocalMessage(
      'MCP client disconnected (session: $sessionId)',
    );
    _transports[sessionId]?.close();
    _transports.remove(sessionId);
    _servers.remove(sessionId);
  }
}

/// Transport wrapper that logs outgoing JSON-RPC responses via [DebugService].
/// The [McpServer] is connected to this wrapper so all [send] calls pass
/// through here before being forwarded to the real transport.
class _LoggingTransport implements Transport {
  _LoggingTransport(this._inner);

  final StreamableHTTPServerTransport _inner;

  @override
  Future<void> send(JsonRpcMessage message, {dynamic relatedRequestId}) async {
    DebugService().addLocalMessage(
      'MCP response: ${jsonEncode(message.toJson())}',
    );
    return _inner.send(message, relatedRequestId: relatedRequestId);
  }

  @override
  Future<void> start() => _inner.start();

  @override
  Future<void> close() => _inner.close();

  @override
  String? get sessionId => _inner.sessionId;

  set sessionId(String? value) => _inner.sessionId = value;

  @override
  void Function()? get onclose => _inner.onclose;

  @override
  set onclose(void Function()? value) => _inner.onclose = value;

  @override
  void Function(Error error)? get onerror => _inner.onerror;

  @override
  set onerror(void Function(Error error)? value) => _inner.onerror = value;

  @override
  void Function(JsonRpcMessage message)? get onmessage => _inner.onmessage;

  @override
  set onmessage(void Function(JsonRpcMessage message)? value) =>
      _inner.onmessage = value;
}

/// Minimal fake [HttpRequest] used to pump a synthetic init through a
/// [StreamableHTTPServerTransport] so it transitions to the initialized state.
/// Only the members actually touched by the transport are implemented.
class _SyntheticHttpRequest extends Stream<Uint8List> implements HttpRequest {
  _SyntheticHttpRequest({this.sessionId});

  final String? sessionId;

  @override
  final String method = 'POST';

  @override
  late final HttpHeaders headers = _SyntheticHeaders(sessionId: sessionId);

  @override
  late final HttpResponse response = _SyntheticHttpResponse();

  @override
  Uri get uri => Uri.parse('/mcp');

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return const Stream<Uint8List>.empty().listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  // -- Unused members required by HttpRequest --
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not implemented on _SyntheticHttpRequest',
  );
}

class _SyntheticHeaders implements HttpHeaders {
  _SyntheticHeaders({this.sessionId});
  final String? sessionId;

  @override
  ContentType? get contentType => ContentType.json;

  @override
  String? value(String name) {
    switch (name.toLowerCase()) {
      case 'accept':
        return 'application/json, text/event-stream';
      case 'content-type':
        return 'application/json';
      case 'mcp-session-id':
        return sessionId;
      default:
        return null;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not implemented on _SyntheticHeaders',
  );
}

class _SyntheticHttpResponse implements HttpResponse {
  final Completer<void> _doneCompleter = Completer<void>();

  @override
  Future get done => _doneCompleter.future;

  @override
  int statusCode = HttpStatus.ok;

  @override
  set bufferOutput(bool value) {}

  @override
  bool get bufferOutput => false;

  @override
  HttpHeaders get headers => _SyntheticResponseHeaders();

  @override
  void write(Object? object) {}

  @override
  Future close() async {
    if (!_doneCompleter.isCompleted) _doneCompleter.complete();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not implemented on _SyntheticHttpResponse',
  );
}

class _SyntheticResponseHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    '${invocation.memberName} not implemented on _SyntheticResponseHeaders',
  );
}

/// Enhanced in-memory event store for MCP message persistence
class InMemoryEventStore implements EventStore {
  final Map<
    String,
    List<({EventId id, JsonRpcMessage message, DateTime timestamp})>
  >
  _events = {};
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
    events.removeWhere(
      (event) => now.difference(event.timestamp) > maxEventAge,
    );

    if (events.length > maxEventsPerStream) {
      events.removeRange(0, events.length - maxEventsPerStream);
    }
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
