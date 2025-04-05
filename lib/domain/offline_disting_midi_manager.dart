import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import '../db/daos/presets_dao.dart';

/// An implementation of [IDistingMidiManager] that interacts with the
/// cached database instead of a physical MIDI device.
class OfflineDistingMidiManager implements IDistingMidiManager {
  final AppDatabase _database;
  late final MetadataDao _metadataDao;

  // Internal state for the simulated preset
  final List<String> _presetAlgorithmGuids = [];
  // State per slot (keyed by slot index)
  final Map<int, Map<int, int>> _parameterValues =
      {}; // slotIndex -> {paramNum: value}
  final Map<int, Map<int, PackedMappingData>> _mappings =
      {}; // slotIndex -> {paramNum: mappingData}
  final Map<int, List<int>> _routingInfo = {}; // slotIndex -> routingInfo list
  final Map<int, String> _customNames = {}; // slotIndex -> customName
  String _presetName = "Offline Preset"; // Internal preset name state

  OfflineDistingMidiManager(this._database) {
    _metadataDao = _database.metadataDao;
  }

  // Initialize state from loaded preset details
  Future<void> initializeFromDb(FullPresetDetails? details) async {
    _presetAlgorithmGuids.clear();
    _parameterValues.clear();
    _mappings.clear();
    _routingInfo.clear();
    _customNames.clear();

    if (details == null) {
      _presetName = "Offline Preset";
      return; // Start empty
    }

    _presetName = details.preset.name;
    for (int i = 0; i < details.slots.length; i++) {
      final slotData = details.slots[i];
      _presetAlgorithmGuids.add(slotData.algorithm.guid);
      _parameterValues[i] = Map.from(slotData.parameterValues);
      _mappings[i] = Map.from(slotData.mappings);
      _routingInfo[i] = List.from(slotData.routingInfo);
      if (slotData.slot.customName != null) {
        _customNames[i] = slotData.slot.customName!;
      }
    }
    debugPrint(
        "[Offline] Initialized manager state from DB preset '${_presetName}'. Slots: ${_presetAlgorithmGuids.length}");
  }

  @override
  void dispose() {
    // No resources to dispose for the offline manager
    print("OfflineDistingMidiManager disposed.");
  }

  // --- Metadata Request Implementations ---

  @override
  Future<int?> requestNumberOfAlgorithms() async {
    try {
      // Query the count directly from the database
      final algorithms = await _metadataDao.getAllAlgorithms();
      return algorithms.length;
    } catch (e) {
      print("Error fetching algorithm count from DB: $e");
      return 0; // Return 0 or null on error? Let's return 0 for now.
    }
  }

  @override
  Future<AlgorithmInfo?> requestAlgorithmInfo(int algorithmIndex) async {
    // Note: Offline mode doesn't have a direct concept of algorithmIndex
    // from the device's perspective. This implementation might need refinement
    // depending on how algorithmIndex is used offline.
    // For now, let's fetch all and try to get by index, assuming the DB list order.
    try {
      final algorithms =
          await _metadataDao.getAllAlgorithms(); // Already sorted by name
      if (algorithmIndex >= 0 && algorithmIndex < algorithms.length) {
        final entry = algorithms[algorithmIndex];
        // Fetch associated specifications
        final specs = await (_metadataDao.select(_metadataDao.specifications)
              ..where((s) => s.algorithmGuid.equals(entry.guid))
              ..orderBy([(s) => OrderingTerm.asc(s.specIndex)]))
            .get();

        return AlgorithmInfo(
          algorithmIndex:
              algorithmIndex, // Using the requested index, might be inaccurate offline
          guid: entry.guid,
          name: entry.name,
          numSpecifications: entry.numSpecifications,
          specifications: specs
              .map((s) => Specification(
                    name: s.name,
                    min: s.minValue,
                    max: s.maxValue,
                    defaultValue: s.defaultValue,
                    type: s.type,
                  ))
              .toList(),
        );
      }
      return null;
    } catch (e) {
      print("Error fetching AlgorithmInfo($algorithmIndex) from DB: $e");
      return null;
    }
  }

