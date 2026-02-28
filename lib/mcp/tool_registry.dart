import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:nt_helper/cubit/disting_cubit.dart';
import 'package:nt_helper/mcp/tools/algorithm_tools.dart';
import 'package:nt_helper/mcp/tools/disting_tools.dart';
import 'package:nt_helper/services/disting_controller.dart';
import 'package:nt_helper/services/disting_controller_impl.dart';

/// A single tool entry in the shared registry.
class ToolRegistryEntry {
  final String name;
  final String description;
  final Map<String, dynamic> inputSchema;
  final Future<String> Function(Map<String, dynamic> args) handler;
  final Duration timeout;

  const ToolRegistryEntry({
    required this.name,
    required this.description,
    required this.inputSchema,
    required this.handler,
    this.timeout = const Duration(seconds: 10),
  });
}

/// Shared registry of tool definitions consumed by both the MCP server
/// and the in-app chat's ToolBridgeService.
class ToolRegistry {
  final List<ToolRegistryEntry> _entries = [];
  late final DistingController _controller;
  late final MCPAlgorithmTools _algoTools;
  late final DistingTools _distingTools;

  ToolRegistry(DistingCubit distingCubit) {
    _controller = DistingControllerImpl(distingCubit);
    _algoTools = MCPAlgorithmTools(_controller, distingCubit);
    _distingTools = DistingTools(_controller, distingCubit);
    _registerAll();
  }

  List<ToolRegistryEntry> get entries => List.unmodifiable(_entries);

  ToolRegistryEntry? findByName(String name) {
    for (final entry in _entries) {
      if (entry.name == name) return entry;
    }
    return null;
  }

