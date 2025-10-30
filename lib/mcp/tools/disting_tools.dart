import 'dart:convert';
import 'dart:math'; // For min, pow functions
import 'dart:typed_data'; // Added for Uint8List

import 'package:image/image.dart' as img; // For image processing
import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show Algorithm, ParameterInfo;
// Re-added for Algorithm, ParameterInfo etc.
import 'package:nt_helper/services/algorithm_metadata_service.dart';
import 'package:nt_helper/services/disting_controller.dart';
import 'package:nt_helper/util/case_converter.dart';
import 'package:nt_helper/mcp/mcp_constants.dart';
import 'package:nt_helper/models/cpu_usage.dart';

/// Defines MCP tools for interacting with the Disting state (presets, slots, parameters)
/// via the DistingController.
class DistingTools {
  final DistingController _controller;

  // Use shared constants
  final int maxSlots = MCPConstants.maxSlots;

  DistingTools(this._controller);

  // Use shared utility
  num _scaleForDisplay(int value, int? powerOfTen) =>
      MCPUtils.scaleForDisplay(value, powerOfTen);

  /// Retrieves enum values for a parameter if it's an enum type
  Future<List<String>?> _getParameterEnumValues(
    int slotIndex,
    int parameterNumber,
  ) async {
    try {
      // Get algorithm from slot
      final algorithm = await _controller.getAlgorithmInSlot(slotIndex);
      if (algorithm == null) return null;

      // Get enum strings from controller
      final enumStrings = await _controller.getParameterEnumStrings(
        slotIndex,
        parameterNumber,
      );
      return enumStrings?.values;
    } catch (e) {
      return null;
    }
  }

  /// Checks if a parameter is an enum type
  bool _isEnumParameter(ParameterInfo paramInfo) {
    return paramInfo.unit == 1;
  }

  /// Converts enum string to integer index
  int? _enumStringToIndex(List<String> enumValues, String value) {
    final index = enumValues.indexOf(value);
    return index >= 0 ? index : null;
  }

  /// Converts integer index to enum string
  String? _enumIndexToString(List<String> enumValues, int index) {
    if (index >= 0 && index < enumValues.length) {
      return enumValues[index];
    }
    return null;
  }

