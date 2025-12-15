part of 'disting_cubit.dart';

class _MonitoringDelegate {
  _MonitoringDelegate(this._cubit) {
    _cpuUsageController = StreamController<CpuUsage>.broadcast(
      onListen: _startCpuUsagePolling,
      onCancel: _checkStopCpuUsagePolling,
    );
  }

  final DistingCubit _cubit;

  // CPU Usage Streaming
  late final StreamController<CpuUsage> _cpuUsageController;
  Timer? _cpuUsageTimer;
  static const Duration _cpuUsagePollingInterval = Duration(seconds: 10);

  // Video Streaming
  UsbVideoManager? _videoManager;
  StreamSubscription<VideoStreamState>? _videoStateSubscription;

  Stream<CpuUsage> get cpuUsageStream => _cpuUsageController.stream;
  VideoStreamState? get currentVideoState => _videoManager?.currentState;
  UsbVideoManager? get videoManager => _videoManager;

  void dispose() {
    _cpuUsageTimer?.cancel();
    _cpuUsageController.close();

    _videoStateSubscription?.cancel();
    _videoManager?.dispose();
  }

  /// Gets the current CPU usage information from the Disting device.
  /// Returns null if the device is not connected or if the request fails.
  /// Only works when connected to a physical device (not in offline or demo mode).
  Future<CpuUsage?> getCpuUsage() async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      return null;
    }

    if (currentState.offline || currentState.demo) {
      return null;
    }

    try {
      final disting = _cubit.requireDisting();
      await disting.requestWake();
      final cpuUsage = await disting.requestCpuUsage();
      return cpuUsage;
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  /// Starts the USB video stream from the Disting NT device
  Future<void> startVideoStream() async {
    final currentState = _cubit.state;
    if (currentState is! DistingStateSynchronized) {
      return;
    }

    // Initialize video manager if not already created
    _videoManager ??= UsbVideoManager();
    await _videoManager!.initialize();

    // Subscribe to video state changes and update cubit state
    _videoStateSubscription?.cancel();
    _videoStateSubscription = _videoManager!.stateStream.listen((videoState) {
      if (_cubit.state is DistingStateSynchronized) {
        final syncState = _cubit.state as DistingStateSynchronized;
        _cubit._emitState(syncState.copyWith(videoStream: videoState));
      }
    });

    // Try to auto-connect to Disting NT or any available USB camera
    await _videoManager!.autoConnect();
  }

  /// Stops the USB video stream
  Future<void> stopVideoStream() async {
    _videoStateSubscription?.cancel();
    _videoStateSubscription = null;
    await _videoManager?.disconnect();

    final currentState = _cubit.state;
    if (currentState is DistingStateSynchronized) {
      _cubit._emitState(currentState.copyWith(videoStream: null));
    }
  }

  // CPU Usage Streaming
  void _startCpuUsagePolling() {
    // Cancel any existing timer
    _cpuUsageTimer?.cancel();

    // Start polling immediately, then every 10 seconds
    _pollCpuUsageOnce();
    _cpuUsageTimer = Timer.periodic(_cpuUsagePollingInterval, (_) {
      _pollCpuUsageOnce();
    });
  }

  void _checkStopCpuUsagePolling() {
    // Use a small delay to check if there are still listeners
    // This prevents stopping polling when one listener cancels but others remain
    Timer(const Duration(milliseconds: 100), () {
      if (!_cpuUsageController.hasListener) {
        _cpuUsageTimer?.cancel();
        _cpuUsageTimer = null;
      }
    });
  }

  Future<void> _pollCpuUsageOnce() async {
    try {
      final cpuUsage = await getCpuUsage();
      if (cpuUsage != null && !_cpuUsageController.isClosed) {
        _cpuUsageController.add(cpuUsage);
      }
    } catch (e, stackTrace) {
      debugPrintStack(stackTrace: stackTrace);
      // Don't add error to stream, just log it
    }
  }

  /// Temporarily pause CPU usage polling (useful during sync operations)
  void pauseCpuMonitoring() {
    _cpuUsageTimer?.cancel();
    _cpuUsageTimer = null;
  }

  /// Resume CPU usage polling if there are listeners
  void resumeCpuMonitoring() {
    if (_cpuUsageController.hasListener && _cpuUsageTimer == null) {
      _startCpuUsagePolling();
    }
  }
}

