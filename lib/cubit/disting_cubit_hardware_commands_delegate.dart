part of 'disting_cubit.dart';

class _HardwareCommandsDelegate {
  _HardwareCommandsDelegate(this._cubit);

  final DistingCubit _cubit;

  Future<Uint8List?> getHardwareScreenshot() async {
    final disting = _cubit.requireDisting();
    await disting.requestWake();
    return disting.encodeTakeScreenshot();
  }

  Future<void> updateScreenshot() async {
    final disting = _cubit.requireDisting();
    await disting.requestWake();
    final screenshot = await disting.encodeTakeScreenshot();
    switch (_cubit.state) {
      case DistingStateSynchronized syncstate:
        _cubit._emitState(syncstate.copyWith(screenshot: screenshot));
        break;
      default:
      // Handle other cases or errors
    }
  }

  void setDisplayMode(DisplayMode displayMode) {
    _cubit.requireDisting().let((disting) {
      disting.requestWake();
      disting.requestSetDisplayMode(displayMode);
    });
  }

  /// Reboots the Disting NT module.
  /// This will cause the module to restart as if power cycled.
  Future<void> reboot() async {
    final disting = _cubit.requireDisting();
    await disting.requestReboot();
  }

  /// Remounts the SD card file system.
  /// This refreshes the file system without a full reboot.
  Future<void> remountSd() async {
    final disting = _cubit.requireDisting();
    await disting.requestRemountSd();
  }
}

