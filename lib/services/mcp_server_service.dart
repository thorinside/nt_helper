import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';

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

/// Simplified MCP server service using StreamableHTTPServerTransport
/// for automatic session management, connection persistence, and health monitoring.
/// This service manages multiple MCP server instances, one per client connection.
///
/// MIGRATION NOTE: dart_mcp library (0.3.3) added to pubspec.yaml as dependency.
/// Future stories (E4.2+) will incrementally migrate from mcp_dart to dart_mcp.
/// Current implementation remains on mcp_dart for backward compatibility.
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

  // Pre-loaded resource cache
  final Map<String, String> _resourceCache = {};

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

  Future<void> start({int port = 3000, InternetAddress? bindAddress}) async {
    if (isRunning) {
      return;
    }

    try {
      // Pre-load all resources before starting server
      await _preloadResources();

      final address = bindAddress ?? InternetAddress.anyIPv4;

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

      notifyListeners();
    } catch (e) {
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
        request.response.headers.set(
          HttpHeaders.allowHeader,
          'GET, POST, DELETE, OPTIONS',
        );
        request.response.write('Method Not Allowed');
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
      } else if (_isInitializeRequest(body)) {
        // New initialization request - create transport and server
        if (sessionId != null) {
          // Client provided a session ID - use it for the new transport
          transport = await _createNewTransport(sessionId: sessionId);
        } else {
          // No session ID provided - generate one
          transport = await _createNewTransport();
        }

        // Ensure session is fully initialized before proceeding
        await Future.delayed(const Duration(milliseconds: 1));

        await transport.handleRequest(request, body);
        return; // Already handled
      } else {
        // Non-initialization request with unknown session ID - create a new session
        if (sessionId != null) {
          transport = await _createNewTransport(sessionId: sessionId);
        } else {
          _sendErrorResponse(
            request,
            HttpStatus.badRequest,
            'Bad Request: No session ID provided for non-initialization request',
          );
          return;
        }
      }

      // Handle the request with existing transport
      await transport.handleRequest(request, body);
    } catch (e) {
      _sendErrorResponse(
        request,
        HttpStatus.internalServerError,
        'Internal server error',
      );
    }
  }

  /// Handle GET requests for SSE streams
  Future<void> _handleGetRequest(HttpRequest request) async {
    final sessionId = request.headers.value('mcp-session-id');
    if (sessionId == null) {
      _sendErrorResponse(
        request,
        HttpStatus.badRequest,
        'Missing session ID for SSE stream',
      );
      return;
    }

    // If session doesn't exist, create a new transport for it
    if (!_transports.containsKey(sessionId)) {
      try {
        await _createNewTransport(sessionId: sessionId);
      } catch (e) {
        _sendErrorResponse(
          request,
          HttpStatus.internalServerError,
          'Failed to create session',
        );
        return;
      }
    }

    // Check for Last-Event-ID header for resumability
    final lastEventId = request.headers.value('Last-Event-ID');
    if (lastEventId != null) {
    } else {}

    final transport = _transports[sessionId]!;
    await transport.handleRequest(request);
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
      return;
    }

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
  }

  Future<void> restart({int port = 3000, InternetAddress? bindAddress}) async {
    await stop();
    await Future.delayed(const Duration(milliseconds: 500));
    await start(port: port, bindAddress: bindAddress);
  }

  void _cleanup() {
    _httpSubscription = null;
    _httpServer = null;
    _transports.clear();
    _servers.clear();
    _resourceCache.clear();
    notifyListeners();
  }

  /// Pre-load all documentation resources at startup
  Future<void> _preloadResources() async {
    // DEBUGGING: Use hardcoded content to test if the resource mechanism works
    // This bypasses asset loading entirely to isolate the issue
    final hardcodedContent = {
      'bus-mapping': '''# Bus Mapping Reference

## IO to Bus Conversion Rules

The Disting NT uses a bus-based internal routing system. Physical inputs/outputs map to internal buses as follows:

### Mapping Rules
- **Input N** = Bus N (e.g., Input 1 = Bus 1, Input 2 = Bus 2)
- **Output N** = Bus N+12 (e.g., Output 1 = Bus 13, Output 2 = Bus 14)  
- **Aux N** = Bus N+20 (e.g., Aux 1 = Bus 21, Aux 2 = Bus 22)
- **None** = Bus 0 (used for unused/disconnected signals)

### Important Notes
- Always use physical names (Input N, Output N, Aux N) when communicating with users
- Bus numbers are internal implementation details and should not be exposed to users
- Use the `get_routing` tool to see current bus assignments for loaded algorithms
''',
      'mcp-usage-guide': '''# MCP Usage Guide for Disting NT

## Essential Tools for Small LLMs

### Getting Started
1. **`get_current_preset`** - Always start here to understand the current state
2. **`list_algorithms`** - Find available algorithms by category or search
3. **`get_algorithm_details`** - Get detailed info about specific algorithms

### Building Presets
1. **`new_preset`** - Start with a clean slate
2. **`add_algorithm`** - Add algorithms using GUID or name (fuzzy matching ≥70%)
3. **`set_parameter_value`** - Configure algorithm parameters
4. **`save_preset`** - Persist changes to device

### Best Practices
- Check device connection status if operations fail
- Use exact algorithm names or GUIDs for reliable results
- Always verify parameter ranges before setting values
- Save presets after making changes to persist them
''',
      'algorithm-categories': '''# Algorithm Categories Reference

## Complete List of Available Categories

The Disting NT includes 44 algorithm categories organizing hundreds of algorithms:

### Audio Processing
- **Audio-IO** - Audio input/output utilities
- **Delay** - Echo, tape delay, ping-pong delay, reverse delay
- **Distortion** - Overdrive, fuzz, bit crusher, wave shaper
- **Dynamics** - Compression, gating, limiting, expansion
- **Effect** - General effects processing
- **EQ** - Equalization and tone shaping
- **Filter** - Low-pass, high-pass, band-pass, notch filters
- **Reverb** - Room, hall, plate, spring reverb algorithms

### Synthesis & Generation
- **Chiptune** - Retro 8-bit style sound generation
- **FM** - Frequency modulation synthesis
- **Granular** - Granular synthesis and processing
- **Noise** - White, pink, brown noise generation
- **Oscillator** - Basic waveform oscillators
- **Physical-Modeling** - Plucked string, resonator, modal synthesis
''',
      'preset-format': '''# Preset Format Reference

## JSON Structure for `build_preset_from_json`

### Complete Preset Structure
```json
{
  "preset_name": "My Preset",
  "slots": [
    {
      "algorithm": {
        "guid": "algorithm_guid",
        "name": "Algorithm Name"
      },
      "parameters": [
        {
          "parameter_number": 0,
          "value": 1.5
        }
      ]
    }
  ]
}
```

### Required Fields
- **`preset_name`**: String name for the preset
- **`slots`**: Array of slot configurations (max 32 slots)

### Slot Structure
- **`algorithm`**: Algorithm to load in this slot
  - **`guid`**: Exact algorithm GUID (preferred)
  - **`name`**: Algorithm name (fuzzy matching ≥70%)
- **`parameters`**: Array of parameter configurations (optional)
''',
      'routing-concepts': '''# Routing Concepts for Disting NT

## Signal Flow Fundamentals

### Processing Order
- Algorithms execute in slot order: Slot 0 → Slot 1 → ... → Slot N
- **Earlier slots** process signals before later slots
- **Modulation sources** must be in earlier slots than their targets

### Input/Output Behavior
- **Inputs**: Algorithms read from assigned input buses
- **Outputs**: Algorithms write to assigned output buses  
- **Signal Replacement**: When multiple algorithms output to the same bus, later slots replace earlier signals
- **Signal Combination**: Some algorithms can combine/mix signals rather than replace

### Common Routing Patterns
1. **Audio Chain**: Input 1,2 → Filter → Reverb → Output 1,2
2. **CV Modulation**: LFO (None → Output 3) → VCA CV Input (Input 3)
3. **Parallel Processing**: Input 1 → [Delay, Chorus] → Mixer → Output 1
4. **Feedback Loops**: Output bus routed back as input to earlier slot
''',
    };

    // Load hardcoded content into cache
    for (final entry in hardcodedContent.entries) {
      _resourceCache[entry.key] = entry.value;
    }

    // Debug: Show what's in the cache
    for (final _ in _resourceCache.entries) {}
  }

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit);
    final distingTools = DistingTools(distingControllerForTools, _distingCubit);

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
      'search',
      description:
          'Search for algorithms by name or category with fuzzy matching. Returns top 10 matches sorted by relevance.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'type': {
            'type': 'string',
            'description': 'Type of search. Currently only "algorithm" is supported.',
            'enum': ['algorithm'],
          },
          'query': {
            'type': 'string',
            'description':
                'Search query: algorithm name, partial name, or category. Fuzzy matching threshold: 70% similarity.',
          },
        },
        required: ['type', 'query'],
      ),
      callback: ({args, extra}) async {
        try {
          final resultJson = await tools.searchAlgorithms(args ?? {}).timeout(
                const Duration(seconds: 5),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 5 seconds',
                }),
              );
          return CallToolResult.fromContent(
            content: [TextContent(text: resultJson)],
          );
        } catch (e) {
          final errorJson = jsonEncode({
            'success': false,
            'error': 'Tool execution failed: ${e.toString()}',
          });
          return CallToolResult.fromContent(
            content: [TextContent(text: errorJson)],
          );
        }
      },
    );

    server.tool(
      'get_algorithm_details',
      description:
          'Get algorithm metadata by GUID or name. Supports fuzzy matching >=70%.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
          'algorithm_name': {'type': 'string', 'description': 'Algorithm name'},
          'expand_features': {
            'type': 'boolean',
            'description': 'Expand parameters',
            'default': false,
          },
        },
      ),
      callback: ({args, extra}) async {
        try {
          // Add a timeout to prevent hanging
          final resultJson = await tools
              .getAlgorithmDetails(args ?? {})
              .timeout(
                const Duration(seconds: 5),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 5 seconds',
                  'requested_algorithm':
                      args?['algorithm_guid'] ??
                      args?['algorithm_name'] ??
                      'unknown',
                }),
              );
          return CallToolResult.fromContent(
            content: [TextContent(text: resultJson)],
          );
        } catch (e) {
          final errorJson = jsonEncode({
            'success': false,
            'error': 'Tool execution failed: ${e.toString()}',
          });
          return CallToolResult.fromContent(
            content: [TextContent(text: errorJson)],
          );
        }
      },
    );

    server.tool(
      'list_algorithms',
      description: 'List algorithms with optional category/text filtering.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'category': {'type': 'string', 'description': 'Filter by category'},
          'query': {'type': 'string', 'description': 'Text search filter'},
        },
      ),
      callback: ({args, extra}) async {
        try {
          final resultJson = await tools.listAlgorithms(args ?? {});
          return CallToolResult.fromContent(
            content: [TextContent(text: resultJson)],
          );
        } catch (e) {
          final errorJson = jsonEncode({
            'success': false,
            'error': 'Tool execution failed: ${e.toString()}',
          });
          return CallToolResult.fromContent(
            content: [TextContent(text: errorJson)],
          );
        }
      },
    );

    server.tool(
      'get_routing',
      description:
          'Get current routing state. Always use physical names (Input N, Output N, Aux N, None).',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        try {
          final resultJson = await tools.getCurrentRoutingState(args ?? {});
          return CallToolResult.fromContent(
            content: [TextContent(text: resultJson)],
          );
        } catch (e) {
          final errorJson = jsonEncode({
            'success': false,
            'error': 'Tool execution failed: ${e.toString()}',
          });
          return CallToolResult.fromContent(
            content: [TextContent(text: errorJson)],
          );
        }
      },
    );
  }

  void _registerDistingTools(McpServer server, DistingTools tools) {
    server.tool(
      'get_current_preset',
      description:
          'Get preset with slots and parameters. Use parameter_number from this for set/get_parameter_value.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final resultJson = await tools.getCurrentPreset(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'add_algorithm',
      description:
          'Add algorithm to first available slot. Use GUID or name (fuzzy matching >=70%).',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
          'algorithm_name': {'type': 'string', 'description': 'Algorithm name'},
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.addAlgorithm(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'remove_algorithm',
      description:
          'Remove algorithm from slot. WARNING: Subsequent algorithms shift down.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.removeAlgorithm(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'set_parameter_value',
      description:
          'Set parameter value. Use parameter_number from get_current_preset OR parameter_name.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
          'parameter_number': {
            'type': 'integer',
            'description': 'From get_current_preset',
          },
          'parameter_name': {
            'type': 'string',
            'description': 'Parameter name (must be unique)',
          },
          'value': {
            'type': 'number',
            'description': 'Value within parameter min/max',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.setParameterValue(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'get_parameter_value',
      description:
          'Get parameter value. Use parameter_number from get_current_preset.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
          'parameter_number': {
            'type': 'integer',
            'description': 'From get_current_preset',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.getParameterValue(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'get_parameter_enum_values',
      description: 'Get available enum values for an enum parameter',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
          'parameter_number': {
            'type': 'integer',
            'description': 'Parameter number (0-based)',
          },
          'parameter_name': {
            'type': 'string',
            'description': 'Parameter name (alternative to number)',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.getParameterEnumValues(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
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
      toolInputSchema: const ToolInputSchema(
        properties: {
          'name': {'type': 'string', 'description': 'Preset name'},
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.setPresetName(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'set_slot_name',
      description: 'Set custom slot name. Use save_preset to persist.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
          'name': {'type': 'string', 'description': 'Custom slot name'},
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.setSlotName(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'new_preset',
      description:
          'Clear current preset and start new empty one. Unsaved changes lost.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final resultJson = await tools.newPreset(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'new',
      description:
          'Create new blank preset or preset with initial algorithms. WARNING: Clears current preset (unsaved changes lost). Device must be in connected mode.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'name': {
            'type': 'string',
            'description': 'Name for the new preset (required)',
          },
          'algorithms': {
            'type': 'array',
            'description':
                'Array of algorithms to add (optional). Each item: {guid: string, name: string, specifications: array}. Algorithms added sequentially to slots 0, 1, 2, etc.',
            'items': {
              'type': 'object',
              'properties': {
                'guid': {
                  'type': 'string',
                  'description': 'Algorithm GUID (alternative to name)',
                },
                'name': {
                  'type': 'string',
                  'description':
                      'Algorithm name (fuzzy matching ≥70%, alternative to guid)',
                },
                'specifications': {
                  'type': 'array',
                  'description': 'Algorithm-specific specification values (optional)',
                  'items': {'type': 'object'},
                },
              },
            },
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.newWithAlgorithms(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'save_preset',
      description: 'Save current preset to device.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final resultJson = await tools.savePreset(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'edit',
      description:
          'Edit preset with preset-level granularity. Accepts complete preset state and applies only necessary changes. Device must be in connected mode.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'target': {
            'type': 'string',
            'enum': ['preset'],
            'description': 'Target type (must be "preset")',
          },
          'data': {
            'type': 'object',
            'description':
                'Preset state with name and slots array. Each slot contains algorithm (guid or name) and optional parameters with values and optional mappings.',
            'properties': {
              'name': {
                'type': 'string',
                'description': 'Preset name',
              },
              'slots': {
                'type': 'array',
                'description': 'Array of slot objects (indexed by position)',
                'items': {
                  'type': 'object',
                  'properties': {
                    'algorithm': {
                      'type': 'object',
                      'description':
                          'Algorithm specification (either guid or name)',
                      'properties': {
                        'guid': {
                          'type': 'string',
                          'description': 'Algorithm GUID',
                        },
                        'name': {
                          'type': 'string',
                          'description': 'Algorithm name (fuzzy matching)',
                        },
                      },
                    },
                    'parameters': {
                      'type': 'array',
                      'description': 'Array of parameter objects',
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
                                'Optional mapping (cv, midi, i2c, performance_page)',
                          },
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.editPreset(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'get_preset_name',
      description: 'Get current preset name.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final resultJson = await tools.getPresetName(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'get_slot_name',
      description: 'Get custom slot name for specified slot.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.getSlotName(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );
  }

  void _registerMovementTools(McpServer server, DistingTools tools) {
    server.tool(
      'move_algorithm_up',
      description:
          'Move algorithm up one slot. Algorithms evaluate top to bottom.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.moveAlgorithmUp(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'move_algorithm_down',
      description:
          'Move algorithm down one slot. Algorithms evaluate top to bottom.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.moveAlgorithmDown(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'move_algorithm',
      description:
          'Move algorithm in specified direction with optional step count. More flexible than individual up/down tools.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
          'direction': {
            'type': 'string',
            'description': 'Direction to move: "up" or "down"',
          },
          'steps': {
            'type': 'integer',
            'description': 'Number of steps to move (default: 1)',
            'default': 1,
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.moveAlgorithm(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );
  }

  void _registerBatchTools(McpServer server, DistingTools tools) {
    server.tool(
      'set_multiple_parameters',
      description:
          'Set multiple parameters in one operation. More efficient than individual calls.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
          'parameters': {
            'type': 'array',
            'description': 'Array of parameter objects',
            'items': {
              'type': 'object',
              'properties': {
                'parameter_number': {
                  'type': 'integer',
                  'description': 'Parameter number (0-based)',
                },
                'parameter_name': {
                  'type': 'string',
                  'description': 'Parameter name (alternative to number)',
                },
                'value': {'type': 'number', 'description': 'Parameter value'},
              },
            },
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.setMultipleParameters(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'get_multiple_parameters',
      description:
          'Get multiple parameter values in one operation. More efficient than individual calls.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'slot_index': {
            'type': 'integer',
            'description': '0-based slot index',
          },
          'parameter_numbers': {
            'type': 'array',
            'description': 'Array of parameter numbers to retrieve',
            'items': {'type': 'integer'},
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.getMultipleParameters(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'build_preset_from_json',
      description:
          'Build complete preset from JSON data. Supports algorithms and parameters.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'preset_data': {
            'type': 'object',
            'description': 'JSON object with preset_name and slots array',
            'properties': {
              'preset_name': {'type': 'string'},
              'slots': {'type': 'array'},
            },
            'required': ['preset_name', 'slots'],
          },
          'clear_existing': {
            'type': 'boolean',
            'description': 'Clear existing preset first (default: true)',
            'default': true,
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.buildPresetFromJson(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );
  }

  void _registerUtilityTools(McpServer server, DistingTools tools) {
    server.tool(
      'get_module_screenshot',
      description: 'Get current module screenshot as base64 JPEG.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final Map<String, dynamic> result = await tools.getModuleScreenshot(
          args ?? {},
        );
        if (result['success'] == true) {
          return CallToolResult.fromContent(
            content: [
              ImageContent(
                data: result['screenshot_base64'] as String,
                mimeType: 'image/jpeg',
              ),
            ],
          );
        } else {
          return CallToolResult.fromContent(
            content: [
              TextContent(
                text:
                    result['error'] as String? ??
                    'Unknown error retrieving screenshot',
              ),
            ],
          );
        }
      },
    );

    server.tool(
      'get_cpu_usage',
      description:
          'Get current CPU usage including per-core and per-slot usage percentages.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final resultJson = await tools.getCpuUsage(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'set_notes',
      description:
          'Add/update Notes algorithm at slot 0. Max 7 lines of 31 chars each.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'text': {
            'type': 'string',
            'description': 'Note text (auto-wrapped at 31 chars)',
          },
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.setNotes(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'get_notes',
      description:
          'Get current notes content from Notes algorithm if it exists.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final resultJson = await tools.getNotes(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'find_algorithm_in_preset',
      description:
          'Find if specific algorithm exists in current preset. Returns slot locations.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'algorithm_guid': {'type': 'string', 'description': 'Algorithm GUID'},
          'algorithm_name': {'type': 'string', 'description': 'Algorithm name'},
        },
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.findAlgorithmInPreset(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );
  }

  void _registerDiagnosticTools(McpServer server) {
    server.tool(
      'mcp_diagnostics',
      description:
          'Get MCP server connection diagnostics and health information',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        // Get current Disting state
        final distingState = _distingCubit.state;

        // Build state-specific diagnostics
        final Map<String, dynamic> stateInfo = {
          'state_type': distingState.runtimeType.toString(),
        };

        if (distingState is DistingStateSynchronized) {
          // Get manager type for connection mode
          final manager = distingState.disting;
          String connectionMode = 'unknown';
          if (manager.runtimeType.toString().contains('Mock')) {
            connectionMode = 'demo';
          } else if (manager.runtimeType.toString().contains('Offline')) {
            connectionMode = 'offline';
          } else {
            connectionMode = 'connected';
          }

          stateInfo.addAll({
            'connection_mode': connectionMode,
            'firmware_version': distingState.firmwareVersion.versionString,
            'disting_version': distingState.distingVersion,
            'preset_name': distingState.presetName,
            'num_slots': distingState.slots.length,
            'num_algorithms_available': distingState.algorithms.length,
            'num_unit_strings': distingState.unitStrings.length,
          });

          // Count non-empty slots
          final nonEmptySlots = distingState.slots
              .where(
                (slot) =>
                    slot.algorithm.guid.isNotEmpty &&
                    slot.algorithm.guid != 'ERROR',
              )
              .length;
          stateInfo['num_loaded_slots'] = nonEmptySlots;
        }

        final diagnostics = {
          'server_info': connectionDiagnostics,
          'transport_info': {
            'active_transports': _transports.length,
            'sessions': _transports.keys.toList(),
            'transport_type': 'StreamableHTTPServerTransport',
          },
          'disting_state': stateInfo,
        };

        return CallToolResult.fromContent(
          content: [TextContent(text: jsonEncode(diagnostics))],
        );
      },
    );
  }

  /// Helper method to create resource callback with pre-loaded content
  ReadResourceCallback _createResourceCallback(
    String resourceName,
    String content,
  ) {
    return (uri, extra) async {
      final startTime = DateTime.now();

      // DEBUGGING: Add more detailed logging for resource requests

      // Double-check cache state at request time
      final originalContent = _resourceCache[resourceName];
      if (originalContent != null) {
      } else {}

      // Use real content now that we know the mechanism works
      var rawContent =
          originalContent ??
          'Documentation not available - Resource not found in cache: $resourceName';

      // SANITIZE: Replace Unicode characters that break MCP JSON serialization
      final originalLength = rawContent.length;
      final finalContent = rawContent
          .replaceAll('≥', '>=') // U+2265 → ASCII equivalent
          .replaceAll('→', '->') // U+2192 → ASCII equivalent
          .replaceAll('←', '<-') // U+2190 → ASCII equivalent
          .replaceAll('↑', '^') // U+2191 → ASCII equivalent
          .replaceAll('↓', 'v') // U+2193 → ASCII equivalent
          .replaceAll('\'', "'") // U+2019 → ASCII apostrophe
          .replaceAll('"', '"') // U+201C → ASCII quote
          .replaceAll('"', '"'); // U+201D → ASCII quote

      final sanitizedLength = finalContent.length;
      if (originalLength != sanitizedLength) {
      } else {}

      // Return pre-loaded content immediately - no async operations
      // Try different ways to construct the ResourceContents

      try {
        final resourceContents = ResourceContents.fromJson({
          'uri': uri.toString(),
          'text': finalContent,
          'mimeType': 'text/markdown',
        });

        final result = ReadResourceResult(contents: [resourceContents]);

        DateTime.now().difference(startTime);

        return result;
      } catch (e) {
        // Last resort: return empty result
        DateTime.now().difference(startTime);

        return ReadResourceResult(contents: []);
      }
    };
  }

  void _registerDocumentationResources(McpServer server) {
    // Define resource metadata
    final resourceMeta = {
      'bus-mapping': 'IO to Bus conversion rules and routing concepts',
      // 'mcp-usage-guide': 'Essential tools and workflows for MCP clients',
      // 'algorithm-categories':
      //     'Complete list of algorithm categories and descriptions',
      // 'preset-format': 'JSON schema and examples for preset data',
      'routing-concepts': 'Signal flow and routing fundamentals',
    };

    // Register each resource with pre-loaded content
    for (final entry in resourceMeta.entries) {
      final resourceName = entry.key;
      final description = entry.value;

      // Get content from cache - fallback to error message if not found
      final content =
          _resourceCache[resourceName] ??
          'Documentation not available - Resource not cached: $resourceName';

      // DEBUGGING: Add more detailed logging for registration

      if (_resourceCache.containsKey(resourceName)) {
      } else {}

      server.resource(
        resourceName,
        resourceName,
        _createResourceCallback(resourceName, content),
        metadata: (mimeType: 'text/markdown', description: description),
      );
    }
  }

  void _registerHelpfulPrompts(McpServer server) {
    // Preset builder prompt - guides through building a preset step by step
    server.prompt(
      'preset-builder',
      description: 'Guides you through building a custom preset step by step',
      argsSchema: {
        'use_case': PromptArgumentDefinition(
          description:
              'Describe what you want the preset to do (e.g., "audio delay with modulation", "CV sequencer setup")',
          required: true,
        ),
        'skill_level': PromptArgumentDefinition(
          description:
              'Your experience level: "beginner", "intermediate", or "advanced"',
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
                text:
                    'I want to build a Disting NT preset for: "$useCase"\n\nMy skill level is: $skillLevel\n\nPlease help me build this preset step by step. Start by:\n1. Understanding the current state with get_current_preset\n2. Suggesting appropriate algorithms from the right categories\n3. Setting up the signal routing properly\n4. Configuring parameters for the desired sound/behavior\n\nUse the MCP tools available to inspect the current state and build the preset interactively. Explain each step clearly and ask for feedback before proceeding to the next step.',
              ),
            ),
          ],
        );
      },
    );

    // Algorithm recommender prompt
    server.prompt(
      'algorithm-recommender',
      description:
          'Recommends algorithms based on musical/technical requirements',
      argsSchema: {
        'requirement': PromptArgumentDefinition(
          description:
              'What you need the algorithm to do (e.g., "filter bass frequencies", "generate random CV", "create stereo delay")',
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

        final contextText = context.isNotEmpty
            ? '\nAdditional context: $context'
            : '';

        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text:
                    'I need an algorithm that can: "$requirement"$contextText\n\nPlease help me find the best algorithm(s) for this by:\n1. Searching through appropriate categories using list_algorithms\n2. Getting detailed information about promising candidates with get_algorithm_details\n3. Explaining the pros and cons of each option\n4. Recommending the best choice with reasoning\n5. Suggesting how to integrate it into a preset effectively\n\nFocus on practical recommendations that will work well for my specific use case.',
              ),
            ),
          ],
        );
      },
    );

    // Routing analyzer prompt
    server.prompt(
      'routing-analyzer',
      description: 'Analyzes and explains current routing configuration',
      argsSchema: {
        'focus': PromptArgumentDefinition(
          description:
              'What to focus on: "signal_flow", "problems", "optimization", or "explanation"',
          required: false,
        ),
      },
      callback: (args, extra) async {
        final focus = args?['focus'] as String? ?? 'explanation';

        String focusInstructions;
        switch (focus) {
          case 'signal_flow':
            focusInstructions =
                'Focus on explaining the signal flow path through each algorithm.';
            break;
          case 'problems':
            focusInstructions =
                'Look for potential routing problems, conflicts, or inefficiencies.';
            break;
          case 'optimization':
            focusInstructions =
                'Suggest ways to optimize the routing for better performance or sound.';
            break;
          default:
            focusInstructions =
                'Provide a clear explanation of how the routing works.';
        }

        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text:
                    'Please analyze the current routing configuration of my Disting NT preset.\n\n$focusInstructions\n\nSteps to follow:\n1. Get the current preset state with get_current_preset\n2. Get the routing information with get_routing\n3. Analyze the signal flow between algorithms\n4. Explain how signals move through the bus system\n5. Identify any issues or suggest improvements\n\nPlease use the physical names (Input N, Output N, Aux N) when explaining the routing, not internal bus numbers. Make the explanation clear and educational.',
              ),
            ),
          ],
        );
      },
    );

    // Parameter tuner prompt
    server.prompt(
      'parameter-tuner',
      description:
          'Helps tune algorithm parameters for specific sounds or behaviors',
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
          description:
              'What is not working about the current settings (optional)',
          required: false,
        ),
      },
      callback: (args, extra) async {
        final slotIndex = args!['slot_index'];
        final desiredSound = args['desired_sound'] as String;
        final currentIssue = args['current_issue'] as String? ?? '';

        final issueText = currentIssue.isNotEmpty
            ? '\nCurrent issue: $currentIssue'
            : '';

        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text:
                    'I want to tune the algorithm in slot $slotIndex to achieve: "$desiredSound"$issueText\n\nPlease help me tune the parameters by:\n1. Getting the current preset state to see what algorithm is in slot $slotIndex\n2. Getting detailed information about the algorithm and its parameters\n3. Understanding the current parameter values and their ranges\n4. Suggesting specific parameter changes to achieve the desired sound\n5. Explaining what each parameter does and how it affects the sound\n6. Making the changes step by step with explanations\n\nBe specific about parameter values and explain the reasoning behind each suggestion.',
              ),
            ),
          ],
        );
      },
    );

    // Troubleshooter prompt
    server.prompt(
      'troubleshooter',
      description: 'Helps diagnose and fix common Disting NT issues',
      argsSchema: {
        'problem': PromptArgumentDefinition(
          description: 'Describe the problem you are experiencing',
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

        final symptomsText = symptoms.isNotEmpty
            ? '\nAdditional symptoms: $symptoms'
            : '';

        return GetPromptResult(
          messages: [
            PromptMessage(
              role: PromptMessageRole.user,
              content: TextContent(
                text:
                    'I am having this problem with my Disting NT: "$problem"$symptomsText\n\nPlease help me troubleshoot this by:\n1. Checking the connection status with mcp_diagnostics\n2. Getting the current preset state to understand the configuration\n3. Checking routing and signal flow if audio-related\n4. Looking at CPU usage if performance-related\n5. Suggesting step-by-step solutions to try\n6. Explaining what each diagnostic step reveals\n\nWork through the troubleshooting systematically and explain what we are checking at each step.',
              ),
            ),
          ],
        );
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

    // Create new transport with event store for resumability
    transport = StreamableHTTPServerTransport(
      options: StreamableHTTPServerTransportOptions(
        sessionIdGenerator: sessionId != null
            ? () => sessionId
            : () => generateUUID(),
        eventStore: InMemoryEventStore(),
        onsessioninitialized: (initializedSessionId) {
          // Store both transport and server by session ID when session is initialized
          _transports[initializedSessionId] = transport!;
          _servers[initializedSessionId] = server!;
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

    // Connect server to transport BEFORE handling requests
    await server.connect(transport);

    return transport;
  }

  /// Clean up a specific session
  void _cleanupSession(String sessionId) {
    _transports[sessionId]?.close();
    _transports.remove(sessionId);
    _servers.remove(sessionId);
  }
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