  @override
  Future<Algorithm?> requestAlgorithmGuid(int algorithmIndex) async {
    // Get the GUID from our internal preset list based on index
    if (algorithmIndex < 0 || algorithmIndex >= _presetAlgorithmGuids.length) {
      debugPrint(
          "[Offline] requestAlgorithmGuid: Index $algorithmIndex out of bounds for preset size ${_presetAlgorithmGuids.length}");
      return null;
    }
    final guid = _presetAlgorithmGuids[algorithmIndex];

    // Fetch the full AlgorithmEntry from the DB using the GUID
    try {
      final algoEntry = await (_metadataDao.select(_metadataDao.algorithms)
            ..where((a) => a.guid.equals(guid)))
          .getSingleOrNull();

      if (algoEntry != null) {
        // Check for duplicate GUIDs earlier in the list to simulate postfixing
        int instanceCount = 0;
        for (int i = 0; i < algorithmIndex; i++) {
          if (_presetAlgorithmGuids[i] == guid) {
            instanceCount++;
          }
        }

        String name = algoEntry.name;
        if (instanceCount > 0) {
          name = "$name ${instanceCount + 1}";
        }

        return Algorithm(
          algorithmIndex: algorithmIndex, // Use the preset index
          guid: algoEntry.guid,
          name: name, // Use potentially postfixed name
        );
      } else {
        debugPrint(
            "[Offline] requestAlgorithmGuid: Algorithm with GUID $guid not found in DB.");
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint(
          "[Offline] Error fetching AlgorithmGuid($algorithmIndex, guid: $guid) from DB: $e");
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<ParameterInfo?> requestParameterInfo(
      int algorithmIndex, int parameterNumber) {
    // Get GUID and query the specific parameter entry
    return _runForGuid<ParameterInfo?>(algorithmIndex, (guid) async {
      final paramEntry = await (_metadataDao.select(_metadataDao.parameters)
            ..where((p) =>
                p.algorithmGuid.equals(guid) &
                p.parameterNumber.equals(parameterNumber)))
          .getSingleOrNull();

      if (paramEntry != null) {
        // Map ParameterEntry to ParameterInfo
        return ParameterInfo(
          algorithmIndex: algorithmIndex, // Use preset index
          parameterNumber: paramEntry.parameterNumber,
          min: paramEntry.minValue ?? 0,
          max: paramEntry.maxValue ?? 0,
          defaultValue: paramEntry.defaultValue ?? 0,
          unit: paramEntry.rawUnitIndex ?? 0,
          name: paramEntry.name,
          powerOfTen: paramEntry.powerOfTen ?? 0,
        );
      } else {
        return null;
      }
    }, errorValue: null);
  }

  @override
  Future<ParameterValue?> requestParameterValue(
      int algorithmIndex, int parameterNumber) async {
    // Check internal state first
    final value = _parameterValues[algorithmIndex]?[parameterNumber];

    if (value != null) {
      debugPrint(
          "[Offline] requestParameterValue($algorithmIndex, $parameterNumber) - Returning state value: $value");
      return ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameterNumber,
          value: value);
    } else {
      // Fallback to default value from metadata if not set in state
      debugPrint(
          "[Offline] requestParameterValue($algorithmIndex, $parameterNumber) - Returning default value");
      final paramInfo =
          await requestParameterInfo(algorithmIndex, parameterNumber);
      return paramInfo != null
          ? ParameterValue(
              algorithmIndex: algorithmIndex,
              parameterNumber: parameterNumber,
              value: paramInfo.defaultValue)
          : null;
    }
  }

  @override
  Future<AllParameterValues?> requestAllParameterValues(int algorithmIndex) {
    // Get GUID, fetch all parameters, return their default values
    return _runForGuid<AllParameterValues?>(algorithmIndex, (guid) async {
      // Get number of parameters for this algorithm
      final numParams = await requestNumberOfParameters(algorithmIndex);
      final count = numParams?.numParameters ?? 0;

      final values = <ParameterValue>[];
      for (int i = 0; i < count; i++) {
        // Use requestParameterValue which checks internal state first, then default
        final pValue = await requestParameterValue(algorithmIndex, i);
        if (pValue != null) {
          values.add(pValue);
        } else {
          // Fallback if requestParameterValue somehow failed
          values.add(ParameterValue(
              algorithmIndex: algorithmIndex, parameterNumber: i, value: 0));
        }
      }

      return AllParameterValues(algorithmIndex: algorithmIndex, values: values);
    }, errorValue: null);
  }

  @override
  Future<ParameterPages?> requestParameterPages(int algorithmIndex) {
    // Get GUID, fetch pages and items, build ParameterPages model
    return _runForGuid<ParameterPages?>(algorithmIndex, (guid) async {
      // Fetch pages ordered by index
      final pagesQuery = _metadataDao.select(_metadataDao.parameterPages)
        ..where((p) => p.algorithmGuid.equals(guid))
        ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]);
      final pageEntries = await pagesQuery.get();

      // Fetch all items for this algorithm
      final itemsQuery = _metadataDao.select(_metadataDao.parameterPageItems)
        ..where((i) => i.algorithmGuid.equals(guid));
      final itemEntries = await itemsQuery.get();

      // Group items by page index
      final Map<int, List<int>> itemsByPageIndex = {};
      for (final item in itemEntries) {
        (itemsByPageIndex[item.pageIndex] ??= []).add(item.parameterNumber);
        // Ensure parameter numbers are sorted within each page
        itemsByPageIndex[item.pageIndex]!.sort();
      }

      // Build the final structure
      final pages = pageEntries.map((pageEntry) {
        return ParameterPage(
          name: pageEntry.name,
          parameters: itemsByPageIndex[pageEntry.pageIndex] ?? [],
        );
      }).toList();

      return ParameterPages(algorithmIndex: algorithmIndex, pages: pages);
    }, errorValue: null);
  }

