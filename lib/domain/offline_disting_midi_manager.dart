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

/// An implementation of [IDistingMidiManager] that interacts with the
/// cached database instead of a physical MIDI device.
class OfflineDistingMidiManager implements IDistingMidiManager {
  final AppDatabase _database;
  late final MetadataDao _metadataDao;

  // Internal state for the simulated preset
  final List<String> _presetAlgorithmGuids = [];

  OfflineDistingMidiManager(this._database) {
    _metadataDao = _database.metadataDao;
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
          min: paramEntry.minValue,
          max: paramEntry.maxValue,
          defaultValue: paramEntry.defaultValue,
          unit: paramEntry.unitId ??
              0, // Handle null unitId, map to unit (0 = none?)
          name: paramEntry.name,
          powerOfTen: paramEntry.powerOfTen,
        );
      } else {
        return null;
      }
    }, errorValue: null);
  }

  @override
  Future<ParameterValue?> requestParameterValue(
      int algorithmIndex, int parameterNumber) {
    // TODO: Implement requestParameterValue (return default?)
    throw UnimplementedError("requestParameterValue not implemented offline");
  }

  @override
  Future<AllParameterValues?> requestAllParameterValues(int algorithmIndex) {
    // Get GUID, fetch all parameters, return their default values
    return _runForGuid<AllParameterValues?>(algorithmIndex, (guid) async {
      final paramsQuery = _metadataDao.select(_metadataDao.parameters)
        ..where((p) => p.algorithmGuid.equals(guid))
        ..orderBy([(p) => OrderingTerm.asc(p.parameterNumber)]);

      final paramEntries = await paramsQuery.get();

      final values = paramEntries.map((entry) {
        return ParameterValue(
          algorithmIndex: algorithmIndex, // Use preset index
          parameterNumber: entry.parameterNumber,
          value: entry.defaultValue, // Use the stored default value
        );
      }).toList();

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
      int algorithmIndex, int parameterNumber) {
    // Get GUID, fetch enum strings for the specific parameter
    return _runForGuid<ParameterEnumStrings?>(algorithmIndex, (guid) async {
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
    }, errorValue: ParameterEnumStrings.filler()); // Return filler on error
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
    // Return default/filler for now
    debugPrint(
        "[Offline] requestMappings($algorithmIndex, $parameterNumber) - Returning filler");
    return Future.value(Mapping.filler());
  }

  @override
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex) {
    // Return default/filler for now
    debugPrint(
        "[Offline] requestRoutingInformation($algorithmIndex) - Returning filler");
    return Future.value(RoutingInfo.filler());
  }

  @override
  Future<String?> requestPresetName() async {
    return "Offline Preset"; // Fixed name for offline mode
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
    print(
        "[Offline] setParameterValue($algorithmIndex, $parameterNumber, $value) - No-op");
    // No actual device to send to. State needs local management if required.
  }

  @override
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    print("[Offline] requestSetMapping - No-op");
  }

  @override
  Future<void> requestSetPresetName(String name) async {
    print("[Offline] requestSetPresetName - No-op");
    // Could potentially update a local variable if we want to simulate this
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
    debugPrint("[Offline] requestAddAlgorithm: Adding GUID ${algorithm.guid}");
    _presetAlgorithmGuids.add(algorithm.guid);
    // Note: We are not using the specifications here yet.
    // A more complete simulation might store these or parameter defaults.
  }

  @override
  Future<void> requestRemoveAlgorithm(int algorithmIndex) async {
    if (algorithmIndex >= 0 && algorithmIndex < _presetAlgorithmGuids.length) {
      final guid = _presetAlgorithmGuids.removeAt(algorithmIndex);
      debugPrint(
          "[Offline] requestRemoveAlgorithm: Removed GUID $guid at index $algorithmIndex. New count: ${_presetAlgorithmGuids.length}");
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
    } else {
      debugPrint(
          "[Offline] requestMoveAlgorithmDown: Cannot move index $algorithmIndex down from preset size ${_presetAlgorithmGuids.length}");
    }
  }

  @override
  Future<void> requestSendSlotName(int algorithmIndex, String newName) async {
    print("[Offline] requestSendSlotName - No-op");
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
  Future<T> _runForGuid<T>(
      int algorithmIndex, Future<T> Function(String guid) queryRunner,
      {required T errorValue}) async {
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
}
