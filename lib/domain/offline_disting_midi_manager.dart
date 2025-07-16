import 'dart:math'; // Added for pow
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:nt_helper/db/database.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart';

import 'package:nt_helper/domain/i_disting_midi_manager.dart'
    show IDistingMidiManager;
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:flutter/foundation.dart';
import '../db/daos/presets_dao.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/sd_card_file_system.dart';

/// An implementation of [IDistingMidiManager] that interacts with the
/// cached database instead of a physical MIDI device.
class OfflineDistingMidiManager implements IDistingMidiManager {
  final AppDatabase _database;
  late final MetadataDao _metadataDao;

  // Internal state for the simulated preset
  int? _loadedPresetId;
  final List<String> _presetAlgorithmGuids = [];
  final Map<int, Map<int, int>> _parameterValues = {};
  final Map<int, Map<int, String>> _parameterStringValues = {};
  final Map<int, Map<int, PackedMappingData>> _mappings = {};
  final Map<int, String> _customNames = {};
  final Map<int, String> _defaultNames = {};
  String _presetName = "Offline Preset";

  OfflineDistingMidiManager(this._database) {
    _metadataDao = _database.metadataDao;
  }

  // Initialize state from loaded preset details
  Future<void> initializeFromDb(FullPresetDetails? details) async {
    _presetAlgorithmGuids.clear();
    _parameterValues.clear();
    _parameterStringValues.clear();
    _mappings.clear();
    _customNames.clear();
    _defaultNames.clear();
    _loadedPresetId = null;

    if (details == null) {
      _presetName = "Offline Preset";
      return;
    }

    _loadedPresetId = details.preset.id;
    _presetName = details.preset.name;
    for (int i = 0; i < details.slots.length; i++) {
      final slotData = details.slots[i];
      final guid = slotData.algorithm.guid;
      _presetAlgorithmGuids.add(guid);

      // Calculate default name with instance number during init
      String baseName = slotData.algorithm.name;
      int instanceCount = 0;
      for (int j = 0; j < i; j++) {
        if (_presetAlgorithmGuids[j] == guid) {
          instanceCount++;
        }
      }
      if (instanceCount > 0) {
        _defaultNames[i] = "$baseName ${instanceCount + 1}";
      } else {
        _defaultNames[i] = baseName;
      }

      _parameterValues[i] = Map.from(slotData.parameterValues);
      _parameterStringValues[i] = Map.from(slotData.parameterStringValues);
      _mappings[i] = Map.from(slotData.mappings);
      if (slotData.slot.customName != null) {
        _customNames[i] = slotData.slot.customName!;
      }
    }
    debugPrint(
        "[Offline] Initialized manager state from DB preset '$_presetName' (ID: $_loadedPresetId). Slots: ${_presetAlgorithmGuids.length}");
  }

  @override
  void dispose() {
    // No resources to dispose for the offline manager
    debugPrint("OfflineDistingMidiManager disposed.");
  }

  // --- Metadata Request Implementations ---

  @override
  Future<int?> requestNumberOfAlgorithms() async {
    try {
      final algorithms = await _metadataDao.getAllAlgorithms();
      return algorithms.length;
    } catch (e) {
      debugPrint("Error fetching algorithm count from DB: $e");
      return 0;
    }
  }

