import 'dart:typed_data';

import 'package:nt_helper/domain/disting_nt_sysex.dart'
    show Algorithm, ParameterInfo, ParameterEnumStrings, Mapping, ParameterValue;
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/packed_mapping_data.dart' show PackedMappingData;

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
    int slotIndex,
    int parameterNumber,
    dynamic value,
  );

  /// Updates the string value of a specific parameter for the algorithm in the given slot.
  /// Used for text-based parameters like those in the Notes algorithm.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index or parameterNumber is invalid.
  Future<void> updateParameterString(
    int slotIndex,
    int parameterNumber,
    String value,
  );

  /// Retrieves the state of all slots, mapping slot index to the loaded algorithm (or null).
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<Map<int, Algorithm?>> getAllSlots();

  /// Retrieves the current value of a specific parameter from the device.
  /// Returns ParameterValue with value and metadata (including isDisabled flag).
  /// Returns null if the value cannot be fetched (e.g., slot empty, parameter invalid, or MIDI error).
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index or parameterNumber is invalid.
  Future<ParameterValue?> getParameterValue(int slotIndex, int parameterNumber);

  /// Retrieves the current string value of a specific parameter from the device.
  /// Used for text-based parameters like those in the Notes algorithm.
  /// Returns null if the value cannot be fetched (e.g., slot empty, parameter invalid, or MIDI error).
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index or parameterNumber is invalid.
  Future<String?> getParameterStringValue(int slotIndex, int parameterNumber);

  /// Sets a custom name for the algorithm in the specified slot.
  /// Throws StateError if the Disting is not in a synchronized state or the slot is empty.
  /// Throws ArgumentError if the slot index is invalid.
  Future<void> setSlotName(int slotIndex, String name);

  /// Gets the custom name for the algorithm in the specified slot.
  /// Returns null if no custom name is set or the slot is empty.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index is invalid.
  Future<String?> getSlotName(int slotIndex);

  /// Tells the device to clear the current preset and start a new, empty one.
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<void> newPreset();

  /// Tells the device to save the current working preset.
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<void> savePreset();

  /// Waits for all queued parameter updates to be sent to hardware.
  Future<void> flushParameterQueue();

  /// Retrieves the current module screenshot as byte data.
  /// Returns null if not connected, screenshot unavailable, or an error occurs.
  /// Throws StateError if the Disting is not in a synchronized state (if applicable for this operation).
  Future<Uint8List?> getModuleScreenshot();

  /// Refreshes the data for a specific slot to ensure UI is updated.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index is invalid.
  Future<void> refreshSlot(int slotIndex);

  /// Retrieves the current CPU usage information from the device.
  /// Returns CPU usage data including overall CPU usage and per-slot usage.
  /// Returns null if the usage cannot be fetched (e.g., device not connected, MIDI error).
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<CpuUsage?> getCpuUsage();

  /// Get enum strings for a parameter if it's an enum type
  /// Returns null if the parameter is not an enum or if the slot/parameter is invalid.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index or parameterNumber is invalid.
  Future<ParameterEnumStrings?> getParameterEnumStrings(
    int slotIndex,
    int parameterNumber,
  );

  /// Get mapping information for a parameter
  /// Returns the mapping data including performance page assignment, MIDI/CV mappings, etc.
  /// Returns null if the slot/parameter is invalid.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index or parameterNumber is invalid.
  Future<Mapping?> getParameterMapping(int slotIndex, int parameterNumber);

  /// Whether the Disting is currently in a synchronized state.
  bool get isSynchronized;

  /// Retrieves all parameter values for the algorithm in the specified slot.
  /// Returns values in the same order as getParametersForSlot.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index is invalid.
  Future<List<ParameterValue>> getValuesForSlot(int slotIndex);

  /// Retrieves all mappings for the algorithm in the specified slot.
  /// Returns mappings in the same order as getParametersForSlot.
  /// Throws StateError if the Disting is not in a synchronized state.
  /// Throws ArgumentError if the slot index is invalid.
  Future<List<Mapping>> getMappingsForSlot(int slotIndex);

  /// Saves a mapping for a specific parameter.
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<void> saveMapping(int algorithmIndex, int parameterNumber, PackedMappingData mapping);

  /// Refreshes the device state (re-reads preset from hardware).
  /// Throws StateError if the Disting is not in a synchronized state.
  Future<void> refresh();
}
