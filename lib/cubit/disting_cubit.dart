import 'dart:async';

import 'package:async/async.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nt_helper/db/daos/metadata_dao.dart'; // Added
import 'package:nt_helper/db/daos/presets_dao.dart'; // Added
import 'package:nt_helper/db/database.dart'; // Added
import 'package:nt_helper/domain/disting_midi_manager.dart';
import 'package:nt_helper/domain/disting_nt_sysex.dart';
import 'package:nt_helper/domain/i_disting_midi_manager.dart';
import 'package:nt_helper/domain/mock_disting_midi_manager.dart';
import 'package:nt_helper/domain/offline_disting_midi_manager.dart';
import 'package:nt_helper/domain/parameter_update_queue.dart';
import 'package:nt_helper/models/cpu_usage.dart';
import 'package:nt_helper/models/packed_mapping_data.dart';
import 'package:nt_helper/models/package_file.dart';
import 'package:nt_helper/models/plugin_info.dart';
import 'package:nt_helper/models/routing_information.dart';
import 'package:nt_helper/models/firmware_version.dart';
import 'package:nt_helper/util/extensions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart'; // Add collection package import
import 'package:nt_helper/domain/video/video_stream_state.dart';
import 'package:nt_helper/domain/video/usb_video_manager.dart';

part 'disting_cubit.freezed.dart';

part 'disting_state.dart';
part 'disting_cubit_algorithm_ops.dart';
part 'disting_cubit_preset_ops.dart';
part 'disting_cubit_slot_ops.dart';
part 'disting_cubit_offline_demo_delegate.dart';
part 'disting_cubit_parameter_fetch_delegate.dart';
part 'disting_cubit_plugin_delegate.dart';
part 'disting_cubit_connection_delegate.dart';
part 'disting_cubit_parameter_refresh_delegate.dart';
part 'disting_cubit_monitoring_delegate.dart';
part 'disting_cubit_slot_state_delegate.dart';
part 'disting_cubit_algorithm_library_delegate.dart';
part 'disting_cubit_sd_card_delegate.dart';
part 'disting_cubit_lua_reload_delegate.dart';
part 'disting_cubit_parameter_string_delegate.dart';
part 'disting_cubit_mapping_delegate.dart';
part 'disting_cubit_state_refresh_delegate.dart';
part 'disting_cubit_slot_maintenance_delegate.dart';
part 'disting_cubit_parameter_value_delegate.dart';
part 'disting_cubit_hardware_commands_delegate.dart';
part 'disting_cubit_state_helpers_delegate.dart';

// A helper class to track each parameter's polling state.
class _PollingTask {
  bool active = true;
  int noChangeCount = 0;

  _PollingTask();
}

// Retry request types for background parameter retry queue
enum _ParameterRetryType { info, enumStrings, mappings, valueStrings }

// Retry request data structure for background parameter retry queue
class _ParameterRetryRequest {
  final int slotIndex;
  final int paramIndex;
  final _ParameterRetryType type;

  _ParameterRetryRequest({
    required this.slotIndex,
    required this.paramIndex,
    required this.type,
  });
}

abstract class _DistingCubitBase extends Cubit<DistingState> {
  _DistingCubitBase(super.initialState);

  IDistingMidiManager requireDisting();
  Future<Slot> fetchSlot(IDistingMidiManager disting, int algorithmIndex);
  Future<List<Slot>> fetchSlots(
    int numAlgorithmsInPreset,
    IDistingMidiManager disting,
  );
  Future<void> _refreshStateFromManager({
    Duration delay,
  });
  Slot _fixAlgorithmIndex(Slot slot, int algorithmIndex);
  List<Slot> updateSlot(
    int algorithmIndex,
    List<Slot> slots,
    Slot Function(Slot) updateFunction,
  );
}

