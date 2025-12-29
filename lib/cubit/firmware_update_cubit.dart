import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bloc/bloc.dart';
import 'package:nt_helper/cubit/firmware_update_state.dart';
import 'package:nt_helper/models/firmware_release.dart';
import 'package:nt_helper/models/flash_progress.dart';
import 'package:nt_helper/models/flash_stage.dart';
import 'package:nt_helper/services/firmware_version_service.dart';
import 'package:nt_helper/services/flash_tool_bridge.dart';
import 'package:nt_helper/services/flash_tool_manager.dart';

/// Path to the udev rules on Linux
const String kUdevRulesPath = '/etc/udev/rules.d/99-disting-nt.rules';

/// Content of the udev rules file
const String kUdevRulesContent = '''
# /etc/udev/rules.d/99-disting-nt.rules
# Allow unprivileged access to Disting NT in SDP (bootloader) mode
SUBSYSTEM=="usb", ATTRS{idVendor}=="1fc9", ATTRS{idProduct}=="0135", MODE="0666"
''';

/// Cubit for managing the firmware update workflow
class FirmwareUpdateCubit extends Cubit<FirmwareUpdateState> {
  final FirmwareVersionService _firmwareVersionService;
  final FlashToolManager _flashToolManager;
  final FlashToolBridge _flashToolBridge;
  final bool _isDemo;
  final bool _isOffline;
  final String _initialCurrentVersion;

  StreamSubscription<FlashProgress>? _flashSubscription;
  String? _currentFirmwarePath;
  String? _currentTargetVersion;

  FirmwareUpdateCubit({
    required FirmwareVersionService firmwareVersionService,
    required FlashToolManager flashToolManager,
    required FlashToolBridge flashToolBridge,
    required String currentVersion,
    required bool isDemo,
    required bool isOffline,
  })  : _firmwareVersionService = firmwareVersionService,
        _flashToolManager = flashToolManager,
        _flashToolBridge = flashToolBridge,
        _isDemo = isDemo,
        _isOffline = isOffline,
        _initialCurrentVersion = currentVersion,
        super(FirmwareUpdateState.initial(currentVersion: currentVersion));

