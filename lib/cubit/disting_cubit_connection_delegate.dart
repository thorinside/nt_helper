part of 'disting_cubit.dart';

class _ConnectionDelegate {
  _ConnectionDelegate(this._cubit);

  final DistingCubit _cubit;

  Future<void> initialize() async {
    // Check for offline capability first
    bool canWorkOffline = false; // Default to false
    try {
      canWorkOffline = await _cubit._metadataDao.hasCachedAlgorithms();
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Proceed with canWorkOffline as false
    }

    final prefs = await _cubit._prefs;
    final savedInputDeviceName = prefs.getString('selectedInputMidiDevice');
    final savedOutputDeviceName = prefs.getString('selectedOutputMidiDevice');
    final savedSysExId = prefs.getInt('selectedSysExId');

    if (savedOutputDeviceName != null &&
        savedInputDeviceName != null &&
        savedSysExId != null) {
      // Try to connect to the saved device
      final devices = await _cubit._midiCommand.devices;
      final MidiDevice? savedInputDevice = devices
          ?.where((device) => device.name == savedInputDeviceName)
          .firstOrNull;

      final MidiDevice? savedOutputDevice = devices
          ?.where((device) => device.name == savedOutputDeviceName)
          .firstOrNull;

      if (savedInputDevice != null && savedOutputDevice != null) {
        await connectToDevices(
          savedInputDevice,
          savedOutputDevice,
          savedSysExId,
        );
      } else {
        // Saved prefs exist, but devices not found now.
        final devices = await _fetchDeviceLists(); // Use helper
        _cubit._emitState(
          DistingState.selectDevice(
            inputDevices: devices['input'] ?? [],
            outputDevices: devices['output'] ?? [],
            canWorkOffline: canWorkOffline, // Pass the flag
          ),
        );
        // Start listening for MIDI device connection changes
        startMidiSetupListener();
      }
    } else {
      // No saved settings found, load devices and show selection
      final devices = await _fetchDeviceLists(); // Use helper
      _cubit._emitState(
        DistingState.selectDevice(
          inputDevices: devices['input'] ?? [],
          outputDevices: devices['output'] ?? [],
          canWorkOffline: canWorkOffline, // Pass the flag
        ),
      );
      // Start listening for MIDI device connection changes
      startMidiSetupListener();
    }
  }

  Future<void> loadDevices() async {
    try {
      // Transition to a loading state if needed
      _cubit._emitState(const DistingState.initial());

      // Fetch devices using the helper
      final devices = await _fetchDeviceLists(); // Call helper

      // Re-check offline capability here for manual refresh accuracy
      final bool canWorkOffline = await _cubit._metadataDao.hasCachedAlgorithms();

      // Transition to the select device state
      _cubit._emitState(
        DistingState.selectDevice(
          inputDevices: devices['input'] ?? [],
          outputDevices: devices['output'] ?? [],
          canWorkOffline: canWorkOffline, // Pass the flag here
        ),
      );

      // Start listening for MIDI device connection changes
      startMidiSetupListener();
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Emit default state on error
      _cubit._emitState(
        const DistingState.selectDevice(
          inputDevices: [],
          outputDevices: [],
          canWorkOffline: false,
        ),
      );

      // Still start listening even on error
      startMidiSetupListener();
    }
  }

  /// Starts listening for MIDI setup changes (device connections/disconnections).
  /// Automatically refreshes device list when changes are detected.
  void startMidiSetupListener() {
    // Cancel any existing subscription to avoid duplicates
    _cubit._midiSetupSubscription?.cancel();
    _cubit._midiSetupSubscription = null;

    // Subscribe to MIDI setup changes
    _cubit._midiSetupSubscription = _cubit._midiCommand.onMidiSetupChanged
        ?.listen((_) {
          // Only refresh if we're still in the device selection state
          if (_cubit.state is DistingStateInitial ||
              _cubit.state is DistingStateSelectDevice) {
            loadDevices();
          }
        });
  }

  /// Stops listening for MIDI setup changes.
  void stopMidiSetupListener() {
    _cubit._midiSetupSubscription?.cancel();
    _cubit._midiSetupSubscription = null;
  }

