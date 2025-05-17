import 'dart:convert';
import 'dart:typed_data'; // Added for Uint8List
import 'dart:math'; // For min function
import 'package:nt_helper/domain/disting_nt_sysex.dart'; // Added for DistingNT.decodeBitmap

import 'package:nt_helper/services/disting_controller.dart';

/// Defines MCP tools for interacting with the Disting state (presets, slots, parameters)
/// via the DistingController.
class DistingTools {
  final DistingController _controller;
  // Assuming a maximum number of slots for finding the first empty one
  final int maxSlots = 32;

  DistingTools(this._controller);

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

      List<Map<String, dynamic>?> slotsJson = List.filled(maxSlots, null);

      for (int i = 0; i < maxSlots; i++) {
        final algorithm = slotAlgorithms[i];
        if (algorithm != null) {
          // To get parameters, we need to call getParametersForSlot for each non-empty slot
          final List<ParameterInfo> parameterInfos =
              await _controller.getParametersForSlot(i);

          List<Map<String, dynamic>> parametersJsonList = [];
          for (final pInfo in parameterInfos) {
            final int? liveValue =
                await _controller.getParameterValue(i, pInfo.parameterNumber);
            parametersJsonList.add({
              'parameterNumber': pInfo.parameterNumber,
              'name': pInfo.name,
              'min': pInfo.min,
              'max': pInfo.max,
              'defaultValue': pInfo.defaultValue,
              'unit': pInfo.unit,
              'powerOfTen': pInfo.powerOfTen,
              'value': liveValue, // Added live parameter value
            });
          }

          slotsJson[i] = {
            'slotIndex': i,
            'algorithm': {
              'guid': algorithm.guid,
              'name': algorithm.name,
              'algorithmIndex': algorithm.algorithmIndex,
            },
            'parameters': parametersJsonList,
          };
        }
      }

