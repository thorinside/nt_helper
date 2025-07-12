import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';
import 'package:uuid/uuid.dart';

/// Generate a unique session ID
String generateUUID() => const Uuid().v4();

/// Simplified MCP server service using StreamableHTTPServerTransport
/// for automatic session management, connection persistence, and health monitoring.
/// This service manages multiple MCP server instances, one per client connection.
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
  
  // Map of session ID to server instance for multi-client support
  final Map<String, McpServer> _servers = {};
  final Map<String, StreamableHTTPServerTransport> _transports = {};
  HttpServer? _httpServer;
  StreamSubscription<HttpRequest>? _httpSubscription;
  

  bool get isRunning => _httpServer != null;

  /// Get basic connection diagnostics
  Map<String, dynamic> get connectionDiagnostics {
    return {
      'server_running': isRunning,
      'active_servers': _servers.length,
      'active_transports': _transports.length,
      'server_implementation': 'nt-helper-flutter',
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
    // Apply CORS headers to all responses
    _setCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      // Handle CORS preflight request
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    if (request.uri.path != '/mcp') {
      request.response.statusCode = HttpStatus.notFound;
      request.response.headers.contentType = ContentType.text;
      request.response.write('Not Found. Use /mcp endpoint.');
      await request.response.close();
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
        request.response.statusCode = HttpStatus.methodNotAllowed;
        request.response.headers.set(HttpHeaders.allowHeader, 'GET, POST, DELETE, OPTIONS');
        request.response.write('Method Not Allowed');
        await request.response.close();
    }
  }

  void _setCorsHeaders(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 
        'Origin, X-Requested-With, Content-Type, Accept, mcp-session-id, Last-Event-ID, Authorization');
    response.headers.set('Access-Control-Allow-Credentials', 'true');
    response.headers.set('Access-Control-Max-Age', '86400');
    response.headers.set('Access-Control-Expose-Headers', 'mcp-session-id');
  }

  /// Check if request is an initialization request
  bool _isInitializeRequest(dynamic body) {
    if (body is Map<String, dynamic> &&
        body.containsKey('method') &&
        body['method'] == 'initialize') {
      return true;
    }
    return false;
  }

  /// Handle POST requests for JSON-RPC calls
  Future<void> _handlePostRequest(HttpRequest request) async {
    debugPrint('[MCP] Received POST request');

    try {
      // Parse the request body
      final bodyBytes = await _collectBytes(request);
      final bodyString = utf8.decode(bodyBytes);
      final body = jsonDecode(bodyString);

      // Check for existing session ID
      final sessionId = request.headers.value('mcp-session-id');
      StreamableHTTPServerTransport? transport;

      if (sessionId != null && _transports.containsKey(sessionId)) {
        // Reuse existing transport
        transport = _transports[sessionId]!;
      } else if (sessionId == null && _isInitializeRequest(body)) {
        // New initialization request - create transport and server
        transport = await _createNewTransport();
        
        // Ensure session is fully initialized before proceeding
        await Future.delayed(const Duration(milliseconds: 1));
        
        debugPrint('[MCP] Handling initialization request for new session');
        await transport.handleRequest(request, body);
        return; // Already handled
      } else {
        // Invalid request - no session ID or not initialization request
        _sendErrorResponse(request, HttpStatus.badRequest,
            'Bad Request: No valid session ID provided');
        return;
      }

      // Handle the request with existing transport
      await transport.handleRequest(request, body);
    } catch (e, s) {
      debugPrint('[MCP] Error handling POST request: $e\n$s');
      _sendErrorResponse(request, HttpStatus.internalServerError, 'Internal server error');
    }
  }

  /// Handle GET requests for SSE streams
  Future<void> _handleGetRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null || !_transports.containsKey(sessionId)) {
      _sendErrorResponse(request, HttpStatus.badRequest, 'Invalid or missing session ID');
      return;
    }

    // Check for Last-Event-ID header for resumability
    final lastEventId = request.headers.value('Last-Event-ID');
    if (lastEventId != null) {
      debugPrint('[MCP] Client reconnecting with Last-Event-ID: $lastEventId');
    } else {
      debugPrint('[MCP] Establishing new SSE stream for session $sessionId');
    }

    final transport = _transports[sessionId]!;
    await transport.handleRequest(request);
  }

  /// Handle DELETE requests for session termination
  Future<void> _handleDeleteRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null || !_transports.containsKey(sessionId)) {
      _sendErrorResponse(request, HttpStatus.badRequest, 'Invalid or missing session ID');
      return;
    }

    debugPrint('[MCP] Received session termination request for session $sessionId');

    try {
      final transport = _transports[sessionId]!;
      await transport.handleRequest(request);
    } catch (e, s) {
      debugPrint('[MCP] Error handling DELETE request: $e\n$s');
      _sendErrorResponse(request, HttpStatus.internalServerError, 'Error processing session termination');
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
        request.response.write(jsonEncode({
          'jsonrpc': '2.0',
          'error': {'code': -32000, 'message': message},
          'id': null,
        }));
        request.response.close();
      }
    } catch (_) {
      // Ignore errors when sending error response
    }
  }

  /// Helper to collect bytes from HTTP request
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

    // Close all transports and servers
    for (final transport in _transports.values) {
      transport.close();
    }
    _transports.clear();
    _servers.clear();

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
    _transports.clear();
    _servers.clear();
    notifyListeners();
  }

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit);
    final distingTools = DistingTools(distingControllerForTools);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.39.0'),
      options: ServerOptions(
        capabilities: ServerCapabilities(
          resources: ServerCapabilitiesResources(),
          tools: ServerCapabilitiesTools(),
          prompts: ServerCapabilitiesPrompts(),
        ),
      ),
    );

    // Register MCP tools - preserving existing tool definitions
    _registerAlgorithmTools(server, mcpAlgorithmTools);
    _registerDistingTools(server, distingTools);
    _registerDiagnosticTools(server);
    
    // Register MCP resources and prompts
    _registerDocumentationResources(server);
    _registerHelpfulPrompts(server);

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
      inputSchemaProperties: {},
      callback: ({args, extra}) async {
        final diagnostics = {
          'server_info': connectionDiagnostics,
          'transport_info': {
            'active_transports': _transports.length,
            'sessions': _transports.keys.toList(),
            'transport_type': 'StreamableHTTPServerTransport',
          },
        };
        
        debugPrint('[MCP] Diagnostics requested - Server running: $isRunning');
        return CallToolResult.fromContent(content: [TextContent(text: jsonEncode(diagnostics))]);
      },
    );
  }

  /// Helper method to create resource callback that loads assets directly
  ReadResourceCallback _createResourceCallback(String assetPath, String resourceName) {
    return (uri, extra) async {
      final stopwatch = Stopwatch()..start();
      try {
        debugPrint('[MCP] 🔄 Starting load for resource: $resourceName at ${DateTime.now()}');
        
        // Add timeout protection to debug if the issue is in our callback
        final content = await rootBundle.loadString('assets/mcp_docs/$assetPath')
            .timeout(const Duration(seconds: 5), onTimeout: () {
          debugPrint('[MCP] ⏰ TIMEOUT in asset loading for $resourceName after ${stopwatch.elapsedMilliseconds}ms');
          throw TimeoutException('Asset loading timeout', const Duration(seconds: 5));
        });
        
        stopwatch.stop();
        debugPrint('[MCP] ✅ Successfully loaded resource: $resourceName (${content.length} chars) in ${stopwatch.elapsedMilliseconds}ms');
        
        return ReadResourceResult(
          contents: [
            ResourceContents.fromJson({
              'uri': uri.toString(),
              'text': content,
              'mimeType': 'text/markdown'
            })
          ]
        );
      } catch (e) {
        stopwatch.stop();
        debugPrint('[MCP] ❌ Error serving resource $resourceName after ${stopwatch.elapsedMilliseconds}ms: $e');
        return ReadResourceResult(
          contents: [
            ResourceContents.fromJson({
              'uri': uri.toString(),
              'text': 'Documentation not available - Error: $e',
              'mimeType': 'text/markdown'
            })
          ]
        );
      }
    };
  }

  void _registerDocumentationResources(McpServer server) {
    debugPrint('[MCP] 🔄 Starting resource registration...');
    
    // DEBUGGING: Test hypothesis - register only one resource at first
    // Bus mapping documentation (this one works)
    debugPrint('[MCP] Registering bus-mapping...');
    server.resource(
      'bus-mapping',
      'bus-mapping',
      _createResourceCallback('bus_mapping.md', 'bus-mapping'),
      metadata: (mimeType: 'text/markdown', description: 'IO to Bus conversion rules and routing concepts')
    );
    debugPrint('[MCP] ✅ Registered bus-mapping');

    // DEBUGGING: Test problematic resources one by one with different patterns
    // Try MCP usage guide with simple name/URI pattern like bus-mapping
    debugPrint('[MCP] Registering mcp-usage-guide...');
    server.resource(
      'mcp-usage-guide',
      'mcp-usage-guide',
      _createResourceCallback('mcp_usage_guide.md', 'mcp-usage-guide'),
      metadata: (mimeType: 'text/markdown', description: 'Essential tools and workflows for MCP clients')
    );
    debugPrint('[MCP] ✅ Registered mcp-usage-guide');

    // Comment out others temporarily to test one problematic resource at a time
    /*
    // Algorithm categories
    server.resource(
      'algorithm-categories', 
      'algorithm-categories',
      _createResourceCallback('algorithm_categories.md', 'algorithm-categories'),
      metadata: (mimeType: 'text/markdown', description: 'Complete list of algorithm categories and descriptions')
    );

    // Preset format documentation
    server.resource(
      'preset-format',
      'preset-format',
      _createResourceCallback('preset_format.md', 'preset-format'),
      metadata: (mimeType: 'text/markdown', description: 'JSON schema and examples for preset data')
    );

    // Routing concepts
    server.resource(
      'routing-concepts',
      'routing-concepts',
      _createResourceCallback('routing_concepts.md', 'routing-concepts'),
      metadata: (mimeType: 'text/markdown', description: 'Signal flow and routing fundamentals')
    );
    */
    
    debugPrint('[MCP] 🔄 Resource registration complete');
  }

  void _registerHelpfulPrompts(McpServer server) {
    // Preset builder prompt - guides through building a preset step by step
    server.prompt(
      'preset-builder',
      description: 'Guides you through building a custom preset step by step',
      argsSchema: {
        'use_case': PromptArgumentDefinition(
          description: 'Describe what you want the preset to do (e.g., "audio delay with modulation", "CV sequencer setup")',
          required: true,
        ),
        'skill_level': PromptArgumentDefinition(
          description: 'Your experience level: "beginner", "intermediate", or "advanced"',
          required: false,
        ),
      },
      callback: (args, extra) async {
        final useCase = args!['use_case'] as String;
        final skillLevel = args['skill_level'] as String? ?? 'intermediate';
        
        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text: '''I want to build a Disting NT preset for: "$useCase"

My skill level is: $skillLevel

Please help me build this preset step by step. Start by:
1. Understanding the current state with get_current_preset
2. Suggesting appropriate algorithms from the right categories
3. Setting up the signal routing properly
4. Configuring parameters for the desired sound/behavior

Use the MCP tools available to inspect the current state and build the preset interactively. Explain each step clearly and ask for feedback before proceeding to the next step.'''
              )
            )
          ]
        );
      }
    );

    // Algorithm recommender prompt
    server.prompt(
      'algorithm-recommender',
      description: 'Recommends algorithms based on musical/technical requirements',
      argsSchema: {
        'requirement': PromptArgumentDefinition(
          description: 'What you need the algorithm to do (e.g., "filter bass frequencies", "generate random CV", "create stereo delay")',
          required: true,
        ),
        'context': PromptArgumentDefinition(
          description: 'Additional context about your setup or constraints',
          required: false,
        ),
      },
      callback: (args, extra) async {
        final requirement = args!['requirement'] as String;
        final context = args['context'] as String? ?? '';
        
        final contextText = context.isNotEmpty ? '\nAdditional context: $context' : '';
        
        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text: '''I need an algorithm that can: "$requirement"$contextText

Please help me find the best algorithm(s) for this by:
1. Searching through appropriate categories using list_algorithms
2. Getting detailed information about promising candidates with get_algorithm_details
3. Explaining the pros and cons of each option
4. Recommending the best choice with reasoning
5. Suggesting how to integrate it into a preset effectively

Focus on practical recommendations that will work well for my specific use case.'''
              )
            )
          ]
        );
      }
    );

    // Routing analyzer prompt
    server.prompt(
      'routing-analyzer',
      description: 'Analyzes and explains current routing configuration',
      argsSchema: {
        'focus': PromptArgumentDefinition(
          description: 'What to focus on: "signal_flow", "problems", "optimization", or "explanation"',
          required: false,
        ),
      },
      callback: (args, extra) async {
        final focus = args?['focus'] as String? ?? 'explanation';
        
        String focusInstructions;
        switch (focus) {
          case 'signal_flow':
            focusInstructions = 'Focus on explaining the signal flow path through each algorithm.';
            break;
          case 'problems':
            focusInstructions = 'Look for potential routing problems, conflicts, or inefficiencies.';
            break;
          case 'optimization':
            focusInstructions = 'Suggest ways to optimize the routing for better performance or sound.';
            break;
          default:
            focusInstructions = 'Provide a clear explanation of how the routing works.';
        }
        
        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text: '''Please analyze the current routing configuration of my Disting NT preset.

$focusInstructions

Steps to follow:
1. Get the current preset state with get_current_preset
2. Get the routing information with get_routing  
3. Analyze the signal flow between algorithms
4. Explain how signals move through the bus system
5. Identify any issues or suggest improvements

Please use the physical names (Input N, Output N, Aux N) when explaining the routing, not internal bus numbers. Make the explanation clear and educational.'''
              )
            )
          ]
        );
      }
    );

    // Parameter tuner prompt
    server.prompt(
      'parameter-tuner',
      description: 'Helps tune algorithm parameters for specific sounds or behaviors',
      argsSchema: {
        'slot_index': PromptArgumentDefinition(
          description: 'Slot index of algorithm to tune (0-31)',
          required: true,
        ),
        'desired_sound': PromptArgumentDefinition(
          description: 'Describe the sound or behavior you want to achieve',
          required: true,
        ),
        'current_issue': PromptArgumentDefinition(
          description: 'What\'s not working about the current settings (optional)',
          required: false,
        ),
      },
      callback: (args, extra) async {
        final slotIndex = args!['slot_index'];
        final desiredSound = args['desired_sound'] as String;
        final currentIssue = args['current_issue'] as String? ?? '';
        
        final issueText = currentIssue.isNotEmpty ? '\nCurrent issue: $currentIssue' : '';
        
        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text: '''I want to tune the algorithm in slot $slotIndex to achieve: "$desiredSound"$issueText

Please help me tune the parameters by:
1. Getting the current preset state to see what algorithm is in slot $slotIndex
2. Getting detailed information about the algorithm and its parameters
3. Understanding the current parameter values and their ranges
4. Suggesting specific parameter changes to achieve the desired sound
5. Explaining what each parameter does and how it affects the sound
6. Making the changes step by step with explanations

Be specific about parameter values and explain the reasoning behind each suggestion.'''
              )
            )
          ]
        );
      }
    );

    // Troubleshooter prompt
    server.prompt(
      'troubleshooter',
      description: 'Helps diagnose and fix common Disting NT issues',
      argsSchema: {
        'problem': PromptArgumentDefinition(
          description: 'Describe the problem you\'re experiencing',
          required: true,
        ),
        'symptoms': PromptArgumentDefinition(
          description: 'Additional symptoms or context about the issue',
          required: false,
        ),
      },
      callback: (args, extra) async {
        final problem = args!['problem'] as String;
        final symptoms = args['symptoms'] as String? ?? '';
        
        final symptomsText = symptoms.isNotEmpty ? '\nAdditional symptoms: $symptoms' : '';
        
        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text: '''I'm having this problem with my Disting NT: "$problem"$symptomsText

Please help me troubleshoot this by:
1. Checking the connection status with mcp_diagnostics
2. Getting the current preset state to understand the configuration
3. Checking routing and signal flow if audio-related
4. Looking at CPU usage if performance-related
5. Suggesting step-by-step solutions to try
6. Explaining what each diagnostic step reveals

Work through the troubleshooting systematically and explain what we're checking at each step.'''
              )
            )
          ]
        );
      }
    );
  }

  /// Create a new transport and connect server following example pattern
  Future<StreamableHTTPServerTransport> _createNewTransport() async {
    StreamableHTTPServerTransport? transport;
    McpServer? server;
    
    // Create new server instance first
    server = _buildServer();
    
    // Create new transport with event store for resumability
    transport = StreamableHTTPServerTransport(
      options: StreamableHTTPServerTransportOptions(
        sessionIdGenerator: () => generateUUID(),
        eventStore: InMemoryEventStore(),
        onsessioninitialized: (sessionId) {
          // Store both transport and server by session ID when session is initialized
          debugPrint('[MCP] Session initialized with ID: $sessionId');
          _transports[sessionId] = transport!;
          _servers[sessionId] = server!;
        },
      ),
    );
    
    // Set up transport close handler with session cleanup
    transport.onclose = () {
      final sessionId = transport!.sessionId;
      if (sessionId != null && _transports.containsKey(sessionId)) {
        debugPrint('[MCP] Transport closed for session $sessionId, removing from transports map');
        _cleanupSession(sessionId);
      }
    };
    
    // Connect server to transport BEFORE handling requests
    await server.connect(transport);
    
    return transport;
  }

  /// Clean up a specific session
  void _cleanupSession(String sessionId) {
    _transports[sessionId]?.close();
    _transports.remove(sessionId);
    _servers.remove(sessionId);
    debugPrint('[MCP] Cleaned up session: $sessionId');
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


