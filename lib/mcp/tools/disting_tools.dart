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

/// Defines MCP tools for interacting with the Disting state (presets, slots, parameters)
/// via the DistingController.
class DistingTools {
  final DistingController _controller;

  // Assuming a maximum number of slots for finding the first empty one
  final int maxSlots = 32;

  DistingTools(this._controller);

  // Helper to scale value based on powerOfTen for display
  num _scaleForDisplay(int value, int? powerOfTen) {
    if (powerOfTen != null && powerOfTen > 0) {
      return value / pow(10, powerOfTen);
    }
    return value;
  }

  /// MCP Tool: Gets the entire current preset state.
  /// Parameters: None
  /// Returns:
  ///   A JSON string representing the current preset including name,
  ///   and details for each slot (algorithm and parameters).
  Future<String> get_current_preset(Map<String, dynamic> params) async {
    try {
      final presetName = await _controller.getCurrentPresetName();
      final Map<int, Algorithm?> slotAlgorithms =
          await _controller.getAllSlots();

      List<Map<String, dynamic>?> slotsJsonList = List.filled(maxSlots, null);

      for (int i = 0; i < maxSlots; i++) {
        final algorithm = slotAlgorithms[i];
        if (algorithm != null) {
          // To get parameters, we need to call getParametersForSlot for each non-empty slot
          final List<ParameterInfo> parameterInfos =
              await _controller.getParametersForSlot(i);

          List<Map<String, dynamic>> parametersJsonList = [];
          for (final pInfo in parameterInfos) {
            final int? liveRawValue =
                await _controller.getParameterValue(i, pInfo.parameterNumber);

            parametersJsonList.add({
              'parameter_number': pInfo.parameterNumber,
              'name': pInfo.name,
              'min_value':
                  _scaleForDisplay(pInfo.min, pInfo.powerOfTen), // Scaled
              'max_value':
                  _scaleForDisplay(pInfo.max, pInfo.powerOfTen), // Scaled
              'default_value': _scaleForDisplay(
                  pInfo.defaultValue, pInfo.powerOfTen), // Scaled
              'unit': pInfo.unit,
              'value': liveRawValue != null
                  ? _scaleForDisplay(liveRawValue, pInfo.powerOfTen)
                  : null, // Scaled
            });
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

      final Map<String, dynamic> presetData =
          _buildPresetJson(presetName, slotsJsonList);
      return jsonEncode(
          convertToSnakeCaseKeys(presetData)); // Apply converter here
    } catch (e, s) {
      print('[MCP DistingTools] Error in get_current_preset: $e\\n$s');
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  Map<String, dynamic> _buildPresetJson(
      String presetName, List<Map<String, dynamic>?> slotsData) {
    return {
      'preset_name': presetName,
      'slots': slotsData,
    };
  }

  static int _levenshteinDistance(String s, String t) {
    final int sLen = s.length;
    final int tLen = t.length;
    if (sLen == 0) return tLen;
    if (tLen == 0) return sLen;
    final v = List.generate(sLen + 1, (_) => List<int>.filled(tLen + 1, 0));
    for (var i = 0; i <= sLen; i++) {
      v[i][0] = i;
    }
    for (var j = 0; j <= tLen; j++) {
      v[0][j] = j;
    }
    for (var i = 1; i <= sLen; i++) {
      for (var j = 1; j <= tLen; j++) {
        final cost = s[i - 1].toLowerCase() == t[j - 1].toLowerCase() ? 0 : 1;
        v[i][j] = [
          v[i - 1][j] + 1,
          v[i][j - 1] + 1,
          v[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return v[sLen][tLen];
  }

  static double _similarity(String s, String t) {
    final dist = _levenshteinDistance(s, t);
    final maxLen = s.length > t.length ? s.length : t.length;
    if (maxLen == 0) return 1.0;
    return (maxLen - dist) / maxLen;
  }

  /// MCP Tool: Adds an algorithm to the first available slot (determined by hardware).
  /// Parameters:
  ///   - algorithm_guid (string, required): The GUID of the algorithm to add.
  /// Returns:
  ///   A JSON string confirming the addition or an error.
  Future<String> add_algorithm(Map<String, dynamic> params) async {
    final String? algorithmGuid = params['algorithm_guid'];
    final String? algorithmName = params['algorithm_name'];
    if ((algorithmGuid == null || algorithmGuid.isEmpty) &&
        (algorithmName == null || algorithmName.isEmpty)) {
      return jsonEncode({
        'success': false,
        'error':
            'Missing or empty "algorithm_guid" or "algorithm_name" parameter.'
      });
    }

    String resolvedGuid = algorithmGuid ?? '';
    if (algorithmGuid == null || algorithmGuid.isEmpty) {
      final algorithms = AlgorithmMetadataService().getAllAlgorithms();
      final exactMatches = algorithms
          .where(
              (alg) => alg.name.toLowerCase() == algorithmName!.toLowerCase())
          .toList();
      if (exactMatches.isEmpty) {
        final fuzzyMatches = algorithms.where((alg) {
          return _similarity(alg.name, algorithmName!) >= 0.7;
        }).toList();
        if (fuzzyMatches.isEmpty) {
          return jsonEncode(convertToSnakeCaseKeys({
            'success': false,
            'error': 'No algorithm named "$algorithmName" found.'
          }));
        }
        if (fuzzyMatches.length > 1) {
          final candidates = fuzzyMatches
              .map((alg) => {'name': alg.name, 'guid': alg.guid})
              .toList();
          return jsonEncode(convertToSnakeCaseKeys({
            'success': false,
            'error':
                'Ambiguous algorithm name "$algorithmName". Fuzzy matches (>=70%): $candidates. Please specify more precisely or use the GUID.'
          }));
        }
        resolvedGuid = fuzzyMatches.first.guid;
      } else if (exactMatches.length > 1) {
        final candidates = exactMatches
            .map((alg) => {'name': alg.name, 'guid': alg.guid})
            .toList();
        return jsonEncode(convertToSnakeCaseKeys({
          'success': false,
          'error':
              'Ambiguous algorithm name "$algorithmName". Matches: $candidates. Please specify more precisely.'
        }));
      } else {
        resolvedGuid = exactMatches.first.guid;
      }
    }

    try {
      final algoStub =
          Algorithm(algorithmIndex: -1, guid: resolvedGuid, name: '');

      await _controller.addAlgorithm(algoStub);

      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message': 'Request to add algorithm $resolvedGuid sent.'
      }));
    } catch (e, s) {
      print('[MCP DistingTools] Error in add_algorithm: $e\\n$s');
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  /// MCP Tool: Removes (clears) the algorithm from a specific slot.
  /// Parameters:
  ///   - slot_index (int, required): The index of the slot to clear.
  /// Returns:
  ///   A JSON string confirming the removal or an error.
  Future<String> remove_algorithm(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'];
    if (slotIndex == null) {
      return jsonEncode(convertToSnakeCaseKeys(
          // Ensure snake case for error response
          {'success': false, 'error': 'Missing "slot_index" parameter.'}));
    }

    try {
      await _controller.clearSlot(slotIndex);
      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message': 'Algorithm removed from slot $slotIndex.'
      }));
    } catch (e, s) {
      print('[MCP DistingTools] Error in remove_algorithm: $e\\n$s');
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  // Updated method to set parameter value, handling display_value and powerOfTen
  Future<String> set_parameter_value(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final int? parameterNumberParam = params['parameter_number'] as int?;
    final String? parameterNameParam = params['parameter_name'] as String?;
    final num? displayValue = params['value'] as num?;

    if (slotIndex == null) {
      return jsonEncode(convertToSnakeCaseKeys(
          {'success': false, 'error': 'Missing "slot_index" parameter.'}));
    }
    if (displayValue == null) {
      return jsonEncode(convertToSnakeCaseKeys(
          {'success': false, 'error': 'Missing "value" parameter.'}));
    }

    if (parameterNumberParam == null && parameterNameParam == null) {
      return jsonEncode(convertToSnakeCaseKeys({
        'success': false,
        'error':
            'Either "parameter_number" or "parameter_name" must be provided.'
      }));
    }

    if (parameterNumberParam != null && parameterNameParam != null) {
      return jsonEncode(convertToSnakeCaseKeys({
        'success': false,
        'error':
            'Provide either "parameter_number" or "parameter_name", not both.'
      }));
    }

    try {
      final List<ParameterInfo> paramInfos =
          await _controller.getParametersForSlot(slotIndex);

      int? targetParameterNumber;
      ParameterInfo? paramInfo;

      if (parameterNumberParam != null) {
        if (parameterNumberParam >= paramInfos.length ||
            parameterNumberParam < 0) {
          return jsonEncode(convertToSnakeCaseKeys({
            'success': false,
            'error':
                'Parameter number $parameterNumberParam is out of bounds for slot $slotIndex.'
          }));
        }
        targetParameterNumber = parameterNumberParam;
        paramInfo = paramInfos[targetParameterNumber];
      } else if (parameterNameParam != null) {
        final matchingParams = paramInfos
            .where(
                (p) => p.name.toLowerCase() == parameterNameParam.toLowerCase())
            .toList();

        if (matchingParams.isEmpty) {
          return jsonEncode(convertToSnakeCaseKeys({
            'success': false,
            'error':
                'Parameter with name "$parameterNameParam" not found in slot $slotIndex. Check `get_current_preset` for available parameters.'
          }));
        }
        if (matchingParams.length > 1) {
          return jsonEncode(convertToSnakeCaseKeys({
            'success': false,
            'error':
                'Parameter name "$parameterNameParam" is ambiguous in slot $slotIndex. Please use "parameter_number". Check `get_current_preset` for details.'
          }));
        }
        paramInfo = matchingParams.first;
        // We need to find the original index (parameterNumber) of this paramInfo
        targetParameterNumber = paramInfos.indexOf(paramInfo);
      }

      if (paramInfo == null || targetParameterNumber == null) {
        // Should not happen if logic above is correct
        return jsonEncode(convertToSnakeCaseKeys({
          'success': false,
          'error': 'Failed to identify target parameter.'
        }));
      }

      int rawValue;
      if (paramInfo.powerOfTen > 0) {
        rawValue = (displayValue * pow(10, paramInfo.powerOfTen)).round();
      } else {
        rawValue =
            displayValue.round(); // Round even if no powerOfTen, to ensure int
      }

      if (rawValue < paramInfo.min || rawValue > paramInfo.max) {
        final effectiveMin =
            _scaleForDisplay(paramInfo.min, paramInfo.powerOfTen);
        final effectiveMax =
            _scaleForDisplay(paramInfo.max, paramInfo.powerOfTen);
        return jsonEncode(convertToSnakeCaseKeys({
          'success': false,
          'error':
              'Provided value $displayValue (scaled to $rawValue) is out of range for parameter ${paramInfo.name} (effective range: $effectiveMin to $effectiveMax, raw range: ${paramInfo.min} to ${paramInfo.max}).'
        }));
      }

      await _controller.updateParameterValue(
          slotIndex, targetParameterNumber, rawValue);

      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message':
            'Parameter ${paramInfo.name} (number $targetParameterNumber) in slot $slotIndex set to $displayValue.'
      }));
    } catch (e, s) {
      print('[MCP DistingTools] Error in set_parameter_value: $e\\n$s');
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  /// MCP Tool: Gets the value of a specific parameter.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  ///   - parameter_number (int, required): The 0-based index of the parameter within the algorithm.
  /// Returns:
  ///   A JSON string with the parameter value or an error.
  Future<String> get_parameter_value(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final int? parameterNumber = params['parameter_number'] as int?;

    if (slotIndex == null) {
      return jsonEncode(convertToSnakeCaseKeys(
          {'success': false, 'error': 'Missing "slot_index" parameter.'}));
    }
    if (parameterNumber == null) {
      return jsonEncode(convertToSnakeCaseKeys({
        'success': false,
        'error': 'Missing "parameter_number" parameter.'
      }));
    }

    try {
      final int? liveRawValue =
          await _controller.getParameterValue(slotIndex, parameterNumber);

      if (liveRawValue == null) {
        return jsonEncode(convertToSnakeCaseKeys({
          'success': false,
          'error':
              'Could not retrieve value for parameter $parameterNumber in slot $slotIndex.'
        }));
      }

      // Fetch parameter info to get powerOfTen for scaling
      final List<ParameterInfo> paramInfos =
          await _controller.getParametersForSlot(slotIndex);
      if (parameterNumber >= paramInfos.length || parameterNumber < 0) {
        return jsonEncode(convertToSnakeCaseKeys({
          'success': false,
          'error':
              'Parameter number $parameterNumber is out of bounds for slot $slotIndex (for scaling info).'
        }));
      }
      final ParameterInfo paramInfo = paramInfos[parameterNumber];

      final Map<String, dynamic> result = {
        'success': true,
        'slot_index': slotIndex,
        'parameter_number': parameterNumber,
        'value': _scaleForDisplay(
            liveRawValue, paramInfo.powerOfTen), // Scaled value
      };
      return jsonEncode(convertToSnakeCaseKeys(result));
    } catch (e, s) {
      print('[MCP DistingTools] Error in get_parameter_value: $e\\n$s');
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  /// MCP Tool: Sets the name of the current preset.
  /// Parameters:
  ///   - name (string, required): The new name for the preset.
  /// Returns:
  ///   A JSON string confirming the action or an error.
  Future<String> set_preset_name(Map<String, dynamic> params) async {
    final String? name = params['name'] as String?;

    if (name == null || name.isEmpty) {
      return jsonEncode(
          {'success': false, 'error': 'Missing or empty "name" parameter.'});
    }

    try {
      await _controller.setPresetName(name);
      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message': 'Preset name set to "$name".',
      }));
    } catch (e) {
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  /// MCP Tool: Sets the custom name for an algorithm in a specific slot.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  ///   - name (string, required): The desired custom name.
  /// Returns:
  ///   A JSON string confirming the action or an error.
  Future<String> set_slot_name(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final String? name = params['name'] as String?;

    if (slotIndex == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "slot_index" parameter.'});
    }
    if (name == null || name.isEmpty) {
      return jsonEncode(
          {'success': false, 'error': 'Missing or empty "name" parameter.'});
    }

    try {
      await _controller.setSlotName(slotIndex, name);
      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message': 'Name for slot $slotIndex set to "$name".',
      }));
    } catch (e) {
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  /// MCP Tool: Tells the device to clear the current preset and start a new, empty one.
  /// Parameters: None (can accept a dummy string for consistency if MCP requires it).
  /// Returns: A JSON string confirming the action or an error.
  Future<String> new_preset(Map<String, dynamic> params) async {
    try {
      await _controller.newPreset();
      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message': 'New empty preset initiated on the device.',
      }));
    } catch (e) {
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
    }
  }

  /// MCP Tool: Tells the device to save the current working preset.
  /// Parameters: None (can accept a dummy string for consistency if MCP requires it).
  /// Returns: A JSON string confirming the action or an error.
  Future<String> save_preset(Map<String, dynamic> params) async {
    try {
      await _controller.savePreset();
      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message': 'Request to save current preset sent to the device.',
      }));
    } catch (e) {
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
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
  Future<String> move_algorithm_up(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;

    if (slotIndex == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "slot_index" parameter.'});
    }

    if (slotIndex == 0) {
      return jsonEncode({
        'success': false,
        'error': 'Cannot move algorithm in slot 0 further up.'
      });
    }
    // Ensure slotIndex is within a reasonable range if needed, though controller might handle this.
    // For now, just check against 0. Max slot check can be added if necessary or rely on controller.

    final int sourceSlotIndex = slotIndex;
    final int destSlotIndex = slotIndex - 1;

    try {
      await _controller.moveAlgorithmUp(sourceSlotIndex);
      return jsonEncode(convertToSnakeCaseKeys({
        'success': true,
        'message': 'Algorithm from slot $sourceSlotIndex moved up.'
      }));
    } catch (e) {
      return jsonEncode(
          convertToSnakeCaseKeys({'success': false, 'error': e.toString()}));
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
  Future<String> move_algorithm_down(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;

    if (slotIndex == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "slot_index" parameter.'});
    }

    // Assuming maxSlots is available or a way to check upper bound exists.
    // For simplicity, we'll rely on the controller to handle upper boundary errors if any.
    // A check like `if (slotIndex >= maxSlots - 1)` could be added.
    // For now, we'll assume maxSlots is dynamic or handled by the controller.

    final int sourceSlotIndex = slotIndex;

    try {
      // Check if sourceSlotIndex is already the last possible slot.
      // This requires knowing the total number of slots, which is `maxSlots`.
      if (sourceSlotIndex >= maxSlots - 1) {
        return jsonEncode({
          'success': false,
          'error': 'Cannot move algorithm in slot ${maxSlots - 1} further down.'
        });
      }
      await _controller.moveAlgorithmDown(sourceSlotIndex);
      return jsonEncode({
        'success': true,
        'message': 'Algorithm from slot $sourceSlotIndex moved down.'
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// MCP Tool: Retrieves the current module screenshot data.
  /// Parameters: None
  /// Returns:
  ///   A Map containing success status, and either base64 encoded screenshot_base64
  ///   and format, or an error message.
  Future<Map<String, dynamic>> get_module_screenshot(
      Map<String, dynamic> params) async {
    try {
      final Uint8List? pngBytesFromController =
          await _controller.getModuleScreenshot(); // Assumed to be PNG bytes

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
              'error': 'Failed to encode screenshot to JPEG after decoding.'
            };
          }
        } else {
          return {
            'success': false,
            'error':
                'Failed to decode PNG bytes (from controller) into an image object.'
          };
        }
      } else {
        return {
          'success': false,
          'error':
              'Module screenshot is currently unavailable (controller returned null/empty) or device not connected.'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Exception in get_module_screenshot: ${e.toString()}'
      };
    }
  }
}
