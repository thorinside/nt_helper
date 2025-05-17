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
          'Retrieves full metadata for a specific algorithm by its GUID. IMPORTANT: The order of parameters in this tool\'s output may NOT correspond to the `parameter_index` required by `setParameterValue` or `getParameterValue`. Use `getCurrentPreset` to find the correct live `parameterNumber` (which is used as `parameter_index`).',
      inputSchemaProperties: {
        'guid': {
          'type': 'string',
          'description':
              'Algorithm GUID. Must be a valid GUID discoverable via `list_algorithms` or `find_algorithms` (see nt_helper_mcp.mdc for details on GUID validity).'
        },
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
          'Returns a list of available algorithms, optionally filtered. The GUIDs returned by this tool are the valid identifiers to be used with tools like `addAlgorithm` and `get_algorithm_details`.',
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
      description:
          'Performs text search across algorithm metadata. The GUIDs found can be used with tools like `addAlgorithm` and `get_algorithm_details`.',
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
          'Retrieves the current routing state decoded into RoutingInformation objects. Interpreting this state relies on understanding Disting NT Bus numbering: Physical Inputs 1-12 are Bus 1-12; Physical Outputs 1-8 are Bus 13-20; Aux Channels 1-8 are Bus 21-28. Bus 0 means "None/Not Connected". For stereo signals, if an algorithm uses a single main bus parameter and a `Width=2` parameter, it implies Bus N for Left and N+1 for Right. Algorithms with distinct L/R parameters require both to be set explicitly.',
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
          'Gets the entire current preset state (name, slots, parameters). CRITICAL: Each parameter in the output includes a `parameterNumber` field; this `parameterNumber` is the value that MUST be used as the `parameter_index` for `setParameterValue` and `getParameterValue` tools. Empty slots in the preset are represented as null.',
      inputSchemaProperties: {
        'random_string': {
          'type': 'string',
          'description':
              'Dummy parameter for no-parameter tools. See nt_helper_mcp.mdc regarding the critical `parameterNumber` field in the output of this tool, used for identifying parameters in other operations.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.get_current_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'addAlgorithm',
      description:
          'Adds an algorithm to the first available empty slot. The `algorithm_guid` MUST be a valid GUID discoverable via `list_algorithms` or `find_algorithms`. The firmware determines the slot; this tool does not specify it.',
      inputSchemaProperties: {
        'algorithm_guid': {
          'type': 'string',
          'description':
              'GUID of the algorithm to add. MUST be a valid GUID discoverable via `list_algorithms` or `find_algorithms` (see nt_helper_mcp.mdc).'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.add_algorithm(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'removeAlgorithm',
      description:
          'Removes (clears) the algorithm from a specific slot. CRITICAL BEHAVIOR - SLOT SHIFTING: When an algorithm is removed from `slot_index N`, all subsequent algorithms shift down (e.g., algorithm at N+1 moves to N). The internal `algorithmIndex` (device MIDI reference) of the remaining algorithms will also be updated by the device.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description':
              '0-based index of the slot to clear. Note the slot shifting behavior detailed in nt_helper_mcp.mdc when an algorithm is removed.'
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
          'Sets the value of a specific parameter in a slot, using its display value. Handles `powerOfTen` scaling automatically. \nIMPORTANT `parameter_index` USAGE: The `parameter_index` MUST be the `parameterNumber` obtained from the `getCurrentPreset` tool for that specific parameter in the slot. DO NOT use the parameter order from `get_algorithm_details`.\nWORKFLOW: 1. Call `getCurrentPreset`. 2. Find your parameter by `name` in the correct slot. 3. Use its `parameterNumber` as `parameter_index` here.\nBUS PARAMETERS: For parameters assigning audio/CV paths, use Disting NT bus numbers: Phys Inputs 1-12 are Bus 1-12; Phys Outputs 1-8 are Bus 13-20; Aux 1-8 are Bus 21-28; Bus 0 is None. \nSTEREO BUS HANDLING: If an algorithm has a single main audio bus parameter (e.g., "Audio input") and a `Width=2` parameter, setting the main bus to N implies N for Left, N+1 for Right. For algorithms with distinct "Left input" and "Right input" parameters, both must be set explicitly (for mono, set both to the same source bus).',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description':
              '0-based index of the slot (0-31) containing the algorithm. See nt_helper_mcp.mdc for slot behaviors.'
        },
        'parameter_index': {
          'type': 'integer',
          'description':
              "CRITICAL: This MUST be the `parameterNumber` obtained from `getCurrentPreset` for the target parameter. DO NOT use ordering from `get_algorithm_details`. See nt_helper_mcp.mdc for full workflow."
        },
        'display_value': {
          'type': 'number', // Can be int or double (e.g., 5 or 2.5 for Hz)
          'description':
              'The human-readable display value (e.g., 5 for 5Hz). If this parameter assigns an audio/CV bus, use Disting NT bus numbers (0 for None, 1-12 for Inputs, etc. - see nt_helper_mcp.mdc for full mapping and stereo handling).'
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
          'Gets the current value of a specific parameter from the device. The `parameter_index` MUST be the `parameterNumber` obtained from the `getCurrentPreset` tool for that specific parameter in the slot.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description':
              '0-based index of the slot (0-31) containing the algorithm.'
        },
        'parameter_index': {
          'type': 'integer',
          'description':
              "The parameter\'s unique, 0-based device index. This MUST be the `parameterNumber` obtained from `getCurrentPreset`. See nt_helper_mcp.mdc."
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.get_parameter_value(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'setPresetName',
      description:
          'Sets the name of the currently loaded preset on the device. This change is in working memory and requires `savePreset` to persist it.',
      inputSchemaProperties: {
        'name': {
          'type': 'string',
          'description':
              'The new name for the preset. This change is in working memory; use `savePreset` to persist (see nt_helper_mcp.mdc).'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.set_preset_name(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'setSlotName',
      description:
          'Sets a custom name for the algorithm in a specific slot. This change is in working memory and requires `savePreset` to persist it.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description': '0-based index of the slot (0-31) to name.'
        },
        'name': {
          'type': 'string',
          'description':
              'The desired custom name for the slot. This change is in working memory; use `savePreset` to persist (see nt_helper_mcp.mdc).'
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
          'Tells the device to clear the current preset and start a new, empty one. This affects the working preset; any unsaved changes will be lost unless `savePreset` was used prior.',
      inputSchemaProperties: {
        // No specific parameters needed, but schema can be empty
        'random_string': {
          // Gemini seems to prefer at least one dummy param for no-arg tools
          'type': 'string',
          'description':
              'Dummy parameter (can be any string). This action clears the working preset; see nt_helper_mcp.mdc regarding persistence of changes via `savePreset`.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.new_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'savePreset',
      description:
          'Tells the device to save the current working preset, persisting all changes made to names, slots, and parameters.',
      inputSchemaProperties: {
        'random_string': {
          // Dummy parameter
          'type': 'string',
          'description':
              'Dummy parameter (can be any string). This action persists the current working preset state. See nt_helper_mcp.mdc.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.save_preset(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_up',
      description:
          'Moves an algorithm in a specified slot one position up in the slot list. The evaluation order of algorithms is from top to bottom (slot 0 to N). If an algorithm expects modulation from another, the modulating algorithm must appear in an earlier slot (lower index). Note: This may change the internal `algorithmIndex` (device MIDI reference) of the moved algorithm and the one it swapped with.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description':
              '0-based index of the slot containing the algorithm to move up. See nt_helper_mcp.mdc for notes on evaluation order and potential `algorithmIndex` changes.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.move_algorithm_up(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'move_algorithm_down',
      description:
          'Moves an algorithm in a specified slot one position down in the slot list. The evaluation order of algorithms is from top to bottom (slot 0 to N). If an algorithm expects modulation from another, the modulating algorithm must appear in an earlier slot (lower index). Note: This may change the internal `algorithmIndex` (device MIDI reference) of the moved algorithm and the one it swapped with.',
      inputSchemaProperties: {
        'slot_index': {
          'type': 'integer',
          'description':
              '0-based index of the slot containing the algorithm to move down. See nt_helper_mcp.mdc for notes on evaluation order and potential `algorithmIndex` changes.'
        }
      },
      callback: ({args, extra}) async {
        final resultJson = await _distingTools.move_algorithm_down(args ?? {});
        return CallToolResult(content: [TextContent(text: resultJson)]);
      },
    );

    server.tool(
      'get_module_screenshot',
      description:
          'Retrieves the current module screenshot as a base64 encoded string if connected to the hardware. Returns an error or specific message if not connected or screenshot is unavailable.',
      inputSchemaProperties: {
        'random_string': {
          // Dummy parameter for consistency if no real params needed
          'type': 'string',
          'description': 'Dummy parameter (can be any string).'
        }
      },
      callback: ({args, extra}) async {
        final Map<String, dynamic> result =
            await _distingTools.get_module_screenshot(args ?? {});
        if (result['success'] == true) {
          return CallToolResult(content: [
            ImageContent(
              // type: 'image', // The 'type' field is automatically set by the ImageContent constructor
              data: result['screenshot_base64'] as String,
              mimeType: 'image/png', // Our decodeBitmap ensures PNG
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