  void disconnect() {
    MidiDevice? inputDevice;
    MidiDevice? outputDevice;
    IDistingMidiManager? manager;

    switch (_cubit.state) {
      case DistingStateInitial():
      case DistingStateSelectDevice():
        break;
      case DistingStateConnected connectedState:
        inputDevice = connectedState.inputDevice;
        outputDevice = connectedState.outputDevice;
        manager = connectedState.disting;
        break;
      case DistingStateSynchronized syncstate:
        inputDevice = syncstate.inputDevice;
        outputDevice = syncstate.outputDevice;
        manager = syncstate.disting;
        break;
    }

    // Disconnect MIDI devices FIRST (closes ALSA ports and stops isolate)
    // Must happen before manager.dispose() to avoid read/write on closed ports
    if (inputDevice != null) {
      _cubit._midiCommand.disconnectDevice(inputDevice);
    }
    if (outputDevice != null && outputDevice.id != inputDevice?.id) {
      _cubit._midiCommand.disconnectDevice(outputDevice);
    }

    // Now dispose the manager (safe since devices are already disconnected)
    manager?.dispose();

    _cubit._midiCommand.dispose();
    _cubit._midiCommand = MidiCommand();
  }

  Future<void> performSyncAndEmit() async {
    final currentState = _cubit.state;
    MidiDevice? inputDevice; // Variables to hold devices from state
    MidiDevice? outputDevice;

    if (currentState is DistingStateConnected) {
      inputDevice = currentState.inputDevice;
      outputDevice = currentState.outputDevice;
    } else if (currentState is DistingStateSynchronized &&
        !currentState.offline) {
      inputDevice = currentState.inputDevice;
      outputDevice = currentState.outputDevice;
    } else {
      return;
    }

    // Now state is confirmed, get manager
    final IDistingMidiManager distingManager = _cubit.requireDisting();

    try {
      // --- Fetch ALL data from device REGARDLESS ---

      // Load algorithm library (try cache first for fast startup)
      List<AlgorithmInfo> algorithms = [];
      int numInPreset = 0;
      int numAlgorithms = 0;
      try {
        numAlgorithms = await distingManager.requestNumberOfAlgorithms() ?? 0;
        numInPreset = await distingManager.requestNumAlgorithmsInPreset() ?? 0;

        // Try to load cached algorithms synchronously for fast startup
        if (numAlgorithms > 0) {
          final cacheFreshnessDays = SettingsService().algorithmCacheDays;
          final cachedAlgorithms = await _cubit._metadataDao.getAlgorithmInfoCache(
            numAlgorithms,
            cacheFreshnessDays: cacheFreshnessDays,
          );
          if (cachedAlgorithms != null && cachedAlgorithms.length == numAlgorithms) {
            // Cache hit - use cached data immediately
            algorithms = cachedAlgorithms;
          }
        }
      } catch (e, stackTrace) {
        debugPrintStack(stackTrace: stackTrace);
      }

      final distingVersion = await distingManager.requestVersionString() ?? "";
      final firmwareVersion = FirmwareVersion(distingVersion);
      _cubit._lastKnownFirmwareVersion = firmwareVersion;
      // Set the parameter unit scheme based on firmware version
      ParameterEditorRegistry.setFirmwareVersion(firmwareVersion);
      final presetName = await distingManager.requestPresetName() ?? "Default";
      var unitStrings = await distingManager.requestUnitStrings() ?? [];
      List<Slot> slots = await _cubit.fetchSlots(numInPreset, distingManager);

      // --- Emit final synchronized state --- (Ensure offline is false)
      _cubit._emitState(
        DistingState.synchronized(
          disting: distingManager,
          distingVersion: distingVersion,
          firmwareVersion: firmwareVersion,
          presetName: presetName,
          algorithms: algorithms,
          slots: slots,
          unitStrings: unitStrings,
          inputDevice: inputDevice,
          outputDevice: outputDevice,
          loading: false,
          offline: false,
        ),
      );

      // If cache miss, start background loading for algorithms
      // (now that we're in synchronized state, background loading can update state)
      if (algorithms.isEmpty && numAlgorithms > 0) {
        _cubit._algorithmLibraryDelegate.loadAllAlgorithmsInBackground(
          distingManager,
          numAlgorithms,
        );
      }

      // Start background retry processing for any failed parameter requests
      if (_cubit._parameterFetchDelegate.hasQueuedRetries) {
        _cubit._parameterFetchDelegate
            .processParameterRetryQueue(distingManager)
            .catchError((e) {});
      }

      // Check for firmware updates in background (non-blocking, desktop only)
      // This runs asynchronously and updates state if update is available
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        _cubit.checkForFirmwareUpdate();
      }
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Do NOT store connection details if sync fails
      await loadDevices();
    }
  }

  Future<void> connectToDevices(
    MidiDevice inputDevice,
    MidiDevice outputDevice,
    int sysExId,
  ) async {
    // Get the potentially existing manager AND devices from the CURRENT state
    final currentState = _cubit.state;
    MidiDevice? existingInputDevice;
    MidiDevice? existingOutputDevice;
    if (currentState is DistingStateConnected) {
      existingInputDevice = currentState.inputDevice;
      existingOutputDevice = currentState.outputDevice;
    } else if (currentState is DistingStateSynchronized) {
      existingInputDevice = currentState.inputDevice;
      existingOutputDevice = currentState.outputDevice;
    }
    final existingManager = _cubit.disting(); // Get manager separately

    // Stop listening for MIDI setup changes while connecting
    stopMidiSetupListener();

    try {
      // Disconnect and dispose any existing managers first
      if (existingManager != null) {
        // Explicitly disconnect devices using devices read from the state
        if (existingInputDevice != null) {
          _cubit._midiCommand.disconnectDevice(existingInputDevice);
        }
        // Avoid disconnecting same device twice
        if (existingOutputDevice != null &&
            existingOutputDevice.id != existingInputDevice?.id) {
          _cubit._midiCommand.disconnectDevice(existingOutputDevice);
        }
        existingManager.dispose(); // Dispose the old manager
      }
      _cubit._offlineManager?.dispose(); // Explicitly dispose offline if it exists
      _cubit._offlineManager = null;

      // Connect to the selected device
      await _cubit._midiCommand.connectToDevice(inputDevice);
      if (inputDevice != outputDevice) {
        await _cubit._midiCommand.connectToDevice(outputDevice);
      }
      final prefs = await _cubit._prefs;
      await prefs.setString('selectedInputMidiDevice', inputDevice.name);
      await prefs.setString('selectedOutputMidiDevice', outputDevice.name);
      await prefs.setInt('selectedSysExId', sysExId);

      // Create the NEW online manager
      final newDistingManager = DistingMidiManager(
        midiCommand: _cubit._midiCommand,
        inputDevice: inputDevice,
        outputDevice: outputDevice,
        sysExId: sysExId,
      );

      // Emit Connected state WITH the new manager AND devices
      _cubit._emitState(
        DistingState.connected(
          disting: newDistingManager,
          inputDevice: inputDevice, // Store connected devices
          outputDevice: outputDevice,
          offline: false,
        ),
      );

      // Create parameter queue for the new manager
      _cubit._createParameterQueue();

      // Store these details as the last successful ONLINE connection
      // BEFORE starting the full sync.
      _cubit._lastOnlineInputDevice = inputDevice;
      _cubit._lastOnlineOutputDevice = outputDevice;
      _cubit._lastOnlineSysExId = sysExId; // Use the parameter passed to this method

      // Synchronize device clock with system time
      try {
        // Use local time for RTC since the device filesystem expects local timestamps
        final now = DateTime.now();
        final localUnixTime =
            now.millisecondsSinceEpoch ~/ 1000 - now.timeZoneOffset.inSeconds;
        await newDistingManager.requestSetRealTimeClock(localUnixTime);
      } catch (e) {
        // Continue with connection even if clock sync fails
      }

      await performSyncAndEmit(); // Sync with the new connection
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Clear last connection details if connection/sync fails
      _cubit._lastOnlineInputDevice = null;
      _cubit._lastOnlineOutputDevice = null;
      _cubit._lastOnlineSysExId = null;
      // Attempt to clean up MIDI connection on error too
      try {
        _cubit._midiCommand.disconnectDevice(inputDevice);
        if (inputDevice != outputDevice) {
          _cubit._midiCommand.disconnectDevice(outputDevice);
        }
      } catch (disconnectError) {
        // Intentionally empty
      }
      await loadDevices();
    }
  }

  Future<Map<String, List<MidiDevice>>> _fetchDeviceLists() async {
    final devices = await _cubit._midiCommand.devices;
    devices?.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return {
      'input': devices?.where((it) => it.inputPorts.isNotEmpty).toList() ?? [],
      'output': devices?.where((it) => it.outputPorts.isNotEmpty).toList() ?? [],
    };
  }
}
