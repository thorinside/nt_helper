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


  /// Handle POST requests for JSON-RPC calls
  Future<void> _handlePostRequest(HttpRequest request) async {
    try {
      // Check for existing session ID
      final sessionId = request.headers.value('mcp-session-id');
      StreamableHTTPServerTransport? transport;

      if (sessionId != null && _transports.containsKey(sessionId)) {
        // Reuse existing transport for this session
        transport = _transports[sessionId]!;
      } else {
        // Create new transport for new session
        // If client provided a session ID, use it; otherwise generate one
        transport = await _createNewTransport(sessionId: sessionId);
      }

      // Handle the request - transport will parse the body internally
      await transport.handleRequest(request);
    } catch (e) {
      _sendErrorResponse(
        request,
        HttpStatus.internalServerError,
        'Internal server error: ${e.toString()}',
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
    notifyListeners();
  }

  McpServer _buildServer() {
    final distingControllerForTools = DistingControllerImpl(_distingCubit);
    final mcpAlgorithmTools = MCPAlgorithmTools(_distingCubit);
    final distingTools = DistingTools(distingControllerForTools, _distingCubit);

    final server = McpServer(
      Implementation(name: 'nt-helper-flutter', version: '1.39.0'),
      options: ServerOptions(
        capabilities: ServerCapabilities(
          tools: ServerCapabilitiesTools(),
        ),
      ),
    );

    // Register MCP tools
    _registerAlgorithmTools(server, mcpAlgorithmTools, distingTools);
    _registerDistingTools(server, distingTools);

    return server;
  }

  void _registerAlgorithmTools(McpServer server, MCPAlgorithmTools tools, DistingTools distingTools) {
    server.tool(
      'search',
      description:
          'Search for algorithms by name/category, or search for parameters within preset/slot. Algorithms use fuzzy matching (70% threshold), parameters use exact/partial name matching.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'target': {
            'type': 'string',
            'description': 'What to search for: "algorithm" or "parameter"',
            'enum': ['algorithm', 'parameter'],
          },
          'query': {
            'type': 'string',
            'description':
                'Search query. For algorithms: name, partial name, or category (fuzzy matching). For parameters: parameter name (case-insensitive).',
          },
          'scope': {
            'type': 'string',
            'description':
                'Scope for parameter search: "preset" (all slots) or "slot" (specific slot). Required when target="parameter".',
            'enum': ['preset', 'slot'],
          },
          'slot_index': {
            'type': 'integer',
            'description':
                'Slot index (0-31) for parameter search with scope="slot". Required when target="parameter" and scope="slot".',
          },
          'partial_match': {
            'type': 'boolean',
            'description':
                'For parameter search: if true, find parameters containing the query. Default: false (exact match).',
          },
        },
        required: ['target', 'query'],
      ),
      callback: ({args, extra}) async {
        try {
          final target = args?['target'] as String?;

          late String resultJson;
          if (target == 'algorithm') {
            resultJson = await tools.searchAlgorithms(args ?? {}).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => jsonEncode({
                    'success': false,
                    'error': 'Tool execution timed out after 5 seconds',
                  }),
                );
          } else if (target == 'parameter') {
            resultJson = await distingTools.searchParameters(args ?? {}).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () => jsonEncode({
                    'success': false,
                    'error': 'Tool execution timed out after 5 seconds',
                  }),
                );
          } else {
            resultJson = jsonEncode({
              'success': false,
              'error': 'Invalid target. Must be "algorithm" or "parameter".',
            });
          }

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
      'show',
      description:
          'Show preset, slot, parameter, screen, routing, or CPU information. Returns mappings for enabled CV/MIDI/i2c/performance page controls. Disabled mappings omitted from output. See docs/mcp-mapping-guide.md for mapping field details.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'target': {
            'type': 'string',
            'description':
                'What to display: "preset" (all slots/parameters), "slot" (single slot), "parameter" (single parameter), "screen" (device screenshot), "routing" (signal flow), "cpu" (CPU usage)',
            'enum': ['preset', 'slot', 'parameter', 'screen', 'routing', 'cpu'],
          },
          'identifier': {
            'type': ['string', 'integer'],
            'description':
                'Required for slot/parameter targets. For slot: integer index (0-31). For parameter: "slot_index:parameter_number" (e.g., "0:5")',
          },
          'display_mode': {
            'type': 'string',
            'description':
                'Optional display mode for screen target. Changes hardware display mode before capturing screenshot. Options: "parameter" (hardware parameter list), "algorithm" (custom algorithm interface), "overview" (all slots overview), "vu_meters" (VU meter display)',
            'enum': ['parameter', 'algorithm', 'overview', 'vu_meters'],
          },
        },
        required: ['target'],
      ),
      callback: ({args, extra}) async {
        try {
          final resultJson = await tools.show(args ?? {}).timeout(
                const Duration(seconds: 10),
                onTimeout: () => jsonEncode({
                  'success': false,
                  'error': 'Tool execution timed out after 10 seconds',
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
  }

  void _registerDistingTools(McpServer server, DistingTools tools) {
    // Register new/edit tools
    _registerPresetTools(server, tools);
    _registerUtilityTools(server, tools);
  }

  void _registerPresetTools(McpServer server, DistingTools tools) {
    server.tool(
      'new',
      description:
          'Create new blank preset or preset with initial algorithms. WARNING: Clears current preset.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'name': {
            'type': 'string',
            'description': 'Name for the new preset.',
          },
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
              },
            },
          },
        },
        required: ['name'],
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.newWithAlgorithms(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'save',
      description: 'Save the current preset to the device.',
      toolInputSchema: const ToolInputSchema(properties: {}),
      callback: ({args, extra}) async {
        final resultJson = await tools.savePreset(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    // Simple 'add' tool with flat parameter structure for reduced cognitive load
    server.tool(
      'add',
      description: 'Add an algorithm to the preset. Requires name or guid.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'target': {
            'type': 'string',
            'enum': ['algorithm'],
            'description': 'Must be "algorithm".',
          },
          'name': {
            'type': 'string',
            'description': 'Algorithm name (fuzzy matching). Required if no guid.',
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
        },
        required: ['target'],
      ),
      callback: ({args, extra}) async {
        final resultJson = await tools.addSimple(args ?? {});
        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );

    server.tool(
      'edit',
      description:
          'Edit preset, slot, or parameter with appropriate granularity. Target "preset": full preset state. Target "slot": specific slot with algorithm/parameters. Target "parameter": individual parameter value/mapping. Device must be in connected mode.',
      toolInputSchema: const ToolInputSchema(
        properties: {
          'target': {
            'type': 'string',
            'enum': ['preset', 'slot', 'parameter'],
            'description': 'Target type: "preset" for full preset, "slot" for slot-level, "parameter" for parameter-level edits',
          },
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Slot index (0-31)',
          },
          'parameter': {
            'description':
                'For target "parameter": parameter identifier (string name or integer number, 0-based). Required for parameter target.',
            'oneOf': [
              {'type': 'string'},
              {'type': 'integer'},
            ],
          },
          'value': {
            'type': 'number',
            'description':
                'For target "parameter": optional parameter value. If omitted, mapping must be provided.',
          },
          'mapping': {
            'type': 'object',
            'description':
                'Parameter mapping with CV, MIDI, i2c, and performance page controls. Supports partial updates (e.g., update only MIDI, preserve CV/i2c). See docs/mcp-mapping-guide.md for complete field documentation and examples.',
            'properties': {
              'cv': {
                'type': 'object',
                'description': 'CV mapping: source (algorithm output index), cv_input (0-12), is_unipolar (boolean), is_gate (boolean), volts (0-127), delta (sensitivity). See mapping guide.',
                'properties': {
                  'source': {
                    'type': 'integer',
                    'description': 'Algorithm output index to observe (0=not used)',
                  },
                  'cv_input': {
                    'type': 'integer',
                    'description': 'Physical CV input (0=disabled, 1-12=inputs)',
                  },
                  'is_unipolar': {
                    'type': 'boolean',
                    'description': 'Voltage range: true=unipolar (0-10V), false=bipolar (-5V to +5V)',
                  },
                  'is_gate': {
                    'type': 'boolean',
                    'description': 'Gate/trigger mode for this CV input',
                  },
                  'volts': {
                    'type': 'integer',
                    'description': 'Voltage scaling factor (0-127)',
                  },
                  'delta': {
                    'type': 'integer',
                    'description': 'Sensitivity/responsiveness (0-1000+)',
                  },
                },
              },
              'midi': {
                'type': 'object',
                'description': 'MIDI mapping: is_midi_enabled (boolean), midi_channel (0-15), midi_type (cc|note_momentary|note_toggle|cc_14bit_low|cc_14bit_high), midi_cc (0-128), is_midi_symmetric (boolean), is_midi_relative (boolean), midi_min (0), midi_max (127). See mapping guide.',
                'properties': {
                  'is_midi_enabled': {
                    'type': 'boolean',
                    'description': 'Enable/disable MIDI control',
                  },
                  'midi_channel': {
                    'type': 'integer',
                    'description': 'MIDI channel (0-15, where 0=channel 1, 15=channel 16)',
                  },
                  'midi_type': {
                    'type': 'string',
                    'enum': [
                      'cc',
                      'note_momentary',
                      'note_toggle',
                      'cc_14bit_low',
                      'cc_14bit_high',
                    ],
                    'description': 'Type of MIDI message',
                  },
                  'midi_cc': {
                    'type': 'integer',
                    'description': 'MIDI CC number (0-127) or 128 for aftertouch',
                  },
                  'is_midi_symmetric': {
                    'type': 'boolean',
                    'description': 'Symmetric scaling around center value',
                  },
                  'is_midi_relative': {
                    'type': 'boolean',
                    'description': 'Relative mode for incremental changes',
                  },
                  'midi_min': {
                    'type': 'integer',
                    'description': 'Minimum value for scaling (typically 0)',
                  },
                  'midi_max': {
                    'type': 'integer',
                    'description': 'Maximum value for scaling (typically 127)',
                  },
                },
              },
              'i2c': {
                'type': 'object',
                'description': 'i2c mapping: is_i2c_enabled (boolean), i2c_cc (0-255), is_i2c_symmetric (boolean), i2c_min (0+), i2c_max (0+). See mapping guide.',
                'properties': {
                  'is_i2c_enabled': {
                    'type': 'boolean',
                    'description': 'Enable/disable i2c control',
                  },
                  'i2c_cc': {
                    'type': 'integer',
                    'description': 'i2c CC number (0-255)',
                  },
                  'is_i2c_symmetric': {
                    'type': 'boolean',
                    'description': 'Symmetric scaling around center value',
                  },
                  'i2c_min': {
                    'type': 'integer',
                    'description': 'Minimum value for scaling range',
                  },
                  'i2c_max': {
                    'type': 'integer',
                    'description': 'Maximum value for scaling range',
                  },
                },
              },
              'performance_page': {
                'type': 'integer',
                'description': 'Performance page index (0=not assigned, 1-15=page number). See mapping guide.',
              },
            },
          },
          'data': {
            'type': 'object',
            'description':
                'Data payload varies by target. For "preset": full preset with name and slots array. For "slot": slot state with optional algorithm, parameters, and name. For "parameter": omit this field (use value/mapping instead).',
            'properties': {
              'algorithm': {
                'type': 'object',
                'description':
                    'Optional algorithm specification (guid or name, plus optional specifications)',
                'properties': {
                  'guid': {
                    'type': 'string',
                    'description': 'Algorithm GUID',
                  },
                  'name': {
                    'type': 'string',
                    'description': 'Algorithm name (fuzzy matching)',
                  },
                  'specifications': {
                    'type': 'array',
                    'description': 'Algorithm-specific specification values',
                    'items': {'type': 'object'},
                  },
                },
              },
              'name': {
                'type': 'string',
                'description': 'Optional custom slot name',
              },
              'parameters': {
                'type': 'array',
                'description': 'Array of parameter objects with optional values and mappings',
                'items': {
                  'type': 'object',
                  'properties': {
                    'parameter_number': {
                      'type': 'integer',
                      'description': 'Parameter index',
                    },
                    'value': {
                      'type': 'number',
                      'description': 'Optional parameter value',
                    },
                    'mapping': {
                      'type': 'object',
                      'description':
                          'Optional mapping with CV, MIDI, i2c, and performance page fields. Supports partial updates. See docs/mcp-mapping-guide.md for field details.',
                      'properties': {
                        'cv': {
                          'type': 'object',
                          'description': 'CV mapping: source, cv_input (0-12), is_unipolar, is_gate, volts, delta',
                        },
                        'midi': {
                          'type': 'object',
                          'description':
                              'MIDI mapping: is_midi_enabled, midi_channel (0-15), midi_cc (0-128), midi_type (cc|note_momentary|note_toggle|cc_14bit_low|cc_14bit_high), is_midi_symmetric, is_midi_relative, midi_min, midi_max',
                        },
                        'i2c': {
                          'type': 'object',
                          'description': 'i2c mapping: is_i2c_enabled, i2c_cc (0-255), is_i2c_symmetric, i2c_min, i2c_max',
                        },
                        'performance_page': {
                          'type': 'integer',
                          'description': 'Performance page index (0=not assigned, 1-15=page number)',
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
        required: ['target'],
      ),
      callback: ({args, extra}) async {
        final target = args?['target'] as String?;
        String resultJson;

        if (target == 'preset') {
          // Edit entire preset
          resultJson = await tools.editPreset(args ?? {});
        } else if (target == 'slot' || target == 'parameter') {
          // Edit slot or parameter
          resultJson = await tools.editSlot(args ?? {});
        } else {
          resultJson = jsonEncode({
            'success': false,
            'error': 'Invalid target. Must be "preset", "slot", or "parameter"',
          });
        }

        return CallToolResult.fromContent(
          content: [TextContent(text: resultJson)],
        );
      },
    );
  }

  void _registerUtilityTools(McpServer server, DistingTools tools) {
    // Utility tools can be added here as needed
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
