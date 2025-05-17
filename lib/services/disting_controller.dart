import 'dart:typed_data';
import 'package:nt_helper/domain/disting_nt_sysex.dart';

/// Abstract interface defining operations to control the Disting state,
/// intended for use by MCP tools or other services.
abstract class DistingController {
  /// Gets the name of the currently loaded preset.
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<String> getCurrentPresetName();

  /// Sets the name of the currently loaded preset.
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<void> setPresetName(String name);

  /// Retrieves the algorithm currently loaded in the specified slot.
  /// Returns null if the slot is empty.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index is invalid.
  Future<Algorithm?> getAlgorithmInSlot(int slotIndex);

  /// Retrieves all parameters for the algorithm in the specified slot.
  /// Returns an empty list if the slot is empty or the algorithm has no parameters.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index is invalid.
  Future<List<ParameterInfo>> getParametersForSlot(int slotIndex);

  /// Adds the specified algorithm to the first available slot.
  /// The hardware determines the actual slot index.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the algorithm GUID is not found.
  Future<void> addAlgorithm(Algorithm algorithm);

  /// Removes the algorithm from the specified slot.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index is invalid.
  Future<void> clearSlot(int slotIndex);

  /// Moves the algorithm in the specified slot one position up.
  /// Throws StateError if the Disting is not in a synchronized state or if the slot is already at the top.
  /// Throws ArgumentError if the slot index is invalid.
  Future<void> moveAlgorithmUp(int slotIndex);

  /// Moves the algorithm in the specified slot one position down.
  /// Throws StateError if the Disting is not in a synchronized state or if the slot is already at the bottom.
  /// Throws ArgumentError if the slot index is invalid.
  Future<void> moveAlgorithmDown(int slotIndex);

  /// Updates the value of a specific parameter for the algorithm in the given slot.
  /// The `value` type should match the expected type for the parameter.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index or parameterNumber is invalid, or if the value type is incorrect.
  Future<void> updateParameterValue(
      int slotIndex, int parameterNumber, dynamic value);

  /// Retrieves the state of all slots, mapping slot index to the loaded algorithm (or null).
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<Map<int, Algorithm?>> getAllSlots();

  /// Retrieves the current value of a specific parameter from the device.
  /// Returns null if the value cannot be fetched (e.g., slot empty, parameter invalid, or MIDI error).
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index or parameterNumber is invalid.
  Future<int?> getParameterValue(int slotIndex, int parameterNumber);

  /// Sets a custom name for the algorithm in the specified slot.
  /// Throws StateError if the Disting is not in a synchronized state or the slot is empty.
  /// Throws ArgumentError if the slot index is invalid.
  Future<void> setSlotName(int slotIndex, String name);

  /// Tells the device to clear the current preset and start a new, empty one.
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<void> newPreset();

  /// Tells the device to save the current working preset.
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<void> savePreset();

  /// Retrieves the current module screenshot as byte data.
  /// Returns null if not connected, screenshot unavailable, or an error occurs.
  /// Throws StateError if the Disting is not in a synchronized state (if applicable for this operation).
  Future<Uint8List?> getModuleScreenshot();
}
