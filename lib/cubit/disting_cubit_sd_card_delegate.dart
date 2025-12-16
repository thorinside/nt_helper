part of 'disting_cubit.dart';

class _SdCardDelegate {
  _SdCardDelegate(this._cubit);

  final DistingCubit _cubit;

  Future<List<String>> scanSdCardPresets() async {
    final presets = <String>{};
    final disting = _cubit.requireDisting();
    await disting.requestWake();

    try {
      final rootListing = await disting.requestDirectoryListing('/');
      if (rootListing != null) {
        for (final entry in rootListing.entries) {
          if (entry.isDirectory &&
              entry.name.toLowerCase().contains('presets')) {
            final presetPaths = await _scanDirectory('/${entry.name}');
            presets.addAll(presetPaths);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
        label: "Error scanning SD card presets",
        stackTrace: stack,
      );
    }

    return presets.toList()..sort();
  }

  Future<Set<String>> _scanDirectory(String path) async {
    final presets = <String>{};
    final disting = _cubit.requireDisting();

    try {
      final listing = await disting.requestDirectoryListing(path);
      if (listing != null) {
        for (final entry in listing.entries) {
          final newPath = '$path/${entry.name}';
          if (entry.isDirectory) {
            presets.addAll(await _scanDirectory(newPath));
          } else if (entry.name.toLowerCase().endsWith('.json')) {
            presets.add(newPath);
          }
        }
      }
    } catch (e, stack) {
      debugPrintStack(
        label: "Error scanning directory $path",
        stackTrace: stack,
      );
    }

    return presets;
  }

  /// Scans the SD card on the connected disting for .json files.
  /// Returns a sorted list of relative paths (e.g., "presets/my_preset.json").
  /// Only available if firmware has SD card support.
  Future<List<String>> fetchSdCardPresets() async {
    final currentState = _cubit.state;

    if (currentState is! DistingStateSynchronized || currentState.offline) {
      return [];
    }

    if (!FirmwareVersion(currentState.distingVersion).hasSdCardSupport) {
      return [];
    }

    return scanSdCardPresets();
  }
}