  @override
  Future<ParameterEnumStrings?> requestParameterEnumStrings(
      int algorithmIndex, int parameterNumber) async {
    // IMPORTANT: This method in the interface expects the *preset slot index*.
    // We need the GUID associated with that slot index first.
    if (algorithmIndex < 0 || algorithmIndex >= _presetAlgorithmGuids.length) {
      debugPrint(
          "[Offline] requestParameterEnumStrings: Index $algorithmIndex out of bounds");
      return Future.value(
          ParameterEnumStrings.filler()); // Return filler if index invalid
    }
    final String guid = _presetAlgorithmGuids[algorithmIndex];

    // Always query the ParameterEnums table directly, relying on cached data presence.
    try {
      final enumsQuery = _metadataDao.select(_metadataDao.parameterEnums)
        ..where((e) =>
            e.algorithmGuid.equals(guid) &
            e.parameterNumber.equals(parameterNumber))
        ..orderBy([(e) => OrderingTerm.asc(e.enumIndex)]);

      final enumEntries = await enumsQuery.get();

      if (enumEntries.isNotEmpty) {
        return ParameterEnumStrings(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameterNumber,
          values: enumEntries.map((e) => e.enumString).toList(),
        );
      } else {
        // Return filler if no enums found (or parameter isn't enum type)
        return ParameterEnumStrings.filler();
      }
    } catch (e, stackTrace) {
      debugPrint(
          "[Offline] Error fetching enums for guid $guid, param $parameterNumber: $e");
      debugPrintStack(stackTrace: stackTrace);
      return ParameterEnumStrings.filler(); // Return filler on error
    }
  }

  @override
  Future<ParameterValueString?> requestParameterValueString(
      int algorithmIndex, int parameterNumber) {
    // Return default/filler for now
    debugPrint(
        "[Offline] requestParameterValueString($algorithmIndex, $parameterNumber) - Returning filler");
    return Future.value(ParameterValueString.filler());
  }

  @override
  Future<Mapping?> requestMappings(int algorithmIndex, int parameterNumber) {
    // Read from internal state
    final mapping = _mappings[algorithmIndex]?[parameterNumber];
    if (mapping != null) {
      debugPrint(
          "[Offline] requestMappings($algorithmIndex, $parameterNumber) - Returning state value");
      return Future.value(Mapping(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameterNumber,
          packedMappingData: mapping));
    } else {
      debugPrint(
          "[Offline] requestMappings($algorithmIndex, $parameterNumber) - Returning filler");
      return Future.value(Mapping.filler());
    }
  }