  /// MCP Tool: Gets the entire current preset state.
  /// Parameters: None
  /// Returns:
  ///   A JSON string representing the current preset including name,
  ///   and details for each slot (algorithm and parameters).
  Future<String> getCurrentPreset(Map<String, dynamic> params) async {
    try {
      final presetName = await _controller.getCurrentPresetName();
      final Map<int, Algorithm?> slotAlgorithms = await _controller
          .getAllSlots();

      List<Map<String, dynamic>?> slotsJsonList = List.filled(maxSlots, null);

      for (int i = 0; i < maxSlots; i++) {
        final algorithm = slotAlgorithms[i];
        if (algorithm != null) {
          // To get parameters, we need to call getParametersForSlot for each non-empty slot
          final List<ParameterInfo> parameterInfos = await _controller
              .getParametersForSlot(i);

          List<Map<String, dynamic>> parametersJsonList = [];
          for (
            int paramIndex = 0;
            paramIndex < parameterInfos.length;
            paramIndex++
          ) {
            final pInfo = parameterInfos[paramIndex];
            final int? liveRawValue = await _controller.getParameterValue(
              i,
              paramIndex,
            );

            // Build base parameter object
            final paramData = {
              'parameter_number': paramIndex,
              'name': pInfo.name,
              'min_value': _scaleForDisplay(
                pInfo.min,
                pInfo.powerOfTen,
              ), // Scaled
              'max_value': _scaleForDisplay(
                pInfo.max,
                pInfo.powerOfTen,
              ), // Scaled
              'default_value': _scaleForDisplay(
                pInfo.defaultValue,
                pInfo.powerOfTen,
              ), // Scaled
              'unit': pInfo.unit,
              'value': liveRawValue != null
                  ? _scaleForDisplay(liveRawValue, pInfo.powerOfTen)
                  : null, // Scaled
            };

            // Add enum metadata if this is an enum parameter
            if (_isEnumParameter(pInfo)) {
              final enumValues = await _getParameterEnumValues(i, paramIndex);
              if (enumValues != null) {
                paramData['is_enum'] = true;
                paramData['enum_values'] = enumValues;
                if (liveRawValue != null) {
                  paramData['enum_value'] = _enumIndexToString(
                    enumValues,
                    liveRawValue,
                  );
                }
              }
            }

            // Add mapping information (performance page, MIDI, CV, etc.)
            try {
              final mapping = await _controller.getParameterMapping(
                i,
                paramIndex,
              );
              if (mapping != null) {
                final perfPageIndex = mapping.packedMappingData.perfPageIndex;
                if (perfPageIndex > 0) {
                  paramData['performance_page'] = perfPageIndex;
                }
              }
            } catch (e) {
              // Intentionally empty
            }

            parametersJsonList.add(paramData);
          }

          slotsJsonList[i] = {
            'slot_index': i,
            'algorithm': {
              'guid': algorithm.guid,
              'name': algorithm.name,
              'algorithm_index': algorithm.algorithmIndex,
            },
            'parameters': parametersJsonList,
          };
        }
      }

      final Map<String, dynamic> presetData = _buildPresetJson(
        presetName,
        slotsJsonList,
      );
      return jsonEncode(
        convertToSnakeCaseKeys(presetData),
      ); // Apply converter here
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  Map<String, dynamic> _buildPresetJson(
    String presetName,
    List<Map<String, dynamic>?> slotsData,
  ) {
    return {'preset_name': presetName, 'slots': slotsData};
  }

  /// MCP Tool: Adds an algorithm to the first available slot (determined by hardware).
  /// Parameters:
  ///   - algorithm_guid (string, required): The GUID of the algorithm to add.
  /// Returns:
  ///   A JSON string confirming the addition or an error.
  Future<String> addAlgorithm(Map<String, dynamic> params) async {
    final String? algorithmGuid = params['algorithm_guid'];
    final String? algorithmName = params['algorithm_name'];

    // Use shared algorithm resolver
    final algorithms = AlgorithmMetadataService().getAllAlgorithms();
    final resolution = AlgorithmResolver.resolveAlgorithm(
      guid: algorithmGuid,
      algorithmName: algorithmName,
      allAlgorithms: algorithms,
    );

    if (!resolution.isSuccess) {
      return jsonEncode(convertToSnakeCaseKeys(resolution.error!));
    }

    try {
      final algoStub = Algorithm(
        algorithmIndex: -1,
        guid: resolution.resolvedGuid!,
        name: '',
      );

      await _controller.addAlgorithm(algoStub);

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Algorithm ${resolution.resolvedGuid!} added to slot',
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Removes (clears) the algorithm from a specific slot.
  /// Parameters:
  ///   - slot_index (int, required): The index of the slot to clear.
  /// Returns:
  ///   A JSON string confirming the removal or an error.
  Future<String> removeAlgorithm(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'];
    if (slotIndex == null) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            '${MCPConstants.missingParamError}: "slot_index"',
          ),
        ),
      );
    }

    try {
      await _controller.clearSlot(slotIndex);
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess('Algorithm removed from slot $slotIndex'),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  // Updated method to set parameter value, handling display_value and powerOfTen
  Future<String> setParameterValue(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final int? parameterNumberParam = params['parameter_number'] as int?;
    final String? parameterNameParam = params['parameter_name'] as String?;
    final dynamic value = params['value']; // Can be num or String for enums

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    // Validate value parameter
    final valueError = MCPUtils.validateRequiredParam(value, 'value');
    if (valueError != null) {
      return jsonEncode(convertToSnakeCaseKeys(valueError));
    }

    // Validate exactly one of parameter_number or parameter_name
    final paramError = MCPUtils.validateExactlyOne(params, [
      'parameter_number',
      'parameter_name',
    ], helpCommand: MCPConstants.getPresetHelp);
    if (paramError != null) {
      return jsonEncode(convertToSnakeCaseKeys(paramError));
    }

    try {
      final List<ParameterInfo> paramInfos = await _controller
          .getParametersForSlot(slotIndex!);

      int? targetParameterNumber;
      ParameterInfo? paramInfo;

      if (parameterNumberParam != null) {
        if (parameterNumberParam >= paramInfos.length ||
            parameterNumberParam < 0) {
          return jsonEncode(
            convertToSnakeCaseKeys(
              MCPUtils.buildError(
                'Parameter number $parameterNumberParam is out of bounds for slot $slotIndex.',
              ),
            ),
          );
        }
        targetParameterNumber = parameterNumberParam;
        paramInfo = paramInfos[targetParameterNumber];
      } else if (parameterNameParam != null) {
        final matchingParams = paramInfos
            .where(
              (p) => p.name.toLowerCase() == parameterNameParam.toLowerCase(),
            )
            .toList();

        if (matchingParams.isEmpty) {
          return jsonEncode(
            convertToSnakeCaseKeys(
              MCPUtils.buildError(
                'Parameter with name "$parameterNameParam" not found in slot $slotIndex. Check `get_current_preset` for available parameters.',
              ),
            ),
          );
        }
        if (matchingParams.length > 1) {
          return jsonEncode(
            convertToSnakeCaseKeys(
              MCPUtils.buildError(
                'Parameter name "$parameterNameParam" is ambiguous in slot $slotIndex. Please use "parameter_number". Check `get_current_preset` for details.',
              ),
            ),
          );
        }
        paramInfo = matchingParams.first;
        // We need to find the original index (parameterNumber) of this paramInfo
        targetParameterNumber = paramInfos.indexOf(paramInfo);
      }

      if (paramInfo == null || targetParameterNumber == null) {
        // Should not happen if logic above is correct
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError('Failed to identify target parameter.'),
          ),
        );
      }

      // Handle enum parameter value conversion
      int rawValue;
      if (_isEnumParameter(paramInfo)) {
        if (value is String) {
          // Convert enum string to index
          final enumValues = await _getParameterEnumValues(
            slotIndex,
            targetParameterNumber,
          );
          if (enumValues == null) {
            return jsonEncode(
              convertToSnakeCaseKeys(
                MCPUtils.buildError(
                  'Could not retrieve enum values for parameter ${paramInfo.name}',
                ),
              ),
            );
          }

          final enumIndex = _enumStringToIndex(enumValues, value);
          if (enumIndex == null) {
            return jsonEncode(
              convertToSnakeCaseKeys(
                MCPUtils.buildError(
                  'Invalid enum value "$value" for parameter ${paramInfo.name}. Valid values: ${enumValues.join(", ")}',
                ),
              ),
            );
          }
          rawValue = enumIndex;
        } else if (value is num) {
          // Use numeric value directly
          rawValue = value.round();
        } else {
          return jsonEncode(
            convertToSnakeCaseKeys(
              MCPUtils.buildError(
                'Enum parameter ${paramInfo.name} requires either a string enum value or numeric index',
              ),
            ),
          );
        }
      } else {
        // Handle non-enum parameters as before
        if (value is! num) {
          return jsonEncode(
            convertToSnakeCaseKeys(
              MCPUtils.buildError(
                'Non-enum parameter ${paramInfo.name} requires a numeric value',
              ),
            ),
          );
        }

        if (paramInfo.powerOfTen > 0) {
          rawValue = (value * pow(10, paramInfo.powerOfTen)).round();
        } else {
          rawValue = value.round();
        }
      }

      if (rawValue < paramInfo.min || rawValue > paramInfo.max) {
        final effectiveMin = _scaleForDisplay(
          paramInfo.min,
          paramInfo.powerOfTen,
        );
        final effectiveMax = _scaleForDisplay(
          paramInfo.max,
          paramInfo.powerOfTen,
        );
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Provided value $value (scaled to $rawValue) is out of range for parameter ${paramInfo.name} (effective range: $effectiveMin to $effectiveMax, raw range: ${paramInfo.min} to ${paramInfo.max}).',
            ),
          ),
        );
      }

      await _controller.updateParameterValue(
        slotIndex,
        targetParameterNumber,
        rawValue,
      );

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Parameter ${paramInfo.name} (number $targetParameterNumber) in slot $slotIndex set to $value.',
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Gets the value of a specific parameter.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  ///   - parameter_number (int, required): The 0-based index of the parameter within the algorithm.
  /// Returns:
  ///   A JSON string with the parameter value or an error.
  Future<String> getParameterValue(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final int? parameterNumber = params['parameter_number'] as int?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    // Validate parameter number
    final paramError = MCPUtils.validateRequiredParam(
      parameterNumber,
      'parameter_number',
    );
    if (paramError != null) {
      return jsonEncode(convertToSnakeCaseKeys(paramError));
    }

    try {
      final int? liveRawValue = await _controller.getParameterValue(
        slotIndex!,
        parameterNumber!,
      );

      if (liveRawValue == null) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Could not retrieve value for parameter $parameterNumber in slot $slotIndex.',
            ),
          ),
        );
      }

      // Fetch parameter info to get powerOfTen for scaling
      final List<ParameterInfo> paramInfos = await _controller
          .getParametersForSlot(slotIndex);
      if (parameterNumber >= paramInfos.length || parameterNumber < 0) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Parameter number $parameterNumber is out of bounds for slot $slotIndex (for scaling info).',
            ),
          ),
        );
      }
      final ParameterInfo paramInfo = paramInfos[parameterNumber];

      final responseData = {
        'slot_index': slotIndex,
        'parameter_number': parameterNumber,
        'parameter_name': paramInfo.name,
        'value': _scaleForDisplay(
          liveRawValue,
          paramInfo.powerOfTen,
        ), // Scaled value
      };

      // Add enum metadata if applicable
      if (_isEnumParameter(paramInfo)) {
        final enumValues = await _getParameterEnumValues(
          slotIndex,
          parameterNumber,
        );
        if (enumValues != null) {
          responseData['is_enum'] = true;
          responseData['enum_values'] = enumValues;
          responseData['enum_value'] =
              _enumIndexToString(enumValues, liveRawValue) ?? '';
        }
      }

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Parameter value retrieved successfully',
            data: responseData,
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Sets the name of the current preset.
  /// Parameters:
  ///   - name (string, required): The new name for the preset.
  /// Returns:
  ///   A JSON string confirming the action or an error.
  Future<String> setPresetName(Map<String, dynamic> params) async {
    final String? name = params['name'] as String?;

    // Validate name parameter
    final nameError = MCPUtils.validateRequiredParam(name, 'name');
    if (nameError != null) {
      return jsonEncode(convertToSnakeCaseKeys(nameError));
    }

    try {
      await _controller.setPresetName(name!);
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess('Preset name set to "$name".'),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Sets the custom name for an algorithm in a specific slot.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  ///   - name (string, required): The desired custom name.
  /// Returns:
  ///   A JSON string confirming the action or an error.
  Future<String> setSlotName(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final String? name = params['name'] as String?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    // Validate name parameter
    final nameError = MCPUtils.validateRequiredParam(name, 'name');
    if (nameError != null) {
      return jsonEncode(convertToSnakeCaseKeys(nameError));
    }

    try {
      await _controller.setSlotName(slotIndex!, name!);
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess('Name for slot $slotIndex set to "$name".'),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Tells the device to clear the current preset and start a new, empty one.
  /// Parameters: None (can accept a dummy string for consistency if MCP requires it).
  /// Returns: A JSON string confirming the action or an error.
  Future<String> newPreset(Map<String, dynamic> params) async {
    try {
      await _controller.newPreset();
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess('New empty preset initiated on the device.'),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Tells the device to save the current working preset.
  /// Parameters: None (can accept a dummy string for consistency if MCP requires it).
  /// Returns: A JSON string confirming the action or an error.
  Future<String> savePreset(Map<String, dynamic> params) async {
    try {
      await _controller.savePreset();
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Request to save current preset sent to the device.',
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Moves an algorithm in a specified slot one position up in the slot list.
  /// The evaluation order of algorithms is from top to bottom (slot 0 to N).
  /// If an algorithm expects modulation from another, the modulating algorithm
  /// must appear in an earlier slot (lower index).
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot to move up.
  /// Returns:
  ///   A JSON string confirming the move or an error.
  Future<String> moveAlgorithmUp(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    if (slotIndex == 0) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Cannot move algorithm in slot 0 further up.'),
        ),
      );
    }
    // Ensure slotIndex is within a reasonable range if needed, though controller might handle this.
    // For now, just check against 0. Max slot check can be added if necessary or rely on controller.

    final int sourceSlotIndex = slotIndex!;

    try {
      await _controller.moveAlgorithmUp(sourceSlotIndex);
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Algorithm from slot $sourceSlotIndex moved up.',
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Moves an algorithm in a specified slot one position down in the slot list.
  /// The evaluation order of algorithms is from top to bottom (slot 0 to N).
  /// If an algorithm expects modulation from another, the modulating algorithm
  /// must appear in an earlier slot (lower index).
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot to move down.
  /// Returns:
  ///   A JSON string confirming the move or an error.
  Future<String> moveAlgorithmDown(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    // Assuming maxSlots is available or a way to check upper bound exists.
    // For simplicity, we'll rely on the controller to handle upper boundary errors if any.
    // A check like `if (slotIndex >= maxSlots - 1)` could be added.
    // For now, we'll assume maxSlots is dynamic or handled by the controller.

    final int sourceSlotIndex = slotIndex!;

    try {
      // Check if sourceSlotIndex is already the last possible slot.
      // This requires knowing the total number of slots, which is `maxSlots`.
      if (sourceSlotIndex >= maxSlots - 1) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Cannot move algorithm in slot ${maxSlots - 1} further down.',
            ),
          ),
        );
      }
      await _controller.moveAlgorithmDown(sourceSlotIndex);
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Algorithm from slot $sourceSlotIndex moved down.',
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Moves an algorithm to a specified direction or position.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot to move.
  ///   - direction (string, required): Direction to move ('up' or 'down').
  ///   - steps (int, optional): Number of steps to move (default: 1).
  /// Returns:
  ///   A JSON string confirming the move or an error.
  Future<String> moveAlgorithm(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final String? direction = params['direction'] as String?;
    final int steps = (params['steps'] as int?) ?? 1;

    // Validate required parameters
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    final directionError = MCPUtils.validateRequiredParam(
      direction,
      'direction',
    );
    if (directionError != null) {
      return jsonEncode(convertToSnakeCaseKeys(directionError));
    }

    // Validate direction parameter
    if (direction != 'up' && direction != 'down') {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Invalid direction. Must be "up" or "down".'),
        ),
      );
    }

    // Validate steps parameter
    if (steps < 1) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Steps must be at least 1.'),
        ),
      );
    }

    final int sourceSlotIndex = slotIndex!;

    try {
      // Perform multiple move operations
      for (int i = 0; i < steps; i++) {
        if (direction == 'up') {
          // Check if we're already at the top
          if (sourceSlotIndex - i <= 0) {
            return jsonEncode(
              convertToSnakeCaseKeys(
                MCPUtils.buildError(
                  'Cannot move algorithm further up. Already at or above slot 0.',
                ),
              ),
            );
          }
          await _controller.moveAlgorithmUp(sourceSlotIndex - i);
        } else {
          // direction == 'down'
          // Check if we're already at the bottom
          if (sourceSlotIndex + i >= maxSlots - 1) {
            return jsonEncode(
              convertToSnakeCaseKeys(
                MCPUtils.buildError(
                  'Cannot move algorithm further down. Already at or below slot ${maxSlots - 1}.',
                ),
              ),
            );
          }
          await _controller.moveAlgorithmDown(sourceSlotIndex + i);
        }
      }

      final String stepText = steps == 1 ? 'step' : 'steps';
      final int finalSlot = direction == 'up'
          ? sourceSlotIndex - steps
          : sourceSlotIndex + steps;
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Algorithm moved $steps $stepText $direction from slot $sourceSlotIndex to slot $finalSlot.',
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Retrieves the current module screenshot data.
  /// Parameters: None
  /// Returns:
  ///   A Map containing success status, and either base64 encoded screenshot_base64
  ///   and format, or an error message.
  Future<Map<String, dynamic>> getModuleScreenshot(
    Map<String, dynamic> params,
  ) async {
    try {
      final Uint8List? pngBytesFromController = await _controller
          .getModuleScreenshot(); // Assumed to be PNG bytes

      if (pngBytesFromController != null && pngBytesFromController.isNotEmpty) {
        // 1. Decode PNG bytes (directly from controller) into an Image object
        final img.Image? image = img.decodeImage(pngBytesFromController);

        if (image != null) {
          // 2. Encode the Image object to JPEG bytes
          final Uint8List jpegBytes = img.encodeJpg(image);

          if (jpegBytes.isNotEmpty) {
            final String base64Image = base64Encode(jpegBytes);
            return {
              'success': true,
              'screenshot_base64': base64Image,
              'format': 'jpeg', // Format is JPEG
            };
          } else {
            return {
              'success': false,
              'error': 'Failed to encode screenshot to JPEG after decoding.',
            };
          }
        } else {
          return {
            'success': false,
            'error':
                'Failed to decode PNG bytes (from controller) into an image object.',
          };
        }
      } else {
        return {
          'success': false,
          'error':
              'Module screenshot is currently unavailable (controller returned null/empty) or device not connected.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception in get_module_screenshot: ${e.toString()}',
      };
    }
  }

  /// MCP Tool: Retrieves the current CPU usage information from the device.
  /// Parameters: None
  /// Returns:
  ///   A JSON string with CPU usage data including overall CPU1 and CPU2 usage
  ///   percentages and per-slot usage information, or an error message.
  Future<String> getCpuUsage(Map<String, dynamic> params) async {
    try {
      final CpuUsage? cpuUsage = await _controller.getCpuUsage();

      if (cpuUsage != null) {
        // Build slot usage details
        final List<Map<String, dynamic>> slotUsageList = [];
        for (int i = 0; i < cpuUsage.slotUsages.length; i++) {
          slotUsageList.add({
            'slot_index': i,
            'usage_percentage': cpuUsage.slotUsages[i],
          });
        }

        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildSuccess(
              'CPU usage retrieved successfully',
              data: {
                'cpu1_percentage': cpuUsage.cpu1,
                'cpu2_percentage': cpuUsage.cpu2,
                'total_slots': cpuUsage.slotUsages.length,
                'slot_usage': slotUsageList,
              },
            ),
          ),
        );
      } else {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'CPU usage data is currently unavailable. Device may not be connected or synchronized.',
            ),
          ),
        );
      }
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Error retrieving CPU usage: ${e.toString()}'),
        ),
      );
    }
  }

  /// MCP Tool: Sets notes text by adding/updating a Notes algorithm and moving it to slot 0.
  /// Parameters:
  ///   - text (string, required): The note text content (max 7 lines, 31 characters each).
  /// Returns:
  ///   A JSON string confirming the action or an error.
  Future<String> setNotes(Map<String, dynamic> params) async {
    final String? text = params['text'];

    // Validate text parameter
    final textError = MCPUtils.validateRequiredParam(text, 'text');
    if (textError != null) {
      return jsonEncode(convertToSnakeCaseKeys(textError));
    }

    try {
      // Split and validate text using the same logic as NotesAlgorithmView
      final lines = _splitTextIntoLines(text!);

      if (!_validateNotesText(lines)) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Text validation failed. Maximum 7 lines of 31 characters each.',
            ),
          ),
        );
      }

      // Find existing Notes algorithm or add one
      final notesSlotIndex = await _findOrAddNotesAlgorithm();

      if (notesSlotIndex == null) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError('Failed to create Notes algorithm.'),
          ),
        );
      }

      // Set text parameters (parameters 1-7)
      for (int i = 0; i < 7; i++) {
        final lineText = i < lines.length ? lines[i] : '';
        await _controller.updateParameterString(
          notesSlotIndex,
          i + 1, // Parameters 1-7, not 0-6
          lineText,
        );
      }

      // Move Notes algorithm to slot 0 if it's not already there
      if (notesSlotIndex != 0) {
        int currentSlotIndex = notesSlotIndex;
        while (currentSlotIndex > 0) {
          await _controller.moveAlgorithmUp(currentSlotIndex);
          currentSlotIndex--;
        }
      }

      // Refresh slot 0 to ensure UI is updated with the latest notes content
      await _controller.refreshSlot(0);

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Notes algorithm updated with text and moved to slot 0.',
            data: {'lines_set': lines.length},
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// MCP Tool: Gets the current notes content from the Notes algorithm if it exists.
  /// Parameters: None
  /// Returns:
  ///   A JSON string with the notes content or an error if no notes exist.
  Future<String> getNotes(Map<String, dynamic> params) async {
    try {
      const String notesGuid = 'note';

      // Find Notes algorithm in any slot
      final Map<int, Algorithm?> allSlots = await _controller.getAllSlots();
      int? notesSlotIndex;

      for (int i = 0; i < maxSlots; i++) {
        final algorithm = allSlots[i];
        if (algorithm != null && algorithm.guid == notesGuid) {
          notesSlotIndex = i;
          break;
        }
      }

      if (notesSlotIndex == null) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'No Notes algorithm found in current preset',
              helpCommand: 'Use `set_notes` to create notes',
            ),
          ),
        );
      }

      // Get the notes content from parameters 1-7
      final List<String> lines = [];
      for (int i = 1; i <= 7; i++) {
        final String? lineContent = await _controller.getParameterStringValue(
          notesSlotIndex,
          i,
        );
        if (lineContent != null && lineContent.isNotEmpty) {
          lines.add(lineContent);
        }
      }

      // Join lines with newline characters
      final String notesText = lines.join('\n');

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Notes content retrieved successfully',
            data: {
              'slot_index': notesSlotIndex,
              'text': notesText,
              'lines': lines,
              'line_count': lines.length,
            },
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Error retrieving notes: ${e.toString()}'),
        ),
      );
    }
  }

  /// MCP Tool: Gets the current preset name.
  /// Parameters: None
  /// Returns:
  ///   A JSON string with the preset name or an error.
  Future<String> getPresetName(Map<String, dynamic> params) async {
    try {
      final String presetName = await _controller.getCurrentPresetName();

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Preset name retrieved successfully',
            data: {'preset_name': presetName},
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Error retrieving preset name: ${e.toString()}'),
        ),
      );
    }
  }

  /// MCP Tool: Gets the custom name for an algorithm in a specific slot.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  /// Returns:
  ///   A JSON string with the slot name or an error.
  Future<String> getSlotName(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    try {
      final String? slotName = await _controller.getSlotName(slotIndex!);

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Slot name retrieved successfully',
            data: {'slot_index': slotIndex, 'slot_name': slotName ?? ''},
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Error retrieving slot name: ${e.toString()}'),
        ),
      );
    }
  }

  /// MCP Tool: Finds if a specific algorithm exists in the current preset.
  /// Parameters:
  ///   - algorithm_guid (string): The unique identifier of the algorithm.
  ///   - algorithm_name (string): The name of the algorithm.
  /// Returns:
  ///   A JSON string with algorithm location or an error if not found.
  Future<String> findAlgorithmInPreset(Map<String, dynamic> params) async {
    final String? algorithmGuid = params['algorithm_guid'];
    final String? algorithmName = params['algorithm_name'];

    // Validate exactly one of algorithm_guid or algorithm_name
    final paramError = MCPUtils.validateExactlyOne(params, [
      'algorithm_guid',
      'algorithm_name',
    ], helpCommand: MCPConstants.getAlgorithmHelp);
    if (paramError != null) {
      return jsonEncode(convertToSnakeCaseKeys(paramError));
    }

    try {
      // Use shared algorithm resolver to get the target GUID
      final algorithms = AlgorithmMetadataService().getAllAlgorithms();
      final resolution = AlgorithmResolver.resolveAlgorithm(
        guid: algorithmGuid,
        algorithmName: algorithmName,
        allAlgorithms: algorithms,
      );

      if (!resolution.isSuccess) {
        return jsonEncode(convertToSnakeCaseKeys(resolution.error!));
      }

      final String targetGuid = resolution.resolvedGuid!;

      // Search through all slots to find the algorithm
      final Map<int, Algorithm?> allSlots = await _controller.getAllSlots();
      final List<Map<String, dynamic>> foundSlots = [];

      for (int i = 0; i < maxSlots; i++) {
        final algorithm = allSlots[i];
        if (algorithm != null && algorithm.guid == targetGuid) {
          foundSlots.add({
            'slot_index': i,
            'algorithm_name': algorithm.name,
            'algorithm_guid': algorithm.guid,
            'algorithm_index': algorithm.algorithmIndex,
          });
        }
      }

      if (foundSlots.isEmpty) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Algorithm with GUID "$targetGuid" not found in current preset',
              helpCommand: 'Use `add_algorithm` to add it to the preset',
            ),
          ),
        );
      }

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Algorithm found in preset',
            data: {
              'algorithm_guid': targetGuid,
              'found_in_slots': foundSlots,
              'slot_count': foundSlots.length,
            },
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Error searching for algorithm: ${e.toString()}'),
        ),
      );
    }
  }

  /// MCP Tool: Sets multiple parameters for an algorithm in one operation.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  ///   - parameters (array, required): Array of parameter objects with parameter_number/parameter_name and value.
  /// Returns:
  ///   A JSON string with results for each parameter or an error.
  Future<String> setMultipleParameters(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final List<dynamic>? parameters = params['parameters'] as List<dynamic>?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    // Validate parameters array
    final paramError = MCPUtils.validateRequiredParam(parameters, 'parameters');
    if (paramError != null) {
      return jsonEncode(convertToSnakeCaseKeys(paramError));
    }

    if (parameters!.isEmpty) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Parameters array cannot be empty'),
        ),
      );
    }

    try {
      final List<Map<String, dynamic>> results = [];
      bool hasErrors = false;

      for (int i = 0; i < parameters.length; i++) {
        final param = parameters[i];
        if (param is! Map<String, dynamic>) {
          results.add({'error': 'Parameter at index $i must be an object'});
          hasErrors = true;
          continue;
        }

        final paramMap = param;
        final dynamic value =
            paramMap['value']; // Can be num or String for enums
        final int? parameterNumber = paramMap['parameter_number'] as int?;
        final String? parameterName = paramMap['parameter_name'] as String?;

        // Validate this parameter
        if (value == null) {
          results.add({'error': 'Missing "value" field'});
          hasErrors = true;
          continue;
        }

        if (parameterNumber == null && parameterName == null) {
          results.add({
            'error':
                'Must provide either "parameter_number" or "parameter_name"',
          });
          hasErrors = true;
          continue;
        }

        if (parameterNumber != null && parameterName != null) {
          results.add({
            'error':
                'Provide only one of "parameter_number" or "parameter_name"',
          });
          hasErrors = true;
          continue;
        }

        // Create individual parameter update request
        final Map<String, dynamic> individualParams = {
          'slot_index': slotIndex,
          'value': value,
        };
        if (parameterNumber != null) {
          individualParams['parameter_number'] = parameterNumber;
        } else {
          individualParams['parameter_name'] = parameterName!;
        }

        // Call the individual setParameterValue method
        final result = await setParameterValue(individualParams);
        final resultMap = jsonDecode(result) as Map<String, dynamic>;

        if (resultMap['success'] == true) {
          results.add({
            'parameter_number': parameterNumber,
            'parameter_name': parameterName,
            'value': value,
          });
        } else {
          results.add({'error': resultMap['error'] ?? 'Unknown error'});
          hasErrors = true;
        }
      }

      final successCount = results.where((r) => r.containsKey('value')).length;
      final totalCount = results.length;

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Batch parameter update completed',
            data: {
              'slot_index': slotIndex,
              'total_parameters': totalCount,
              'successful_updates': successCount,
              'failed_updates': totalCount - successCount,
              'has_errors': hasErrors,
              'results': results,
            },
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            'Error in batch parameter update: ${e.toString()}',
          ),
        ),
      );
    }
  }

  /// MCP Tool: Gets multiple parameter values for an algorithm in one operation.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  ///   - parameter_numbers (array, required): Array of parameter numbers to retrieve.
  /// Returns:
  ///   A JSON string with values for each parameter or an error.
  Future<String> getMultipleParameters(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final List<dynamic>? parameterNumbers =
        params['parameter_numbers'] as List<dynamic>?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    // Validate parameter_numbers array
    final paramError = MCPUtils.validateRequiredParam(
      parameterNumbers,
      'parameter_numbers',
    );
    if (paramError != null) {
      return jsonEncode(convertToSnakeCaseKeys(paramError));
    }

    if (parameterNumbers!.isEmpty) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError('Parameter numbers array cannot be empty'),
        ),
      );
    }

    try {
      final List<Map<String, dynamic>> results = [];
      bool hasErrors = false;

      for (int i = 0; i < parameterNumbers.length; i++) {
        final paramNum = parameterNumbers[i];
        if (paramNum is! int) {
          results.add({
            'parameter_number': paramNum,
            'error': 'Parameter number at index $i must be an integer',
          });
          hasErrors = true;
          continue;
        }

        // Call the individual getParameterValue method
        final Map<String, dynamic> individualParams = {
          'slot_index': slotIndex,
          'parameter_number': paramNum,
        };

        final result = await getParameterValue(individualParams);
        final resultMap = jsonDecode(result) as Map<String, dynamic>;

        if (resultMap['success'] == true) {
          results.add({
            'parameter_number': paramNum,
            'value': resultMap['value'],
          });
        } else {
          results.add({
            'parameter_number': paramNum,
            'error': resultMap['error'] ?? 'Unknown error',
          });
          hasErrors = true;
        }
      }

      final successCount = results.where((r) => r.containsKey('value')).length;
      final totalCount = results.length;

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Batch parameter retrieval completed',
            data: {
              'slot_index': slotIndex,
              'total_parameters': totalCount,
              'successful_retrievals': successCount,
              'failed_retrievals': totalCount - successCount,
              'has_errors': hasErrors,
              'results': results,
            },
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            'Error in batch parameter retrieval: ${e.toString()}',
          ),
        ),
      );
    }
  }

  /// MCP Tool: Build a complete preset from JSON data.
  /// Parameters:
  ///   - preset_data (object, required): JSON object with preset_name and slots array.
  ///   - clear_existing (bool, optional): Clear existing preset first (default: true).
  /// Returns:
  ///   A JSON string confirming preset creation or error details.
  Future<String> buildPresetFromJson(Map<String, dynamic> params) async {
    final Map<String, dynamic>? presetData =
        params['preset_data'] as Map<String, dynamic>?;
    final bool clearExisting = params['clear_existing'] ?? true;

    // Validate preset_data parameter
    final presetError = MCPUtils.validateRequiredParam(
      presetData,
      'preset_data',
    );
    if (presetError != null) {
      return jsonEncode(convertToSnakeCaseKeys(presetError));
    }

    try {
      // Validate preset structure
      if (!presetData!.containsKey('preset_name')) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError('preset_data must contain "preset_name" field'),
          ),
        );
      }

      if (!presetData.containsKey('slots') || presetData['slots'] is! List) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError('preset_data must contain "slots" array'),
          ),
        );
      }

      final String presetName = presetData['preset_name'].toString();
      final List<dynamic> slots = presetData['slots'] as List<dynamic>;

      // Clear existing preset if requested
      if (clearExisting) {
        await _controller.newPreset();
      }

      // Set preset name
      await _controller.setPresetName(presetName);

      final List<Map<String, dynamic>> results = [];
      int successCount = 0;
      int errorCount = 0;

      // Process each slot
      for (
        int slotIndex = 0;
        slotIndex < slots.length && slotIndex < maxSlots;
        slotIndex++
      ) {
        final slotData = slots[slotIndex];

        if (slotData == null) {
          continue; // Skip empty slots
        }

        if (slotData is! Map<String, dynamic>) {
          results.add({
            'slot_index': slotIndex,
            'success': false,
            'error': 'Slot data must be an object',
          });
          errorCount++;
          continue;
        }

        try {
          // Process algorithm
          if (slotData.containsKey('algorithm')) {
            final algorithmData =
                slotData['algorithm'] as Map<String, dynamic>?;
            if (algorithmData != null) {
              final String? algorithmGuid = algorithmData['guid']?.toString();
              final String? algorithmName = algorithmData['name']?.toString();

              // Use AlgorithmResolver to find the algorithm
              final resolution = AlgorithmResolver.resolveAlgorithm(
                guid: algorithmGuid,
                algorithmName: algorithmName,
                allAlgorithms: [], // We'll need algorithm metadata here
              );

              if (resolution.isSuccess) {
                // Add algorithm (this will be added to the first available slot)
                final Map<String, dynamic> addParams = {
                  'algorithm_guid': resolution.resolvedGuid,
                };
                await addAlgorithm(addParams);

                // Process parameters if provided
                if (slotData.containsKey('parameters') &&
                    slotData['parameters'] is List) {
                  final List<dynamic> parameters =
                      slotData['parameters'] as List<dynamic>;
                  final List<Map<String, dynamic>> parameterList = [];

                  for (final param in parameters) {
                    if (param is Map<String, dynamic> &&
                        param.containsKey('value')) {
                      parameterList.add({
                        'parameter_number':
                            param['parameter_number'] ??
                            param['parameterNumber'],
                        'value': param['value'],
                      });
                    }
                  }

                  if (parameterList.isNotEmpty) {
                    final Map<String, dynamic> setParams = {
                      'slot_index': slotIndex,
                      'parameters': parameterList,
                    };
                    await setMultipleParameters(setParams);
                  }
                }

                results.add({
                  'slot_index': slotIndex,
                  'success': true,
                  'algorithm_guid': resolution.resolvedGuid,
                  'parameters_set': slotData.containsKey('parameters')
                      ? (slotData['parameters'] as List).length
                      : 0,
                });
                successCount++;
              } else {
                results.add({
                  'slot_index': slotIndex,
                  'success': false,
                  'error':
                      'Failed to resolve algorithm: ${resolution.error!['error']}',
                });
                errorCount++;
              }
            }
          }
        } catch (e) {
          results.add({
            'slot_index': slotIndex,
            'success': false,
            'error': 'Error processing slot: ${e.toString()}',
          });
          errorCount++;
        }
      }

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Preset built from JSON',
            data: {
              'preset_name': presetName,
              'total_slots_processed': results.length,
              'successful_slots': successCount,
              'failed_slots': errorCount,
              'cleared_existing': clearExisting,
              'results': results,
            },
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildError(
            'Error building preset from JSON: ${e.toString()}',
          ),
        ),
      );
    }
  }

  /// MCP Tool: Gets available enum values for an enum parameter
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot
  ///   - parameter_number (int, optional): The parameter number
  ///   - parameter_name (String, optional): The parameter name
  /// Returns:
  ///   A JSON string with enum values or an error
  Future<String> getParameterEnumValues(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final int? parameterNumber = params['parameter_number'] as int?;
    final String? parameterName = params['parameter_name'] as String?;

    // Validate slot index
    final slotError = MCPUtils.validateSlotIndex(slotIndex);
    if (slotError != null) {
      return jsonEncode(convertToSnakeCaseKeys(slotError));
    }

    // Validate exactly one of parameter_number or parameter_name
    final paramError = MCPUtils.validateExactlyOne(params, [
      'parameter_number',
      'parameter_name',
    ]);
    if (paramError != null) {
      return jsonEncode(convertToSnakeCaseKeys(paramError));
    }

    try {
      // Get parameter info to validate it's an enum
      final List<ParameterInfo> paramInfos = await _controller
          .getParametersForSlot(slotIndex!);

      // Find target parameter
      int? targetParamNumber;
      ParameterInfo? paramInfo;

      if (parameterNumber != null) {
        if (parameterNumber >= 0 && parameterNumber < paramInfos.length) {
          targetParamNumber = parameterNumber;
          paramInfo = paramInfos[parameterNumber];
        }
      } else if (parameterName != null) {
        // Find by name
        for (int i = 0; i < paramInfos.length; i++) {
          if (paramInfos[i].name.toLowerCase() == parameterName.toLowerCase()) {
            targetParamNumber = i;
            paramInfo = paramInfos[i];
            break;
          }
        }
      }

      if (paramInfo == null || targetParamNumber == null) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError('Parameter not found in slot $slotIndex'),
          ),
        );
      }

      if (!_isEnumParameter(paramInfo)) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Parameter ${paramInfo.name} is not an enum type',
            ),
          ),
        );
      }

      final enumValues = await _getParameterEnumValues(
        slotIndex,
        targetParamNumber,
      );

      if (enumValues == null || enumValues.isEmpty) {
        return jsonEncode(
          convertToSnakeCaseKeys(
            MCPUtils.buildError(
              'Could not retrieve enum values for parameter ${paramInfo.name}',
            ),
          ),
        );
      }

      return jsonEncode(
        convertToSnakeCaseKeys(
          MCPUtils.buildSuccess(
            'Enum values retrieved successfully',
            data: {
              'slot_index': slotIndex,
              'parameter_number': targetParamNumber,
              'parameter_name': paramInfo.name,
              'enum_values': enumValues,
              'current_value_index': await _controller.getParameterValue(
                slotIndex,
                targetParamNumber,
              ),
            },
          ),
        ),
      );
    } catch (e) {
      return jsonEncode(
        convertToSnakeCaseKeys(MCPUtils.buildError(e.toString())),
      );
    }
  }

  /// Helper method to split text into lines with same logic as NotesAlgorithmView
  List<String> _splitTextIntoLines(String text) {
    const int maxLinesCount = 7;
    const int maxLineLength = 31;
    final lines = <String>[];

    if (text.trim().isEmpty) {
      return lines;
    }

    // Split by user line breaks first
    final userLines = text.split('\n');

    for (final userLine in userLines) {
      // Stop if we've already reached the maximum number of lines
      if (lines.length >= maxLinesCount) {
        break;
      }

      // Clean up the current user line (collapse multiple spaces)
      final cleanLine = userLine.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleanLine.isEmpty) {
        // User entered an empty line - add it as empty
        lines.add('');
        continue;
      }

      // If the line fits within the character limit, add it as-is
      if (cleanLine.length <= maxLineLength) {
        lines.add(cleanLine);
      } else {
        // Line is too long, need to wrap it
        final words = cleanLine.split(' ');
        String currentLine = '';

        for (final word in words) {
          // Check if adding this word would exceed line length
          final testLine = currentLine.isEmpty ? word : '$currentLine $word';

          if (testLine.length <= maxLineLength) {
            currentLine = testLine;
          } else {
            // Current line is full, start a new one
            if (currentLine.isNotEmpty) {
              lines.add(currentLine);
              currentLine = word;
            } else {
              // Single word is too long, truncate it
              lines.add(word.substring(0, maxLineLength));
              currentLine = '';
            }

            // Stop if we've reached the maximum number of lines
            if (lines.length >= maxLinesCount) {
              break;
            }
          }
        }

        // Add the last line if it's not empty and we haven't exceeded max lines
        if (currentLine.isNotEmpty && lines.length < maxLinesCount) {
          lines.add(currentLine);
        }

        // Stop processing if we've reached the line limit
        if (lines.length >= maxLinesCount) {
          break;
        }
      }
    }

    return lines;
  }

  /// Helper method to validate notes text
  bool _validateNotesText(List<String> lines) {
    const int maxLinesCount = 7;
    const int maxLineLength = 31;

    // Check if we have too many lines
    if (lines.length > maxLinesCount) {
      return false;
    }

    // Check if any individual line exceeds the character limit
    for (final line in lines) {
      if (line.length > maxLineLength) {
        return false;
      }
    }

    return true;
  }

  /// Helper method to find existing Notes algorithm or add one
  Future<int?> _findOrAddNotesAlgorithm() async {
    const String notesGuid = 'note';

    // First, check if Notes algorithm already exists in any slot
    final Map<int, Algorithm?> allSlots = await _controller.getAllSlots();

    for (int i = 0; i < maxSlots; i++) {
      final algorithm = allSlots[i];
      if (algorithm != null && algorithm.guid == notesGuid) {
        return i; // Found existing Notes algorithm
      }
    }

    // Notes algorithm not found, add it
    try {
      final notesAlgorithm = Algorithm(
        algorithmIndex: -1, // Will be assigned by hardware
        guid: notesGuid,
        name: 'Notes',
      );

      await _controller.addAlgorithm(notesAlgorithm);

      // Wait a bit for the algorithm to be added
      await Future.delayed(const Duration(milliseconds: 500));

      // Find the newly added Notes algorithm
      final updatedSlots = await _controller.getAllSlots();
      for (int i = 0; i < maxSlots; i++) {
        final algorithm = updatedSlots[i];
        if (algorithm != null && algorithm.guid == notesGuid) {
          return i; // Found newly added Notes algorithm
        }
      }

      return null; // Failed to find after adding
    } catch (e) {
      return null;
    }
  }
}