class DistingCubit extends _DistingCubitBase
    with _DistingCubitPresetOps, _DistingCubitSlotOps, _DistingCubitAlgorithmOps {
  final AppDatabase database; // Renamed from _database to make it public
  late final MetadataDao _metadataDao; // Added
  final Future<SharedPreferences> _prefs;
  FirmwareVersion? _lastKnownFirmwareVersion;
  late final _OfflineDemoDelegate _offlineDemoDelegate = _OfflineDemoDelegate(
    this,
  );
  late final _ParameterFetchDelegate _parameterFetchDelegate =
      _ParameterFetchDelegate(this);
  late final _PluginDelegate _pluginDelegate = _PluginDelegate(this);
  late final _ConnectionDelegate _connectionDelegate = _ConnectionDelegate(this);
  late final _ParameterRefreshDelegate _parameterRefreshDelegate =
      _ParameterRefreshDelegate(this);
  late final _MonitoringDelegate _monitoringDelegate = _MonitoringDelegate(this);
  late final _SlotStateDelegate _slotStateDelegate = _SlotStateDelegate(this);
  late final _AlgorithmLibraryDelegate _algorithmLibraryDelegate =
      _AlgorithmLibraryDelegate(this);
  late final _SdCardDelegate _sdCardDelegate = _SdCardDelegate(this);
  late final _LuaReloadDelegate _luaReloadDelegate = _LuaReloadDelegate(this);
  late final _ParameterStringDelegate _parameterStringDelegate =
      _ParameterStringDelegate(this);
  late final _MappingDelegate _mappingDelegate = _MappingDelegate(this);
  late final _StateRefreshDelegate _stateRefreshDelegate =
      _StateRefreshDelegate(this);
  late final _SlotMaintenanceDelegate _slotMaintenanceDelegate =
      _SlotMaintenanceDelegate(this);
  late final _ParameterValueDelegate _parameterValueDelegate =
      _ParameterValueDelegate(this);
  late final _HardwareCommandsDelegate _hardwareCommandsDelegate =
      _HardwareCommandsDelegate(this);
  late final _StateHelpersDelegate _stateHelpersDelegate =
      _StateHelpersDelegate(this);

  // Modified constructor
  DistingCubit(this.database)
    : _prefs = SharedPreferences.getInstance(),
      super(const DistingState.initial()) {
    _metadataDao =
        database.metadataDao; // Initialize DAO using public database field
  }

  MidiCommand _midiCommand = MidiCommand();

  // MIDI setup change subscription for auto-detecting device connections
  StreamSubscription<String>? _midiSetupSubscription;

  // Keep track of the offline manager instance when offline
  OfflineDistingMidiManager? _offlineManager;

  // Parameter update queue for consolidated parameter changes
  ParameterUpdateQueue? _parameterQueue;

  /// Stream of CPU usage updates that polls every 10 seconds when listeners are active
  Stream<CpuUsage> get cpuUsageStream => _monitoringDelegate.cpuUsageStream;

  /// Stream of video state updates from the cubit's state
  Stream<VideoStreamState?> get videoStreamState => stream.map(
    (state) => state.maybeWhen(
      synchronized:
          (
            disting,
            distingVersion,
            firmwareVersion,
            presetName,
            algorithms,
            slots,
            unitStrings,
            inputDevice,
            outputDevice,
            loading,
            offline,
            screenshot,
            demo,
            videoStream,
          ) => videoStream,
      orElse: () => null,
    ),
  );

  // Added: Store last known online connection details
  MidiDevice? _lastOnlineInputDevice;
  MidiDevice? _lastOnlineOutputDevice;
  int? _lastOnlineSysExId;

  @override
  Future<void> close() {
    disting()?.dispose();
    _offlineManager?.dispose(); // Dispose offline manager too
    _parameterQueue?.dispose(); // Dispose parameter queue
    _midiCommand.dispose();

    // Cancel timers
    _parameterRefreshDelegate.dispose();

    // Cancel MIDI setup listener
    _midiSetupSubscription?.cancel();

    _monitoringDelegate.dispose();

    return super.close();
  }

  Future<void> initialize() async {
    return _connectionDelegate.initialize();
  }

  Future<void> onDemo() async {
    return _offlineDemoDelegate.onDemo();
  }

  // Helper to fetch AlgorithmInfo list from mock/offline manager
  Future<List<AlgorithmInfo>> _fetchMockAlgorithms(
    IDistingMidiManager manager,
  ) async {
    return _algorithmLibraryDelegate.fetchAlgorithmsWithPriority(manager);
  }

  Future<void> loadDevices() async {
    return _connectionDelegate.loadDevices();
  }

  void _stopMidiSetupListener() {
    _connectionDelegate.stopMidiSetupListener();
  }

  Future<Uint8List?> getHardwareScreenshot() async {
    return _hardwareCommandsDelegate.getHardwareScreenshot();
  }

  Future<void> updateScreenshot() async {
    return _hardwareCommandsDelegate.updateScreenshot();
  }

  /// Gets the current CPU usage information from the Disting device.
  /// Returns null if the device is not connected or if the request fails.
  /// Only works when connected to a physical device (not in offline or demo mode).
  Future<CpuUsage?> getCpuUsage() async {
    return _monitoringDelegate.getCpuUsage();
  }

  void disconnect() {
    return _connectionDelegate.disconnect();
  }

  // Private helper to perform the full synchronization and emit the state
  Future<void> _performSyncAndEmit() async {
    return _connectionDelegate.performSyncAndEmit();
  }

  Future<void> connectToDevices(
    MidiDevice inputDevice,
    MidiDevice outputDevice,
    int sysExId,
  ) async {
    return _connectionDelegate.connectToDevices(inputDevice, outputDevice, sysExId);
  }

  // --- Offline Mode Handling ---

  Future<void> goOffline() async {
    return _offlineDemoDelegate.goOffline();
  }

  Future<void> goOnline() async {
    return _offlineDemoDelegate.goOnline();
  }

  Future<void> cancelSync() async {
    disconnect();
    await loadDevices();
  }

  Future<void> loadPresetOffline(FullPresetDetails presetDetails) async {
    return _offlineDemoDelegate.loadPresetOffline(presetDetails);
  }

  void _emitState(DistingState next) {
    emit(next);
  }

  // Helper to fetch algorithm metadata for offline mode
  Future<List<AlgorithmInfo>> _fetchOfflineAlgorithms() async {
    return _stateHelpersDelegate.fetchOfflineAlgorithms();
  }

  /// Refreshes the state from the current manager (online or offline).
  /// By default, performs a fast refresh of preset data only.
  /// Set [fullRefresh] to true to also re-download the algorithm library (online only).
  Future<void> refresh({bool fullRefresh = false}) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      if (fullRefresh && !currentState.offline) {
        // Full refresh: re-download everything including algorithm library (online only)
        await _performSyncAndEmit();
      } else {
        // Fast refresh: only update preset from manager (works in both online and offline)
        await _refreshStateFromManager();

        // Check if we should refresh algorithms in the background (online only)
        if (!currentState.offline &&
            _algorithmLibraryDelegate.shouldRefreshAlgorithms(currentState)) {
          _algorithmLibraryDelegate.refreshAlgorithmsInBackground();
        }
      }
    } else {
      // Optionally handle error or do nothing
    }
  }

  // Helper to create parameter queue for current manager
  void _createParameterQueue() {
    final manager = disting();
    if (manager != null) {
      _parameterQueue?.dispose();
      _parameterQueue = ParameterUpdateQueue(
        midiManager: manager,
        onParameterStringUpdated: _parameterStringDelegate.onParameterStringUpdated,
      );
    }
  }

  void refreshAlgorithms() {
    _algorithmLibraryDelegate.refreshAlgorithms();
  }

  /// Sends rescan plugins command to hardware and refreshes algorithm list.
  /// Used by the Add Algorithm screen's manual rescan button.
  Future<void> rescanPlugins() async {
    return _algorithmLibraryDelegate.rescanPlugins();
  }

  @override
  IDistingMidiManager requireDisting() {
    final d = disting();
    if (d == null) {
      throw Exception("Disting not connected");
    }
    return d;
  }

  IDistingMidiManager? disting() {
    return switch (state) {
      DistingStateConnected(disting: final d) => d,
      DistingStateSynchronized(disting: final d) => d,
      _ => null,
    };
  }

  List<T> replaceInList<T>(List<T> original, T element, {required int index}) {
    if (index < 0 || index > original.length) {
      throw RangeError.index(index, original, "index out of bounds");
    }

    return [
      ...original.sublist(0, index),
      element,
      ...original.sublist(index + 1),
    ];
  }

  @override
  List<Slot> updateSlot(
    int algorithmIndex,
    List<Slot> slots,
    Slot Function(Slot) updateFunction,
  ) {
    return [
      ...slots.sublist(0, algorithmIndex),
      updateFunction(slots[algorithmIndex]),
      ...slots.sublist(algorithmIndex + 1),
    ];
  }

  Future<void> updateParameterValue({
    required int algorithmIndex,
    required int parameterNumber,
    required int value,
    required bool userIsChangingTheValue,
  }) async {
    return _parameterValueDelegate.updateParameterValue(
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
      value: value,
      userIsChangingTheValue: userIsChangingTheValue,
    );
  }

  /// Schedules a debounced parameter refresh (requestAllParameterValues).
  /// If a refresh is already scheduled, the existing timer is cancelled and restarted.
  /// This ensures only one refresh request is sent after a batch of parameter edits.
  /// The actual refresh occurs 300ms after the last call to this method.
  void scheduleParameterRefresh(int algorithmIndex) {
    return _parameterRefreshDelegate.scheduleParameterRefresh(algorithmIndex);
  }

  Future<void> onAlgorithmSelected(
    AlgorithmInfo algorithm,
    List<int> specifications,
  ) async {
    return onAlgorithmSelectedImpl(algorithm, specifications);
  }

  Future<void> onRemoveAlgorithm(int algorithmIndex) async {
    return onRemoveAlgorithmImpl(algorithmIndex);
  }

  void renamePreset(String newName) async {
    renamePresetImpl(newName);
  }

  Future<int> moveAlgorithmUp(int algorithmIndex) async {
    return moveAlgorithmUpImpl(algorithmIndex);
  }

  Future<int> moveAlgorithmDown(int algorithmIndex) async {
    return moveAlgorithmDownImpl(algorithmIndex);
  }

  Future<void> newPreset() async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      final disting = requireDisting();
      await disting.requestNewPreset();
      await _refreshStateFromManager(); // Use helper
    } else {
      // Handle other cases or errors
    }
  }

  Future<void> loadPreset(String name, bool append) async {
    final currentState = state;
    if (currentState is DistingStateSynchronized) {
      // Prevent online load preset when offline
      if (currentState.offline) {
        return;
      }
      final disting = requireDisting();

      emit(currentState.copyWith(loading: true));

      await disting.requestLoadPreset(name, append);

      // Use the common refresh helper
      await _refreshStateFromManager();
    } else {
      // Handle other cases or errors
    }
  }

  Future<void> saveMapping(
    int algorithmIndex,
    int parameterNumber,
    PackedMappingData data,
  ) async {
    return _mappingDelegate.saveMapping(algorithmIndex, parameterNumber, data);
  }

  void renameSlot(int algorithmIndex, String newName) async {
    renameSlotImpl(algorithmIndex, newName);
  }

  /// Sets the performance page assignment for a parameter.
  ///
  /// - [slotIndex]: Slot index (0-31)
  /// - [parameterNumber]: Parameter number within the algorithm
  /// - [perfPageIndex]: Performance page index (0-15, where 0 = not assigned)
  ///
  /// Uses optimistic update pattern:
  /// 1. Update local state immediately for instant UI feedback
  /// 2. Send update to hardware
  /// 3. Verify by reading back specific parameter mapping
  /// 4. If mismatch, hardware value wins and UI updates again
  Future<void> setPerformancePageMapping(
    int slotIndex,
    int parameterNumber,
    int perfPageIndex,
  ) async {
    return _mappingDelegate.setPerformancePageMapping(
      slotIndex,
      parameterNumber,
      perfPageIndex,
    );
  }

  // --- Helper Methods ---

  // Helper to refresh state from the current manager (online or offline)
  @override
  Future<void> _refreshStateFromManager({
    Duration delay = const Duration(milliseconds: 50), // Shorter default delay
  }) async {
    return _stateRefreshDelegate.refreshStateFromManager(delay: delay);
  }

  List<RoutingInformation> buildRoutingInformation() {
    return _stateHelpersDelegate.buildRoutingInformation();
  }

  bool _isProgramParameter(
    DistingStateSynchronized state,
    int algorithmIndex,
    int parameterNumber,
  ) =>
      _stateHelpersDelegate.isProgramParameter(
        state,
        algorithmIndex,
        parameterNumber,
      );

  @override
  Slot _fixAlgorithmIndex(Slot slot, int algorithmIndex) {
    return _slotMaintenanceDelegate.fixAlgorithmIndex(slot, algorithmIndex);
  }

  // Simple program refresh queue with retry logic
  void _queueProgramRefresh(int algorithmIndex) {
    return _parameterRefreshDelegate.queueProgramRefresh(algorithmIndex);
  }

  void setDisplayMode(DisplayMode displayMode) {
    return _hardwareCommandsDelegate.setDisplayMode(displayMode);
  }

  /// Reboots the Disting NT module.
  /// This will cause the module to restart as if power cycled.
  Future<void> reboot() async {
    return _hardwareCommandsDelegate.reboot();
  }

  /// Remounts the SD card file system.
  /// This refreshes the file system without a full reboot.
  Future<void> remountSd() async {
    return _hardwareCommandsDelegate.remountSd();
  }

  static List<MappedParameter> buildMappedParameterList(DistingState state) {
    switch (state) {
      case DistingStateSynchronized():
        // return a list of parameters that have performance page assignments
        // from the state.
        return state.slots.fold(List<MappedParameter>.empty(growable: true), (
          acc,
          slot,
        ) {
          acc.addAll(
            slot.mappings
                .where(
                  (mapping) =>
                      mapping.parameterNumber != -1 &&
                      mapping.packedMappingData.isPerformance(),
                )
                .map((mapping) {
                  var parameterNumber = mapping.parameterNumber;
                  return MappedParameter(
                    parameter: slot.parameters[parameterNumber],
                    value: slot.values[parameterNumber],
                    enums: slot.enums[parameterNumber],
                    valueString: slot.valueStrings[parameterNumber],
                    mapping: mapping,
                    algorithm: slot.algorithm,
                  );
                })
                .toList(),
          );
          return acc;
        });
      default:
        return [];
    }
  }

  // Starts polling for each mapped parameter.
  void startPollingMappedParameters() {
    return _parameterRefreshDelegate.startPollingMappedParameters();
  }

  // Stops all polling tasks.
  void stopPollingMappedParameters() {
    return _parameterRefreshDelegate.stopPollingMappedParameters();
  }

  Future<void> resetOutputs(Slot slot, int outputIndex) async {
    return _slotMaintenanceDelegate.resetOutputs(slot, outputIndex);
  }

  @override
  Future<List<Slot>> fetchSlots(
    int numAlgorithmsInPreset,
    IDistingMidiManager disting,
  ) async {
    return _parameterFetchDelegate.fetchSlots(numAlgorithmsInPreset, disting);
  }

  /// Get output mode usage data for a parameter.
  /// Returns list of affected parameter numbers, or null if not available.
  List<int>? getOutputModeUsage(int slotIndex, int paramIndex) {
    return _slotStateDelegate.getOutputModeUsage(slotIndex, paramIndex);
  }

  /// Get all output mode usage data for a slot.
  Map<int, List<int>>? getSlotOutputModeUsage(int slotIndex) {
    return _slotStateDelegate.getSlotOutputModeUsage(slotIndex);
  }

  @override
  Future<Slot> fetchSlot(
    IDistingMidiManager disting,
    int algorithmIndex,
  ) async {
    return _parameterFetchDelegate.fetchSlot(disting, algorithmIndex);
  }

  Future<void> refreshRouting() async {
    return _slotStateDelegate.refreshRouting();
  }

  Future<void> _refreshSlotAfterAnomaly(int algorithmIndex) async {
    return _slotMaintenanceDelegate.refreshSlotAfterAnomaly(algorithmIndex);
  }

  Future<List<String>> scanSdCardPresets() async {
    return _sdCardDelegate.scanSdCardPresets();
  }

  /// Scans the SD card on the connected disting for .json files.
  /// Returns a sorted list of relative paths (e.g., "presets/my_preset.json").
  /// Only available if firmware has SD card support.
  Future<List<String>> fetchSdCardPresets() async {
    return _sdCardDelegate.fetchSdCardPresets();
  }

  /// Scans for Lua script plugins in the /programs/lua directory.
  /// Returns a sorted list of .lua files found.
  Future<List<PluginInfo>> fetchLuaPlugins() async {
    return _pluginDelegate.fetchLuaPlugins();
  }

  /// Scans for 3pot plugins in the /programs/3pot directory.
  /// Returns a sorted list of .3pot files found.
  Future<List<PluginInfo>> fetch3potPlugins() async {
    return _pluginDelegate.fetch3potPlugins();
  }

  /// Scans for C++ plugins in the /programs/plug-ins directory.
  /// Returns a sorted list of .o files found.
  Future<List<PluginInfo>> fetchCppPlugins() async {
    return _pluginDelegate.fetchCppPlugins();
  }

  /// Refreshes parameter strings for a specific slot only
  Future<void> refreshSlotParameterStrings(int algorithmIndex) async {
    return _parameterStringDelegate.refreshSlotParameterStrings(algorithmIndex);
  }

  /// Refreshes a single slot's data from the module
  Future<void> refreshSlot(int algorithmIndex) async {
    return _slotMaintenanceDelegate.refreshSlot(algorithmIndex);
  }

  Future<void> updateParameterString({
    required int algorithmIndex,
    required int parameterNumber,
    required String value,
  }) async {
    return _parameterStringDelegate.updateParameterString(
      algorithmIndex: algorithmIndex,
      parameterNumber: parameterNumber,
      value: value,
    );
  }

  /// Starts the USB video stream from the Disting NT device
  Future<void> startVideoStream() async {
    return _monitoringDelegate.startVideoStream();
  }

  /// Stops the USB video stream
  Future<void> stopVideoStream() async {
    return _monitoringDelegate.stopVideoStream();
  }

  /// Gets the current video stream state
  VideoStreamState? get currentVideoState => _monitoringDelegate.currentVideoState;

  /// Gets the video manager for direct stream access
  UsbVideoManager? get videoManager => _monitoringDelegate.videoManager;

  /// Temporarily pause CPU usage polling (useful during sync operations)
  void pauseCpuMonitoring() {
    return _monitoringDelegate.pauseCpuMonitoring();
  }

  /// Resume CPU usage polling if there are listeners
  void resumeCpuMonitoring() {
    return _monitoringDelegate.resumeCpuMonitoring();
  }

  /// Sends a delete command for a plugin file on the SD card.
  /// This is a fire-and-forget operation that assumes success.
  /// Only works when connected to a physical device (not offline/demo mode).
  Future<void> deletePlugin(PluginInfo plugin) async {
    return _pluginDelegate.deletePlugin(plugin);
  }

  /// Uploads a plugin file to the appropriate directory on the SD card.
  /// Files are uploaded in 512-byte chunks to stay within SysEx message limits.
  /// Only works when connected to a physical device (not offline/demo mode).
  Future<void> installPlugin(
    String fileName,
    Uint8List fileData, {
    Function(double)? onProgress,
  }) async {
    return _pluginDelegate.installPlugin(
      fileName,
      fileData,
      onProgress: onProgress,
    );
  }

  /// Forces a Lua script reload while preserving all parameter state.
  /// This is specifically designed for development mode where a script file
  /// has been modified and needs to be reloaded without losing user settings.
  ///
  /// The process: Program=0 (unload) → Program=currentValue (reload) → restore all state
  Future<void> forceReloadLuaScriptWithStatePreservation(
    int algorithmIndex,
    int programParameterNumber,
    int currentProgramValue,
  ) async {
    return _luaReloadDelegate.forceReloadLuaScriptWithStatePreservation(
      algorithmIndex,
      programParameterNumber,
      currentProgramValue,
    );
  }

  /// Backs up all plugins from the Disting NT to a local directory.
  /// Maintains the directory structure (/programs/lua, /programs/three_pot, /programs/plug-ins).
  Future<void> backupPlugins(
    String backupDirectory, {
    void Function(double progress, String currentFile)? onProgress,
  }) async {
    return _pluginDelegate.backupPlugins(
      backupDirectory,
      onProgress: onProgress,
    );
  }

  /// Install multiple files from a preset package in batch
  Future<void> installPackageFiles(
    List<PackageFile> files,
    Map<String, Uint8List> fileData, {
    Function(String fileName, int completed, int total)? onFileStart,
    Function(String fileName, double progress)? onFileProgress,
    Function(String fileName)? onFileComplete,
    Function(String fileName, String error)? onFileError,
  }) async {
    return _pluginDelegate.installPackageFiles(
      files,
      fileData,
      onFileStart: onFileStart,
      onFileProgress: onFileProgress,
      onFileComplete: onFileComplete,
      onFileError: onFileError,
    );
  }

  /// Install a single file to a specific path on the SD card
  Future<void> installFileToPath(
    String targetPath,
    Uint8List fileData, {
    Function(double)? onProgress,
  }) async {
    return _pluginDelegate.installFileToPath(
      targetPath,
      fileData,
      onProgress: onProgress,
    );
  }

  /// Load a plugin using the dedicated 0x38 Load Plugin SysEx command
  /// and refresh the specific algorithm info with updated specifications
  Future<AlgorithmInfo?> loadPlugin(String guid) async {
    return _pluginDelegate.loadPlugin(guid);
  }
}

extension DistingCubitGetters on DistingCubit {
  IDistingMidiManager? disting() {
    return switch (state) {
      DistingStateConnected(disting: final d) => d,
      DistingStateSynchronized(disting: final d) => d,
      _ => null,
    };
  }

  IDistingMidiManager requireDisting() {
    final d = disting();
    if (d == null) {
      throw Exception("Disting not connected");
    }
    return d;
  }
}