  /// Apply all registered tools to an MCP server instance.
  void applyToMcpServer(McpServer server) {
    for (final entry in _entries) {
      server.registerTool(
        entry.name,
        description: entry.description,
        inputSchema: ToolInputSchema.fromJson(
          _deepCastMap({
            'type': 'object',
            'properties': entry.inputSchema['properties'] ?? {},
            if (entry.inputSchema['required'] != null)
              'required': entry.inputSchema['required'],
          }),
        ),
        callback: (args, extra) async {
          try {
            final resultJson = await entry.handler(args).timeout(
              entry.timeout,
              onTimeout: () => jsonEncode({
                'success': false,
                'error':
                    'Tool execution timed out after ${entry.timeout.inSeconds} seconds',
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
  }

  /// Recursively cast Map literals to `Map<String, dynamic>` for mcp_dart.
  static Map<String, dynamic> _deepCastMap(Map map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepCastMap(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((e) => e is Map ? _deepCastMap(e) : e).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }

  void _registerAll() {
    _registerSearchTools();
    _registerShowTools();
    _registerEditTools();
    _registerPresetTools();
  }

  void _registerSearchTools() {
    _entries.add(ToolRegistryEntry(
      name: 'search_algorithms',
      description:
          'Search for algorithms by name/category. Uses fuzzy matching (70% threshold). Returns up to 10 results sorted by relevance.',
      inputSchema: {
        'properties': {
          'query': {
            'type': 'string',
            'description':
                'Search query: algorithm name, partial name, or category.',
          },
        },
        'required': ['query'],
      },
      handler: (args) async {
        final fullArgs = {...args, 'target': 'algorithm'};
        return await _algoTools.searchAlgorithms(fullArgs);
      },
      timeout: const Duration(seconds: 5),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'search_parameters',
      description:
          'Search for parameters by name within the current preset or a specific slot. Uses exact or partial name matching.',
      inputSchema: {
        'properties': {
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
        'required': ['query', 'scope'],
      },
      handler: (args) => _distingTools.searchParameters(args),
      timeout: const Duration(seconds: 5),
    ));
  }

  void _registerShowTools() {
    _entries.add(ToolRegistryEntry(
      name: 'show_preset',
      description:
          'Show the complete preset with all slots, parameters, and enabled mappings.',
      inputSchema: {'properties': {}},
      handler: (_) => _algoTools.showPreset(),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'show_slot',
      description:
          'Show a single slot with its algorithm, parameters, and enabled mappings.',
      inputSchema: {
        'properties': {
          'slot_index': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 31,
            'description': 'Slot index (0-31).',
          },
        },
        'required': ['slot_index'],
      },
      handler: (args) => _algoTools.showSlot(args['slot_index']),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'show_parameter',
      description:
          'Show a single parameter with its value, range, unit, and enabled mappings.',
      inputSchema: {
        'properties': {
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
        'required': ['slot_index', 'parameter'],
      },
      handler: (args) =>
          _algoTools.showParameterByIndex(args['slot_index'], args['parameter']),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'show_screen',
      description:
          'Capture and return the current device screen as a base64 JPEG image.',
      inputSchema: {
        'properties': {
          'display_mode': {
            'type': 'string',
            'description':
                'Optional display mode to switch to before capturing. Options: "parameter" (hardware parameter list), "algorithm" (custom algorithm interface), "overview" (all slots overview), "vu_meters" (VU meter display)',
            'enum': ['parameter', 'algorithm', 'overview', 'vu_meters'],
          },
        },
      },
      handler: (args) =>
          _algoTools.showScreen(displayMode: args['display_mode']),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'show_routing',
      description:
          'Show the current signal routing state with input/output bus assignments for all slots.',
      inputSchema: {'properties': {}},
      handler: (_) => _algoTools.showRouting(),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'show_cpu',
      description:
          'Show CPU usage for the device and per-slot usage breakdown.',
      inputSchema: {'properties': {}},
      handler: (_) => _algoTools.showCpu(),
    ));
  }

  void _registerEditTools() {
    _entries.add(ToolRegistryEntry(
      name: 'edit_preset',
      description:
          'Edit the entire preset state including name and all slots. WARNING: Replaces the full preset.',
      inputSchema: {
        'properties': {
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
        'required': ['data'],
      },
      handler: (args) =>
          _distingTools.editPreset({...args, 'target': 'preset'}),
      timeout: const Duration(seconds: 30),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'edit_slot',
      description:
          'Edit a specific slot: change algorithm, set parameters, or rename. Device must be in connected mode.',
      inputSchema: {
        'properties': {
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
        'required': ['slot_index', 'data'],
      },
      handler: (args) => _distingTools.editSlot({...args, 'target': 'slot'}),
      timeout: const Duration(seconds: 30),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'edit_parameter',
      description:
          'Edit a single parameter value and/or mapping. Device must be in connected mode.',
      inputSchema: {
        'properties': {
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
                    'Performance page index (0=not assigned, 1-30=page number)',
              },
            },
          },
        },
        'required': ['slot_index', 'parameter'],
      },
      handler: (args) => _distingTools.editParameter(args),
      timeout: const Duration(seconds: 15),
    ));
  }

  void _registerPresetTools() {
    _entries.add(ToolRegistryEntry(
      name: 'new',
      description:
          'Create new blank preset or preset with initial algorithms. WARNING: Clears current preset.',
      inputSchema: {
        'properties': {
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
        'required': ['name'],
      },
      handler: (args) => _distingTools.newWithAlgorithms(args),
      timeout: const Duration(seconds: 30),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'save',
      description: 'Save the current preset to the device.',
      inputSchema: {'properties': {}},
      handler: (args) => _distingTools.savePreset(args),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'add',
      description: 'Add an algorithm to the preset. Requires name or guid.',
      inputSchema: {
        'properties': {
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
            'description': 'Insert position (0-31). Omit for first empty slot.',
          },
          'specifications': {
            'type': 'array',
            'items': {'type': 'integer'},
            'description':
                'Specification values for algorithms that require them (e.g., channel count, max delay time).',
          },
        },
      },
      handler: (args) =>
          _distingTools.addSimple({...args, 'target': 'algorithm'}),
      timeout: const Duration(seconds: 30),
    ));

    _entries.add(ToolRegistryEntry(
      name: 'remove',
      description:
          'Remove the algorithm from a slot, leaving it empty. Succeeds gracefully if slot is already empty.',
      inputSchema: {
        'properties': {
          'target': {
            'type': 'string',
            'enum': ['slot'],
            'description': 'Must be "slot".',
          },
          'slot_index': {
            'type': 'integer',
            'description': 'Slot index to clear (0-31).',
          },
        },
        'required': ['slot_index'],
      },
      handler: (args) =>
          _distingTools.removeSlot({...args, 'target': 'slot'}),
    ));
  }
}