  /// Whether firmware update is available (desktop only, not demo/offline)
  bool get isUpdateAvailable {
    if (_isDemo || _isOffline) return false;
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return false;
    }
    return true;
  }

  /// Load available firmware versions from the server
  Future<void> loadAvailableVersions() async {
    if (!isUpdateAvailable) return;

    final currentState = state;
    if (currentState is! FirmwareUpdateStateInitial) return;

    emit(currentState.copyWith(isLoadingVersions: true, fetchError: null));

    try {
      final versions = await _firmwareVersionService.fetchAvailableVersions();
      emit(
        currentState.copyWith(
          availableVersions: versions,
          isLoadingVersions: false,
        ),
      );
    } catch (e) {
      emit(
        currentState.copyWith(
          isLoadingVersions: false,
          fetchError: e.toString(),
        ),
      );
    }
  }

  /// Start the firmware update process for a specific version
  Future<void> startUpdate(FirmwareRelease version) async {
    if (!isUpdateAvailable) {
      emit(
        FirmwareUpdateState.error(
          message: _isDemo
              ? 'Firmware updates not available in demo mode'
              : _isOffline
                  ? 'Firmware updates not available in offline mode'
                  : 'Firmware updates only available on desktop platforms',
        ),
      );
      return;
    }

    emit(FirmwareUpdateState.downloading(version: version, progress: 0));

    try {
      final firmwarePath = await _firmwareVersionService.downloadFirmware(
        version,
        onProgress: (progress) {
          if (state is FirmwareUpdateStateDownloading) {
            emit(
              FirmwareUpdateState.downloading(
                version: version,
                progress: progress,
              ),
            );
          }
        },
      );

      _currentFirmwarePath = firmwarePath;
      _currentTargetVersion = version.version;
      emit(
        FirmwareUpdateState.waitingForBootloader(
          firmwarePath: firmwarePath,
          targetVersion: version.version,
        ),
      );
    } on FirmwareDownloadException catch (e) {
      emit(FirmwareUpdateState.error(
        message: e.message,
        errorType: FirmwareErrorType.download,
      ));
    } catch (e) {
      emit(FirmwareUpdateState.error(
        message: 'Download failed: $e',
        errorType: FirmwareErrorType.download,
      ));
    }
  }

  /// Use a local firmware file instead of downloading
  Future<void> useLocalFile(String path) async {
    if (!isUpdateAvailable) {
      emit(
        FirmwareUpdateState.error(
          message: 'Firmware updates not available',
        ),
      );
      return;
    }

    // Validate the file exists and is a valid ZIP
    try {
      final file = File(path);
      if (!await file.exists()) {
        emit(
          const FirmwareUpdateState.error(
            message: 'Selected file does not exist',
          ),
        );
        return;
      }

      // Validate it's a valid ZIP with firmware binary
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      if (archive.isEmpty) {
        emit(
          const FirmwareUpdateState.error(
            message: 'Selected ZIP archive is empty',
          ),
        );
        return;
      }

      final hasFirmware = archive.any(
        (f) =>
            f.name.toLowerCase().contains('disting') &&
            f.name.toLowerCase().endsWith('.bin'),
      );
      if (!hasFirmware) {
        emit(
          const FirmwareUpdateState.error(
            message: 'ZIP does not contain expected firmware file (disting_NT.bin)',
          ),
        );
        return;
      }

      _currentFirmwarePath = path;
      _currentTargetVersion = 'local';
      emit(
        FirmwareUpdateState.waitingForBootloader(
          firmwarePath: path,
          targetVersion: 'local',
        ),
      );
    } catch (e) {
      emit(
        FirmwareUpdateState.error(
          message: 'Invalid firmware file: $e',
          errorType: FirmwareErrorType.download,
        ),
      );
    }
  }

  /// Check if udev rules are installed (Linux only)
  Future<bool> _checkUdevRules() async {
    if (!Platform.isLinux) return true;
    return File(kUdevRulesPath).exists();
  }

  /// Start the flash process after user confirms bootloader mode
  Future<void> startFlashing() async {
    final currentState = state;
    if (currentState is! FirmwareUpdateStateWaitingForBootloader) return;

    // On Linux, check if udev rules are installed
    if (Platform.isLinux && !await _checkUdevRules()) {
      emit(
        FirmwareUpdateState.udevMissing(
          firmwarePath: currentState.firmwarePath,
          targetVersion: currentState.targetVersion,
          rulesContent: kUdevRulesContent,
        ),
      );
      return;
    }

    // First ensure the flash tool is available
    try {
      await _flashToolManager.getToolPath();
    } catch (e) {
      emit(
        FirmwareUpdateState.error(
          message: 'Failed to prepare flash tool: $e',
          errorType: FirmwareErrorType.general,
          firmwarePath: currentState.firmwarePath,
          targetVersion: currentState.targetVersion,
        ),
      );
      return;
    }

    FlashStage? currentStage;

    emit(
      FirmwareUpdateState.flashing(
        targetVersion: currentState.targetVersion,
        progress: const FlashProgress(
          stage: FlashStage.sdpConnect,
          percent: 0,
          message: 'Connecting to bootloader...',
        ),
      ),
    );

    try {
      final stream = _flashToolBridge.flash(currentState.firmwarePath);

      _flashSubscription = stream.listen(
        (progress) {
          currentStage = progress.stage;
          if (progress.isError) {
            emit(
              FirmwareUpdateState.error(
                message: progress.message,
                errorType: _getErrorTypeForStage(currentStage),
                failedStage: currentStage,
                firmwarePath: currentState.firmwarePath,
                targetVersion: currentState.targetVersion,
              ),
            );
          } else if (progress.stage == FlashStage.complete &&
              progress.percent == 100) {
            emit(
              FirmwareUpdateState.success(
                newVersion: currentState.targetVersion,
              ),
            );
          } else {
            emit(
              FirmwareUpdateState.flashing(
                targetVersion: currentState.targetVersion,
                progress: progress,
              ),
            );
          }
        },
        onError: (error) {
          emit(
            FirmwareUpdateState.error(
              message: 'Flash error: $error',
              errorType: _getErrorTypeForStage(currentStage),
              failedStage: currentStage,
              firmwarePath: currentState.firmwarePath,
              targetVersion: currentState.targetVersion,
            ),
          );
        },
        onDone: () {
          // Stream completed - check if we're still in flashing state
          // If so, something went wrong
          if (state is FirmwareUpdateStateFlashing) {
            emit(
              FirmwareUpdateState.error(
                message: 'Flash process ended unexpectedly',
                errorType: _getErrorTypeForStage(currentStage),
                failedStage: currentStage,
                firmwarePath: currentState.firmwarePath,
                targetVersion: currentState.targetVersion,
              ),
            );
          }
        },
      );
    } catch (e) {
      emit(
        FirmwareUpdateState.error(
          message: 'Failed to start flash: $e',
          errorType: FirmwareErrorType.general,
          firmwarePath: currentState.firmwarePath,
          targetVersion: currentState.targetVersion,
        ),
      );
    }
  }

  /// Get the error type based on which stage failed
  FirmwareErrorType _getErrorTypeForStage(FlashStage? stage) {
    if (stage == null) return FirmwareErrorType.general;
    switch (stage) {
      case FlashStage.sdpConnect:
      case FlashStage.blCheck:
        return FirmwareErrorType.bootloaderConnection;
      case FlashStage.sdpUpload:
      case FlashStage.write:
        return FirmwareErrorType.flashWrite;
      case FlashStage.configure:
      case FlashStage.reset:
      case FlashStage.complete:
        return FirmwareErrorType.general;
    }
  }

  /// Cancel the current operation
  Future<void> cancel() async {
    await _flashSubscription?.cancel();
    _flashSubscription = null;

    await _flashToolBridge.cancel();
    await _cleanupTempFiles();

    final currentState = state;
    if (currentState is FirmwareUpdateStateInitial) {
      // Already in initial state, nothing to do
    } else {
      // Get the current version from any state that has it
      emit(FirmwareUpdateState.initial(currentVersion: _getCurrentVersion()));
      // Reload available versions
      await loadAvailableVersions();
    }
  }

  /// Clean up temporary files (called on success, cancel, or error dismiss)
  Future<void> cleanupAndReset() async {
    await _cleanupTempFiles();
    emit(FirmwareUpdateState.initial(currentVersion: _getCurrentVersion()));
    // Reload available versions
    await loadAvailableVersions();
  }

  /// Return to bootloader instructions (from error state)
  /// Used when user needs to re-enter bootloader mode
  void returnToBootloaderInstructions() {
    final currentState = state;
    String? firmwarePath;
    String? targetVersion;

    if (currentState is FirmwareUpdateStateError) {
      firmwarePath = currentState.firmwarePath;
      targetVersion = currentState.targetVersion;
    }

    // Fall back to stored values if not in error state
    firmwarePath ??= _currentFirmwarePath;
    targetVersion ??= _currentTargetVersion;

    if (firmwarePath != null && targetVersion != null) {
      emit(
        FirmwareUpdateState.waitingForBootloader(
          firmwarePath: firmwarePath,
          targetVersion: targetVersion,
        ),
      );
    } else {
      // Can't return to bootloader without firmware path, reset instead
      emit(FirmwareUpdateState.initial(currentVersion: _getCurrentVersion()));
    }
  }

  /// Retry the flash process (from error state)
  /// Used when the flash failed during upload/write
  Future<void> retryFlash() async {
    final currentState = state;
    String? firmwarePath;
    String? targetVersion;

    if (currentState is FirmwareUpdateStateError) {
      firmwarePath = currentState.firmwarePath;
      targetVersion = currentState.targetVersion;
    }

    // Fall back to stored values
    firmwarePath ??= _currentFirmwarePath;
    targetVersion ??= _currentTargetVersion;

    if (firmwarePath != null && targetVersion != null) {
      // Go to bootloader waiting state first
      emit(
        FirmwareUpdateState.waitingForBootloader(
          firmwarePath: firmwarePath,
          targetVersion: targetVersion,
        ),
      );
      // Then immediately start flashing
      await startFlashing();
    } else {
      // Can't retry without firmware path, reset instead
      emit(FirmwareUpdateState.initial(currentVersion: _getCurrentVersion()));
    }
  }

  /// After udev rules are installed, continue with flashing
  void continueAfterUdevInstall() {
    final currentState = state;
    if (currentState is FirmwareUpdateStateUdevMissing) {
      emit(
        FirmwareUpdateState.waitingForBootloader(
          firmwarePath: currentState.firmwarePath,
          targetVersion: currentState.targetVersion,
        ),
      );
    }
  }

  /// Get diagnostic information for error reporting
  Future<String> getDiagnostics() async {
    final currentState = state;
    final buffer = StringBuffer();

    // Platform info
    buffer.writeln('Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

    // Version info
    buffer.writeln('Current Firmware: $_initialCurrentVersion');
    if (currentState is FirmwareUpdateStateError && currentState.targetVersion != null) {
      buffer.writeln('Target Firmware: ${currentState.targetVersion}');
    } else if (_currentTargetVersion != null) {
      buffer.writeln('Target Firmware: $_currentTargetVersion');
    }

    // Error info
    if (currentState is FirmwareUpdateStateError) {
      if (currentState.failedStage != null) {
        buffer.writeln('Error Stage: ${currentState.failedStage!.machineValue}');
      }
      buffer.writeln('Error Message: ${currentState.message}');
    }

    // Recent log lines
    buffer.writeln('\nRecent Log:');
    final recentLogs = await _flashToolBridge.getRecentLogLines(20);
    for (final line in recentLogs) {
      buffer.writeln(line);
    }

    return buffer.toString();
  }

  /// Clean up downloaded firmware files
  Future<void> _cleanupTempFiles() async {
    if (_currentFirmwarePath != null) {
      // Only delete if it's in the temp directory (not a user-selected local file)
      final file = File(_currentFirmwarePath!);
      if (await file.exists() &&
          _currentFirmwarePath!.contains('distingNT_')) {
        try {
          await file.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      _currentFirmwarePath = null;
      _currentTargetVersion = null;
    }
  }

  /// Get the stored current version (persists across state changes)
  String _getCurrentVersion() => _initialCurrentVersion;

  @override
  Future<void> close() async {
    await _flashSubscription?.cancel();
    await _cleanupTempFiles();
    return super.close();
  }
}