  @override
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex) {
    // Read from internal state
    final routing = _routingInfo[algorithmIndex];
    if (routing != null) {
      debugPrint(
          "[Offline] requestRoutingInformation($algorithmIndex) - Returning state value");
      return Future.value(
          RoutingInfo(algorithmIndex: algorithmIndex, routingInfo: routing));
    } else {
      debugPrint(
          "[Offline] requestRoutingInformation($algorithmIndex) - Returning filler");
      return Future.value(RoutingInfo.filler());
    }
  }

  @override
  Future<String?> requestPresetName() async {
    return _presetName; // Return internal state name
  }

  @override
  Future<int?> requestNumAlgorithmsInPreset() async {
    // Return the length of our internal preset list
    debugPrint(
        "[Offline] requestNumAlgorithmsInPreset: Returning ${_presetAlgorithmGuids.length}");
    return _presetAlgorithmGuids.length;
  }

  @override
  Future<NumParameters?> requestNumberOfParameters(int algorithmIndex) {
    // Get GUID and query parameter count from DB
    return _runForGuid<NumParameters?>(algorithmIndex, (guid) async {
      final countQuery = _metadataDao.parameters.selectOnly()
        ..where(_metadataDao.parameters.algorithmGuid.equals(guid))
        ..addColumns([_metadataDao.parameters.parameterNumber.count()]);
      final count = await countQuery
              .map((row) =>
                  row.read(_metadataDao.parameters.parameterNumber.count()))
              .getSingleOrNull() ??
          0;
      return NumParameters(
          algorithmIndex: algorithmIndex, numParameters: count);
    }, errorValue: null);
  }

  @override
  Future<String?> requestVersionString() async {
    return "Offline Mode v0.1"; // Fixed version for offline
  }

  @override
  Future<List<String>?> requestUnitStrings() async {
    // Fetch all unit strings from the Units table
    try {
      final units = await _metadataDao.getAllUnits();
      // The API likely expects a list of strings, ordered somehow?
      // Let's assume ordering by ID is sufficient for now.
      return units.map((u) => u.unitString).toList();
    } catch (e, stackTrace) {
      debugPrint("[Offline] Error fetching UnitStrings from DB: $e");
      debugPrintStack(stackTrace: stackTrace);
      return []; // Return empty list on error
    }
  }

  // --- State Mutation Request Implementations (Defaults/No-ops) ---

  @override
  Future<void> setParameterValue(
      int algorithmIndex, int parameterNumber, int value) async {
    debugPrint(
        "[Offline] setParameterValue($algorithmIndex, $parameterNumber, $value)");
    // Update internal state
    (_parameterValues[algorithmIndex] ??= {})[parameterNumber] = value;
  }

  @override
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    debugPrint(
        "[Offline] requestSetMapping($algorithmIndex, $parameterNumber)");
    // Update internal state
    (_mappings[algorithmIndex] ??= {})[parameterNumber] = data;
  }

  @override
  Future<void> requestSetPresetName(String name) async {
    debugPrint("[Offline] requestSetPresetName: $name");
    // Update internal state name
    _presetName = name;
  }

  @override
  Future<void> requestSavePreset() async {
    print("[Offline] requestSavePreset - No-op");
  }

  @override
  Future<void> requestLoadPreset(String name, bool append) async {
    print("[Offline] requestLoadPreset - No-op");
  }

  @override
  Future<void> requestNewPreset() async {
    print("[Offline] requestNewPreset - No-op");
  }

  @override
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications) async {
    debugPrint(
        "[Offline] requestAddAlgorithm: Adding GUID ${algorithm.guid}. New count: ${_presetAlgorithmGuids.length + 1}");
    _presetAlgorithmGuids.add(algorithm.guid);
    // Initialize default state for the new slot
    final slotIndex = _presetAlgorithmGuids.length - 1;
    _parameterValues[slotIndex] =
        {}; // Start with empty values, defaults will be read
    _mappings[slotIndex] = {};
    _routingInfo[slotIndex] = [];
    _customNames.remove(slotIndex);

    // Note: We are not using the specifications here yet.
    // A more complete simulation might store these or parameter defaults.
  }

  @override
  Future<void> requestRemoveAlgorithm(int algorithmIndex) async {
    if (algorithmIndex >= 0 && algorithmIndex < _presetAlgorithmGuids.length) {
      final guid = _presetAlgorithmGuids.removeAt(algorithmIndex);
      debugPrint(
          "[Offline] requestRemoveAlgorithm: Removed GUID $guid at index $algorithmIndex. New count: ${_presetAlgorithmGuids.length}");
      // Clear state associated with the removed slot and shift subsequent indices
      _removeAndShiftState(algorithmIndex);
    } else {
      debugPrint(
          "[Offline] requestRemoveAlgorithm: Invalid index $algorithmIndex for preset size ${_presetAlgorithmGuids.length}");
    }
  }

  @override
  Future<void> requestMoveAlgorithmUp(int algorithmIndex) async {
    if (algorithmIndex > 0 && algorithmIndex < _presetAlgorithmGuids.length) {
      final guid = _presetAlgorithmGuids.removeAt(algorithmIndex);
      _presetAlgorithmGuids.insert(algorithmIndex - 1, guid);
      debugPrint(
          "[Offline] requestMoveAlgorithmUp: Moved index $algorithmIndex up. New order: ${_presetAlgorithmGuids}");
      // Shift associated state
      _shiftStateUp(algorithmIndex);
    } else {
      debugPrint(
          "[Offline] requestMoveAlgorithmUp: Cannot move index $algorithmIndex up from preset size ${_presetAlgorithmGuids.length}");
    }
  }

  @override
  Future<void> requestMoveAlgorithmDown(int algorithmIndex) async {
    if (algorithmIndex >= 0 &&
        algorithmIndex < _presetAlgorithmGuids.length - 1) {
      final guid = _presetAlgorithmGuids.removeAt(algorithmIndex);
      _presetAlgorithmGuids.insert(algorithmIndex + 1, guid);
      debugPrint(
          "[Offline] requestMoveAlgorithmDown: Moved index $algorithmIndex down. New order: ${_presetAlgorithmGuids}");
      // Shift associated state
      _shiftStateDown(algorithmIndex);
    } else {
      debugPrint(
          "[Offline] requestMoveAlgorithmDown: Cannot move index $algorithmIndex down from preset size ${_presetAlgorithmGuids.length}");
    }
  }

  @override
  Future<void> requestSendSlotName(int algorithmIndex, String newName) async {
    debugPrint(
        "[Offline] requestSendSlotName: Index $algorithmIndex, Name: $newName");
    if (algorithmIndex >= 0 && algorithmIndex < _presetAlgorithmGuids.length) {
      _customNames[algorithmIndex] = newName;
    } else {
      debugPrint(
          "[Offline] requestSendSlotName: Invalid index $algorithmIndex");
    }
  }

  // --- Communication/Device Specific Implementations (No-ops) ---

  @override
  Future<Uint8List?> encodeTakeScreenshot() async {
    print("[Offline] encodeTakeScreenshot - Returning null");
    return null; // No screenshot capability offline
  }

  @override
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber) async {
    print("[Offline] requestSetFocus - No-op");
  }

  @override
  Future<void> requestSetDisplayMode(DisplayMode displayMode) async {
    print("[Offline] requestSetDisplayMode - No-op");
  }

  @override
  Future<void> requestWake() async {
    print("[Offline] requestWake - No-op");
  }

  @override
  Stream<MidiPacket> get midiDataStream => Stream.empty(); // No MIDI stream

  @override
  MidiDevice? get inputDevice => null; // No input device

  @override
  MidiDevice? get outputDevice => null; // No output device

  // Helper to get GUID for an index and run a DB query
  Future<T?> _runForGuid<T>(
      int algorithmIndex, Future<T?> Function(String guid) queryRunner,
      {T? errorValue}) async {
    if (algorithmIndex < 0 || algorithmIndex >= _presetAlgorithmGuids.length) {
      debugPrint(
          "[Offline] _runForGuid: Index $algorithmIndex out of bounds for preset size ${_presetAlgorithmGuids.length}");
      return errorValue;
    }
    final guid = _presetAlgorithmGuids[algorithmIndex];

    try {
      return await queryRunner(guid);
    } catch (e, stackTrace) {
      debugPrint(
          "[Offline] Error running query for guid $guid (index $algorithmIndex): $e");
      debugPrintStack(stackTrace: stackTrace);
      return errorValue;
    }
  }

  // Helper method to construct FullPresetDetails from internal state
  Future<FullPresetDetails> getCurrentPresetDetails() async {
    // Need the PresetsDao to potentially create/find the PresetEntry ID
    final presetsDao = _database.presetsDao;
    // Find or create the preset entry for our offline state
    PresetEntry? presetEntry = await presetsDao.getPresetByName(_presetName);
    if (presetEntry == null) {
      // Create if it doesn't exist (using default name?)
      final id = await presetsDao.db
          .into(presetsDao.db.presets)
          .insert(PresetsCompanion.insert(name: _presetName));
      presetEntry = await presetsDao.getPresetById(id);
      if (presetEntry == null) {
        throw Exception("Failed to create/find offline preset entry in DB");
      }
    }

    final List<FullPresetSlot> slots = [];
    for (int i = 0; i < _presetAlgorithmGuids.length; i++) {
      final guid = _presetAlgorithmGuids[i];
      // Fetch base algorithm info
      final algoEntry = await (_metadataDao.select(_metadataDao.algorithms)
            ..where((a) => a.guid.equals(guid)))
          .getSingle();

      slots.add(FullPresetSlot(
          slot: PresetSlotEntry(
              id: -1,
              presetId: presetEntry.id,
              slotIndex: i,
              algorithmGuid: guid,
              customName:
                  _customNames[i]), // ID is irrelevant for saving logic in DAO
          algorithm: algoEntry,
          parameterValues: _parameterValues[i] ?? {},
          mappings: _mappings[i] ?? {},
          routingInfo: _routingInfo[i] ?? []));
    }

    return FullPresetDetails(preset: presetEntry, slots: slots);
  }

  // --- Internal State Shifting Helpers ---

  void _removeAndShiftState(int removedIndex) {
    _parameterValues.remove(removedIndex);
    _mappings.remove(removedIndex);
    _routingInfo.remove(removedIndex);
    final removedName = _customNames.remove(removedIndex);
    if (removedName != null) {
      _customNames.remove(removedIndex);
    } else {
      // If no name was shifted, remove the potential old name at index i
      _customNames.remove(removedIndex);
    }

    // Shift subsequent indices down by 1
    for (int i = removedIndex; i < _presetAlgorithmGuids.length; i++) {
      _parameterValues[i] = _parameterValues.remove(i + 1) ?? {};
      _mappings[i] = _mappings.remove(i + 1) ?? {};
      _routingInfo[i] = _routingInfo.remove(i + 1) ?? [];
      final removedName = _customNames.remove(i + 1);
      if (removedName != null) {
        _customNames[i] = removedName;
      } else {
        // If no name was shifted, remove the potential old name at index i
        _customNames.remove(i);
      }
    }
    // Remove the last index key if it exists after shifting
    final lastIndex = _presetAlgorithmGuids.length;
    _parameterValues.remove(lastIndex);
    _mappings.remove(lastIndex);
    _routingInfo.remove(lastIndex);
    _customNames.remove(lastIndex);
  }

  void _shiftStateUp(int movedIndex) {
    // Data at movedIndex needs to go to movedIndex - 1
    // Data originally at movedIndex - 1 needs to go to movedIndex
    final movingData = _getStateForIndex(movedIndex);
    final otherData = _getStateForIndex(movedIndex - 1);

    _setStateForIndex(movedIndex - 1, movingData);
    _setStateForIndex(movedIndex, otherData);
  }

  void _shiftStateDown(int movedIndex) {
    // Data at movedIndex needs to go to movedIndex + 1
    // Data originally at movedIndex + 1 needs to go to movedIndex
    final movingData = _getStateForIndex(movedIndex);
    final otherData = _getStateForIndex(movedIndex + 1);

    _setStateForIndex(movedIndex + 1, movingData);
    _setStateForIndex(movedIndex, otherData);
  }

  Map<String, dynamic> _getStateForIndex(int index) {
    return {
      'values': _parameterValues[index] ?? {},
      'mappings': _mappings[index] ?? {},
      'routing': _routingInfo[index] ?? [],
      'name': _customNames[index],
    };
  }

  void _setStateForIndex(int index, Map<String, dynamic> data) {
    _parameterValues[index] = Map<int, int>.from(data['values']);
    _mappings[index] = Map<int, PackedMappingData>.from(data['mappings']);
    _routingInfo[index] = List<int>.from(data['routing']);
    if (data['name'] != null) {
      _customNames[index] = data['name'];
    } else {
      _customNames.remove(index);
    }
  }
}