  @override
  Future<AlgorithmInfo?> requestAlgorithmInfo(int algorithmIndex) async {
    try {
      final algorithms = await _metadataDao.getAllAlgorithms();
      if (algorithmIndex < 0 || algorithmIndex >= algorithms.length) {
        return null;
      }
      final entry = algorithms[algorithmIndex];
      final specs = await (_metadataDao.select(_metadataDao.specifications)
            ..where((s) => s.algorithmGuid.equals(entry.guid))
            ..orderBy([(s) => OrderingTerm.asc(s.specIndex)]))
          .get();

      return AlgorithmInfo(
        algorithmIndex: algorithmIndex,
        guid: entry.guid,
        name: entry.name,
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
    } catch (e) {
      debugPrint("Error fetching AlgorithmInfo($algorithmIndex) from DB: $e");
      return null;
    }
  }

  @override
  Future<Algorithm?> requestAlgorithmGuid(int algorithmIndex) async {
    if (algorithmIndex < 0 || algorithmIndex >= _presetAlgorithmGuids.length) {
      debugPrint(
          "[Offline] requestAlgorithmGuid: Index $algorithmIndex out of bounds for preset size ${_presetAlgorithmGuids.length}");
      return null;
    }
    final guid = _presetAlgorithmGuids[algorithmIndex];

    try {
      final algoEntry = await (_metadataDao.select(_metadataDao.algorithms)
            ..where((a) => a.guid.equals(guid)))
          .getSingleOrNull();

      if (algoEntry != null) {
        // Retrieve pre-calculated default name and custom name
        final defaultName = _defaultNames[algorithmIndex];
        final customName = _customNames[algorithmIndex];

        return Algorithm(
          algorithmIndex: algorithmIndex,
          guid: algoEntry.guid,
          name: customName ?? defaultName ?? "Error: Name Missing",
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
    return _runForGuid<ParameterInfo?>(algorithmIndex, (guid) async {
      final paramEntry = await (_metadataDao.select(_metadataDao.parameters)
            ..where((p) =>
                p.algorithmGuid.equals(guid) &
                p.parameterNumber.equals(parameterNumber)))
          .getSingleOrNull();

      if (paramEntry != null) {
        return ParameterInfo(
          algorithmIndex: algorithmIndex,
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
    final value = _parameterValues[algorithmIndex]?[parameterNumber];

    if (value != null) {
      return ParameterValue(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameterNumber,
          value: value);
    } else {
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
    return _runForGuid<AllParameterValues?>(algorithmIndex, (guid) async {
      final numParams = await requestNumberOfParameters(algorithmIndex);
      final count = numParams?.numParameters ?? 0;
      final values = <ParameterValue>[];
      for (int i = 0; i < count; i++) {
        final pValue = await requestParameterValue(algorithmIndex, i);
        if (pValue != null) {
          values.add(pValue);
        } else {
          values.add(ParameterValue(
              algorithmIndex: algorithmIndex, parameterNumber: i, value: 0));
        }
      }
      return AllParameterValues(algorithmIndex: algorithmIndex, values: values);
    }, errorValue: null);
  }

  @override
  Future<ParameterPages?> requestParameterPages(int algorithmIndex) {
    return _runForGuid<ParameterPages?>(algorithmIndex, (guid) async {
      final pagesQuery = _metadataDao.select(_metadataDao.parameterPages)
        ..where((p) => p.algorithmGuid.equals(guid))
        ..orderBy([(p) => OrderingTerm.asc(p.pageIndex)]);
      final pageEntries = await pagesQuery.get();

      final itemsQuery = _metadataDao.select(_metadataDao.parameterPageItems)
        ..where((i) => i.algorithmGuid.equals(guid));
      final itemEntries = await itemsQuery.get();

      final Map<int, List<int>> itemsByPageIndex = {};
      for (final item in itemEntries) {
        (itemsByPageIndex[item.pageIndex] ??= []).add(item.parameterNumber);
        itemsByPageIndex[item.pageIndex]!.sort();
      }

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
    if (algorithmIndex < 0 || algorithmIndex >= _presetAlgorithmGuids.length) {
      return Future.value(ParameterEnumStrings.filler());
    }
    final String guid = _presetAlgorithmGuids[algorithmIndex];

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
        return ParameterEnumStrings.filler();
      }
    } catch (e, stackTrace) {
      debugPrint(
          "[Offline] Error fetching enums for guid $guid, param $parameterNumber: $e");
      debugPrintStack(stackTrace: stackTrace);
      return ParameterEnumStrings.filler();
    }
  }

  @override
  Future<ParameterValueString?> requestParameterValueString(
      int algorithmIndex, int parameterNumber) async {
    final stringValue =
        _parameterStringValues[algorithmIndex]?[parameterNumber];

    if (stringValue != null) {
      return ParameterValueString(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: stringValue,
      );
    } else {
      final paramValue =
          await requestParameterValue(algorithmIndex, parameterNumber);
      if (paramValue == null) return ParameterValueString.filler();
      final paramInfo =
          await requestParameterInfo(algorithmIndex, parameterNumber);
      if (paramInfo == null) return ParameterValueString.filler();
      final unitStrings = await requestUnitStrings() ?? [];
      final unitStr = paramInfo.getUnitString(unitStrings);

      String generatedStringValue;
      if (paramInfo.unit == 1) {
        final enums =
            await requestParameterEnumStrings(algorithmIndex, parameterNumber);
        if (enums != null &&
            enums.values.isNotEmpty &&
            paramValue.value >= 0 &&
            paramValue.value < enums.values.length) {
          generatedStringValue = enums.values[paramValue.value];
        } else {
          generatedStringValue = paramValue.value.toString();
        }
      } else if (unitStr != null && unitStr.isNotEmpty) {
        if (paramInfo.powerOfTen != 0) {
          double actualValue =
              paramValue.value / (pow(10, paramInfo.powerOfTen));
          generatedStringValue = "${actualValue.toStringAsFixed(2)}$unitStr";
        } else {
          generatedStringValue = "${paramValue.value}$unitStr";
        }
      } else {
        generatedStringValue = paramValue.value.toString();
      }

      return ParameterValueString(
        algorithmIndex: algorithmIndex,
        parameterNumber: parameterNumber,
        value: generatedStringValue,
      );
    }
  }

  @override
  Future<Mapping?> requestMappings(int algorithmIndex, int parameterNumber) {
    final mapping = _mappings[algorithmIndex]?[parameterNumber];
    if (mapping != null) {
      return Future.value(Mapping(
          algorithmIndex: algorithmIndex,
          parameterNumber: parameterNumber,
          packedMappingData: mapping));
    } else {
      return Future.value(Mapping.filler());
    }
  }

  @override
  Future<RoutingInfo?> requestRoutingInformation(int algorithmIndex) {
    // Routing information is not stored or handled in offline mode.
    debugPrint("[Offline] requestRoutingInformation - Not supported.");
    return Future.value(RoutingInfo.filler());
  }

  @override
  Future<String?> requestPresetName() async {
    return _presetName;
  }

  @override
  Future<int?> requestNumAlgorithmsInPreset() async {
    return _presetAlgorithmGuids.length;
  }

  @override
  Future<NumParameters?> requestNumberOfParameters(int algorithmIndex) {
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
    return "Offline Mode v0.1";
  }

  @override
  Future<List<String>?> requestUnitStrings() async {
    try {
      final cachedUnits = await _metadataDao.getOrderedUnitStrings();
      if (cachedUnits != null) {
        return cachedUnits;
      } else {
        return [];
      }
    } catch (e, stackTrace) {
      debugPrint("[Offline] Error fetching cached UnitStrings from DB: $e");
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  // --- State Mutation Request Implementations ---

  @override
  Future<void> setParameterValue(
      int algorithmIndex, int parameterNumber, int value) async {
    (_parameterValues[algorithmIndex] ??= {})[parameterNumber] = value;
    // Clear the derived string value when the raw value changes
    _parameterStringValues[algorithmIndex]?.remove(parameterNumber);
  }

  @override
  Future<void> setParameterString(
      int algorithmIndex, int parameterNumber, String value) async {
    (_parameterStringValues[algorithmIndex] ??= {})[parameterNumber] = value;
    debugPrint(
        "[Offline] setParameterString: Algo $algorithmIndex, Param $parameterNumber = '$value'");
  }

  @override
  Future<void> requestSetMapping(
      int algorithmIndex, int parameterNumber, PackedMappingData data) async {
    (_mappings[algorithmIndex] ??= {})[parameterNumber] = data;
  }

  @override
  Future<void> requestSetPresetName(String name) async {
    _presetName = name;
    if (_loadedPresetId == null) return;
    try {
      final presetsDao = _database.presetsDao;
      await presetsDao.updatePresetName(_loadedPresetId!, name);
    } catch (e, stackTrace) {
      debugPrint("[Offline] Error updating preset name in DB: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> requestSavePreset({int option = 0}) async {
    debugPrint("[Offline] requestSavePreset: Saving offline state...");
    try {
      final FullPresetDetails? presetDetails =
          await _buildPresetDetailsForSave();
      if (presetDetails == null) {
        debugPrint("[Offline] Failed to build preset details.");
        return;
      }
      final presetsDao = _database.presetsDao;
      final savedPresetId = await presetsDao.saveFullPreset(presetDetails);
      _loadedPresetId = savedPresetId;
      _presetName = presetDetails.preset.name;
      debugPrint(
          "[Offline] Saved state to preset ID $_loadedPresetId ('$_presetName').");
    } catch (e, stackTrace) {
      debugPrint("[Offline] Error saving offline state: $e");
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Future<void> requestLoadPreset(String name, bool append) async {
    debugPrint("[Offline] requestLoadPreset - No-op");
  }

  @override
  Future<void> requestNewPreset() async {
    debugPrint("[Offline] requestNewPreset: Clearing internal state.");
    _presetAlgorithmGuids.clear();
    _parameterValues.clear();
    _parameterStringValues.clear();
    _mappings.clear();
    _customNames.clear();
    _defaultNames.clear();
    _presetName = "Init";
    _loadedPresetId = null;
  }

  @override
  Future<void> requestAddAlgorithm(
      AlgorithmInfo algorithm, List<int> specifications) async {
    // Calculate default name before adding
    String baseName = algorithm.name;
    String guid = algorithm.guid;
    int instanceCount = 0;
    for (int i = 0; i < _presetAlgorithmGuids.length; i++) {
      if (_presetAlgorithmGuids[i] == guid) {
        instanceCount++;
      }
    }
    String defaultName =
        (instanceCount > 0) ? "$baseName ${instanceCount + 1}" : baseName;

    // Add GUID and initialize state maps
    _presetAlgorithmGuids.add(guid);
    final slotIndex = _presetAlgorithmGuids.length - 1;
    _defaultNames[slotIndex] = defaultName;
    _parameterValues[slotIndex] = {};
    _parameterStringValues[slotIndex] = {};
    _mappings[slotIndex] = {};
    _customNames.remove(slotIndex);
  }

  @override
  Future<void> requestRemoveAlgorithm(int algorithmIndex) async {
    if (algorithmIndex >= 0 && algorithmIndex < _presetAlgorithmGuids.length) {
      _presetAlgorithmGuids.removeAt(algorithmIndex);
      _removeAndShiftState(algorithmIndex);
    } else {
      debugPrint(
          "[Offline] requestRemoveAlgorithm: Invalid index $algorithmIndex");
    }
  }

  @override
  Future<void> requestLoadPlugin(String guid) async {
    // No-op in offline mode
  }

  @override
  Future<void> requestMoveAlgorithmUp(int algorithmIndex) async {
    if (algorithmIndex > 0 && algorithmIndex < _presetAlgorithmGuids.length) {
      final guid = _presetAlgorithmGuids.removeAt(algorithmIndex);
      _presetAlgorithmGuids.insert(algorithmIndex - 1, guid);
      _shiftStateUp(algorithmIndex);
    } else {
      debugPrint(
          "[Offline] requestMoveAlgorithmUp: Cannot move index $algorithmIndex up");
    }
  }

  @override
  Future<void> requestMoveAlgorithmDown(int algorithmIndex) async {
    if (algorithmIndex >= 0 &&
        algorithmIndex < _presetAlgorithmGuids.length - 1) {
      final guid = _presetAlgorithmGuids.removeAt(algorithmIndex);
      _presetAlgorithmGuids.insert(algorithmIndex + 1, guid);
      _shiftStateDown(algorithmIndex);
    } else {
      debugPrint(
          "[Offline] requestMoveAlgorithmDown: Cannot move index $algorithmIndex down");
    }
  }

  @override
  Future<void> requestSendSlotName(int algorithmIndex, String newName) async {
    if (algorithmIndex >= 0 && algorithmIndex < _presetAlgorithmGuids.length) {
      _customNames[algorithmIndex] = newName;
    } else {
      debugPrint(
          "[Offline] requestSendSlotName: Invalid index $algorithmIndex");
    }
  }

  @override
  Future<String?> executeLua(String luaScript) async {
    debugPrint("[Offline] executeLua: script='$luaScript'");
    // Lua execution is not supported in offline mode
    throw UnsupportedError('Lua execution is not available in offline mode');
  }

  @override
  Future<String?> installLua(int algorithmIndex, String luaScript) async {
    debugPrint(
        "[Offline] installLua: algo=$algorithmIndex, script='$luaScript'");
    // Lua installation is not supported in offline mode
    throw UnsupportedError('Lua installation is not available in offline mode');
  }

  // --- Communication/Device Specific Implementations (No-ops/Fillers) ---

  @override
  Future<Uint8List?> encodeTakeScreenshot() async {
    return null;
  }

  @override
  Future<void> requestSetFocus(int algorithmIndex, int parameterNumber) async {}

  @override
  Future<void> requestSetDisplayMode(DisplayMode displayMode) async {}

  @override
  Future<void> requestSetRealTimeClock(int unixTimeSeconds) async {}

  @override
  Future<void> requestWake() async {}

  Stream<MidiPacket> get midiDataStream => Stream.empty();

  Future<MidiDevice?> get inputDevice async => null;

  Future<MidiDevice?> get outputDevice async => null;

  // --- Helper Methods ---

  Future<T?> _runForGuid<T>(
      int algorithmIndex, Future<T?> Function(String guid) queryRunner,
      {T? errorValue}) async {
    if (algorithmIndex < 0 || algorithmIndex >= _presetAlgorithmGuids.length) {
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

  Future<FullPresetDetails?> _buildPresetDetailsForSave() async {
    final PresetEntry presetEntry;
    if (_loadedPresetId != null) {
      presetEntry = PresetEntry(
          id: _loadedPresetId!,
          name: _presetName,
          lastModified: DateTime.now());
    } else {
      presetEntry =
          PresetEntry(id: -1, name: _presetName, lastModified: DateTime.now());
    }

    final List<FullPresetSlot> slots = [];
    for (int i = 0; i < _presetAlgorithmGuids.length; i++) {
      final guid = _presetAlgorithmGuids[i];
      final algoEntry = await (_metadataDao.select(_metadataDao.algorithms)
            ..where((a) => a.guid.equals(guid)))
          .getSingleOrNull();

      if (algoEntry == null) {
        debugPrint(
            "[Offline] Warning: Algorithm metadata missing for GUID $guid.");
        return null;
      }

      slots.add(FullPresetSlot(
        slot: PresetSlotEntry(
          id: -1,
          presetId: presetEntry.id,
          slotIndex: i,
          algorithmGuid: guid,
          customName: _customNames[i],
        ),
        algorithm: algoEntry,
        parameterValues: _parameterValues[i] ?? {},
        parameterStringValues: _parameterStringValues[i] ?? {},
        mappings: _mappings[i] ?? {},
      ));
    }
    return FullPresetDetails(preset: presetEntry, slots: slots);
  }

  // --- Internal State Shifting Helpers ---

  void _removeAndShiftState(int removedIndex) {
    _parameterValues.remove(removedIndex);
    _parameterStringValues.remove(removedIndex);
    _mappings.remove(removedIndex);
    _customNames.remove(removedIndex);
    _defaultNames.remove(removedIndex);

    for (int i = removedIndex; i < _presetAlgorithmGuids.length; i++) {
      _parameterValues[i] = _parameterValues.remove(i + 1) ?? {};
      _parameterStringValues[i] = _parameterStringValues.remove(i + 1) ?? {};
      _mappings[i] = _mappings.remove(i + 1) ?? {};
      final movedCustomName = _customNames.remove(i + 1);
      if (movedCustomName != null) {
        _customNames[i] = movedCustomName;
      } else {
        _customNames.remove(i);
      }
      final movedDefaultName = _defaultNames.remove(i + 1);
      if (movedDefaultName != null) {
        _defaultNames[i] = movedDefaultName;
      } else {
        _defaultNames.remove(i);
      }
    }
    final lastIndex = _presetAlgorithmGuids.length;
    _parameterValues.remove(lastIndex);
    _parameterStringValues.remove(lastIndex);
    _mappings.remove(lastIndex);
    _customNames.remove(lastIndex);
    _defaultNames.remove(lastIndex);
  }

  void _shiftStateUp(int movedIndex) {
    final movingDefaultName = _defaultNames[movedIndex];
    final otherDefaultName = _defaultNames[movedIndex - 1];
    final movingCustomName = _customNames[movedIndex];
    final otherCustomName = _customNames[movedIndex - 1];

    final tempValues = _parameterValues[movedIndex - 1];
    _parameterValues[movedIndex - 1] = _parameterValues[movedIndex] ?? {};
    _parameterValues[movedIndex] = tempValues ?? {};

    final tempStringValues = _parameterStringValues[movedIndex - 1];
    _parameterStringValues[movedIndex - 1] =
        _parameterStringValues[movedIndex] ?? {};
    _parameterStringValues[movedIndex] = tempStringValues ?? {};

    final tempMappings = _mappings[movedIndex - 1];
    _mappings[movedIndex - 1] = _mappings[movedIndex] ?? {};
    _mappings[movedIndex] = tempMappings ?? {};

    if (movingDefaultName != null) {
      _defaultNames[movedIndex - 1] = movingDefaultName;
    } else {
      _defaultNames.remove(movedIndex - 1);
    }
    if (otherDefaultName != null) {
      _defaultNames[movedIndex] = otherDefaultName;
    } else {
      _defaultNames.remove(movedIndex);
    }

    if (movingCustomName != null) {
      _customNames[movedIndex - 1] = movingCustomName;
    } else {
      _customNames.remove(movedIndex - 1);
    }
    if (otherCustomName != null) {
      _customNames[movedIndex] = otherCustomName;
    } else {
      _customNames.remove(movedIndex);
    }
  }

  void _shiftStateDown(int movedIndex) {
    final movingDefaultName = _defaultNames[movedIndex];
    final otherDefaultName = _defaultNames[movedIndex + 1];
    final movingCustomName = _customNames[movedIndex];
    final otherCustomName = _customNames[movedIndex + 1];

    final tempValues = _parameterValues[movedIndex];
    _parameterValues[movedIndex] = _parameterValues[movedIndex + 1] ?? {};
    _parameterValues[movedIndex + 1] = tempValues ?? {};

    final tempStringValues = _parameterStringValues[movedIndex];
    _parameterStringValues[movedIndex] =
        _parameterStringValues[movedIndex + 1] ?? {};
    _parameterStringValues[movedIndex + 1] = tempStringValues ?? {};

    final tempMappings = _mappings[movedIndex];
    _mappings[movedIndex] = _mappings[movedIndex + 1] ?? {};
    _mappings[movedIndex + 1] = tempMappings ?? {};

    if (movingDefaultName != null) {
      _defaultNames[movedIndex + 1] = movingDefaultName;
    } else {
      _defaultNames.remove(movedIndex + 1);
    }
    if (otherDefaultName != null) {
      _defaultNames[movedIndex] = otherDefaultName;
    } else {
      _defaultNames.remove(movedIndex);
    }

    if (movingCustomName != null) {
      _customNames[movedIndex + 1] = movingCustomName;
    } else {
      _customNames.remove(movedIndex + 1);
    }
    if (otherCustomName != null) {
      _customNames[movedIndex] = otherCustomName;
    } else {
      _customNames.remove(movedIndex);
    }
  }

  @override
  Future<FullPresetDetails?> requestCurrentPresetDetails() =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<DirectoryListing?> requestDirectoryListing(String path) =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<SdCardStatus?> requestFileDelete(String path) =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<Uint8List?> requestFileDownload(String path) =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<SdCardStatus?> requestFileRename(String fromPath, String toPath) =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<SdCardStatus?> requestFileUpload(String path, Uint8List data) {
    throw UnsupportedError('SD Card write operations not supported offline.');
  }

  @override
  Future<SdCardStatus?> requestFileUploadChunk(
      String path, Uint8List data, int position,
      {bool createAlways = false}) {
    throw UnsupportedError('SD Card write operations not supported offline.');
  }

  @override
  Future<SdCardStatus?> requestDirectoryCreate(String path) =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<void> requestSclFile(String filePath) =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<void> requestKbmFile(String filePath) =>
      throw UnsupportedError('Not available in offline mode');

  @override
  Future<CpuUsage?> requestCpuUsage() async {
    throw UnsupportedError("CPU Usage is not available in offline mode.");
  }

  @override
  Future<void> backupPlugins(String backupDirectory,
          {void Function(double progress, String currentFile)? onProgress}) =>
      throw UnsupportedError('Backup not available in offline mode');
}