      return jsonEncode({
        'success': true,
        'presetName': presetName,
        'slots': slotsJson,
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// MCP Tool: Adds an algorithm to the first available slot (determined by hardware).
  /// Parameters:
  ///   - algorithm_guid (string, required): The GUID of the algorithm to add.
  /// Returns:
  ///   A JSON string confirming the addition or an error.
  Future<String> add_algorithm(Map<String, dynamic> params) async {
    final String? algorithmGuid = params['algorithm_guid'];
    if (algorithmGuid == null || algorithmGuid.isEmpty) {
      return jsonEncode({
        'success': false,
        'error': 'Missing or empty "algorithm_guid" parameter.'
      });
    }

    try {
      // Create a minimal Algorithm object with just the GUID.
      // The controller/cubit uses this to find the full AlgorithmInfo.
      // The algorithmIndex here is arbitrary as it's not used for adding.
      final algoStub = Algorithm(
          algorithmIndex: -1, // Placeholder, not used for adding
          guid: algorithmGuid,
          name: '' // Placeholder, not used
          );

      // Call the updated controller method
      await _controller.addAlgorithm(algoStub);

      // Since the hardware determines the slot, we can't report the index here.
      // The user/client might need to call getCurrentPreset after to see the result.
      return jsonEncode({
        'success': true,
        'message': 'Request to add algorithm $algorithmGuid sent.'
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
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
      return jsonEncode(
          {'success': false, 'error': 'Missing "slot_index" parameter.'});
    }

    try {
      await _controller.clearSlot(slotIndex);
      return jsonEncode({
        'success': true,
        'message': 'Algorithm removed from slot $slotIndex.'
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  // Updated method to set parameter value, handling display_value and powerOfTen
  Future<String> set_parameter_value(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final int? parameterIndex = params['parameter_index'] as int?;
    // Expect 'display_value' which can be int or double (or string parsable to double)
    final dynamic displayValue = params['display_value'];

    if (slotIndex == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "slot_index" parameter.'});
    }
    if (parameterIndex == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "parameter_index" parameter.'});
    }
    if (displayValue == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "display_value" parameter.'});
    }

    try {
      // Fetch parameter info to get powerOfTen
      final List<ParameterInfo> paramInfos =
          await _controller.getParametersForSlot(slotIndex);
      if (parameterIndex >= paramInfos.length) {
        return jsonEncode({
          'success': false,
          'error':
              'Parameter index $parameterIndex is out of bounds for slot $slotIndex.'
        });
      }
      final ParameterInfo paramInfo = paramInfos[parameterIndex];
      final int powerOfTen = paramInfo.powerOfTen ?? 0;

      // Parse displayValue to double first for consistent scaling
      double parsedDisplayValue;
      if (displayValue is double) {
        parsedDisplayValue = displayValue;
      } else if (displayValue is int) {
        parsedDisplayValue = displayValue.toDouble();
      } else if (displayValue is String) {
        parsedDisplayValue = double.tryParse(displayValue) ??
            (throw ArgumentError(
                'Cannot parse display_value string "$displayValue" to double.'));
      } else {
        throw ArgumentError(
            'Invalid display_value type: ${displayValue.runtimeType}. Expected number or parsable string.');
      }

      // Scale the value
      final double scaledValueDouble = parsedDisplayValue * pow(10, powerOfTen);
      // The controller expects an integer, so round the scaled value.
      // This matches how hardware often handles floating point parameters internally.
      final int finalIntValue = scaledValueDouble.round();

      // The controller.updateParameterValue will perform min/max validation against this finalIntValue
      await _controller.updateParameterValue(
          slotIndex, parameterIndex, finalIntValue);

      return jsonEncode({
        'success': true,
        'message':
            'Parameter $parameterIndex in slot $slotIndex set with display value $displayValue (sent as $finalIntValue).'
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// MCP Tool: Gets the value of a specific parameter.
  /// Parameters:
  ///   - slot_index (int, required): The 0-based index of the slot.
  ///   - parameter_index (int, required): The 0-based index of the parameter within the algorithm.
  /// Returns:
  ///   A JSON string with the parameter value or an error.
  Future<String> get_parameter_value(Map<String, dynamic> params) async {
    final int? slotIndex = params['slot_index'] as int?;
    final int? parameterIndex = params['parameter_index'] as int?;

    if (slotIndex == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "slot_index" parameter.'});
    }
    if (parameterIndex == null) {
      return jsonEncode(
          {'success': false, 'error': 'Missing "parameter_index" parameter.'});
    }

    try {
      final int? value =
          await _controller.getParameterValue(slotIndex, parameterIndex);
      if (value != null) {
        return jsonEncode({
          'success': true,
          'slotIndex': slotIndex,
          'parameterIndex': parameterIndex,
          'value': value,
        });
      } else {
        return jsonEncode({
          'success': false,
          'error':
              'Failed to retrieve parameter value for slot $slotIndex, parameter $parameterIndex. Value was null, possibly due to MIDI error, empty slot, or invalid parameter.',
        });
      }
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
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
      return jsonEncode({
        'success': true,
        'message': 'Preset name set to "$name".',
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
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
      return jsonEncode({
        'success': true,
        'message': 'Name for slot $slotIndex set to "$name".',
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// MCP Tool: Tells the device to clear the current preset and start a new, empty one.
  /// Parameters: None (can accept a dummy string for consistency if MCP requires it).
  /// Returns: A JSON string confirming the action or an error.
  Future<String> new_preset(Map<String, dynamic> params) async {
    try {
      await _controller.newPreset();
      return jsonEncode({
        'success': true,
        'message': 'New empty preset initiated on the device.',
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
    }
  }

  /// MCP Tool: Tells the device to save the current working preset.
  /// Parameters: None (can accept a dummy string for consistency if MCP requires it).
  /// Returns: A JSON string confirming the action or an error.
  Future<String> save_preset(Map<String, dynamic> params) async {
    try {
      await _controller.savePreset();
      return jsonEncode({
        'success': true,
        'message': 'Request to save current preset sent to the device.',
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
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
      return jsonEncode({
        'success': true,
        'message': 'Algorithm from slot $sourceSlotIndex moved up.'
      });
    } catch (e) {
      return jsonEncode({'success': false, 'error': e.toString()});
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
    final int destSlotIndex = slotIndex + 1;

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

  /// MCP Tool: Retrieves the current module screenshot as a base64 encoded string.
  /// Parameters: None
  /// Returns:
  ///   A JSON string containing the base64 encoded screenshot and its format,
  ///   or an error message if not connected or screenshot is unavailable.
  Future<String> get_module_screenshot(Map<String, dynamic> params) async {
    try {
      final Uint8List? rawScreenshotBytes =
          await _controller.getModuleScreenshot();

      if (rawScreenshotBytes != null && rawScreenshotBytes.isNotEmpty) {
        // Decode/process the raw bytes into a PNG format using the existing utility
        final Uint8List pngBytes = DistingNT.decodeBitmap(rawScreenshotBytes);

        if (pngBytes.isNotEmpty) {
          final String base64Image = base64Encode(pngBytes);
          return jsonEncode({
            'success': true,
            'screenshot_base64': base64Image,
            'format': 'png', // decodeBitmap ensures PNG format
          });
        } else {
          // decodeBitmap returned empty, indicating an error during processing
          return jsonEncode({
            'success': false,
            'error': 'Failed to process module screenshot data.'
          });
        }
      } else {
        return jsonEncode({
          'success': false,
          'error':
              'Module screenshot is currently unavailable or device not connected.'
        });
      }
    } catch (e) {
      return jsonEncode({
        'success': false,
        'error': 'Failed to retrieve module screenshot: ${e.toString()}'
      });
    }
  }
}
