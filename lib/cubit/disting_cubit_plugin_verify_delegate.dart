part of 'disting_cubit.dart';

/// Installs a plugin and then confirms the result against the device, for
/// callers such as the MCP `install_plugin` tool that cannot watch the UI.
///
/// The upload itself is delegated unchanged to [_PluginDelegate.installPlugin];
/// this delegate adds the live-session guard, the SD listing check, an awaited
/// wait for the rescan, and the optional load.
class _PluginVerifyDelegate {
  _PluginVerifyDelegate(this._cubit);

  final DistingCubit _cubit;

  /// Uploads [fileData] as [fileName] (a `.o` or `.lua` file name) and reports
  /// what the device shows afterwards.
  ///
  /// Throws [PluginInstallRefused] without touching the device unless the app
  /// is synchronized with live hardware whose firmware supports SD writes.
  /// Upload failures from [_PluginDelegate.installPlugin] propagate unchanged.
  ///
  /// For `.o` files the algorithm list is re-read up to [maxRescanAttempts]
  /// times, [rescanPollInterval] apart, until every GUID found in the local
  /// file appears (or, when no GUID is readable, until any algorithm with the
  /// installed filename appears). When [load] is true each matching algorithm
  /// is then loaded with [_PluginDelegate.loadPlugin]. Lua scripts are not
  /// algorithms, so for them only the SD listing is checked.
  Future<PluginInstallReport> installPluginAndVerify(
    String fileName,
    Uint8List fileData, {
    bool load = false,
    int maxRescanAttempts = 5,
    Duration rescanPollInterval = const Duration(seconds: 1),
  }) async {
    final state = _requireLiveSession();
    final targetPath = PluginInstallationPath.target(fileName);
    final isObject = targetPath.toLowerCase().endsWith('.o');
    final presetReloaded =
        isObject &&
        _cubit._pluginDelegate._isPluginInUseByPreset(targetPath, state);

    final cleanup = await _cubit._pluginDelegate.installPlugin(
      fileName,
      fileData,
    );
    final filePresent = await _isListed(targetPath, fileData.length);

    final expectedGuids = isObject
        ? await _readGuids(fileData, fileName)
        : const <String>[];
    var matches = <AlgorithmInfo>[];
    var attempts = 0;
    while (isObject && attempts < maxRescanAttempts) {
      if (attempts > 0) await Future.delayed(rescanPollInterval);
      attempts++;
      final algorithms = await _cubit._algorithmLibraryDelegate
          .refreshAlgorithmsNow();
      matches = algorithms
          .where(
            (a) => expectedGuids.contains(a.guid) || a.filename == targetPath,
          )
          .toList();
      final found = matches.map((a) => a.guid).toSet();
      final complete = expectedGuids.isEmpty
          ? matches.isNotEmpty
          : expectedGuids.every(found.contains);
      if (complete) break;
    }

    final loadResults = <PluginLoadResult>[];
    if (load) {
      for (final algorithm in matches) {
        final loaded = await _cubit._pluginDelegate.loadPlugin(algorithm.guid);
        loadResults.add(
          PluginLoadResult(
            guid: algorithm.guid,
            loaded: loaded?.isLoaded ?? false,
          ),
        );
      }
    }

    return PluginInstallReport(
      destinationPath: targetPath,
      bytesWritten: fileData.length,
      presetReloaded: presetReloaded,
      cleanup: cleanup,
      filePresent: filePresent,
      expectedGuids: expectedGuids,
      algorithms: [
        for (final a in matches)
          InstalledPluginAlgorithm(
            guid: a.guid,
            name: a.name,
            isLoaded: a.isLoaded,
          ),
      ],
      rescanAttempts: attempts,
      loadResults: loadResults,
    );
  }

  /// Returns the synchronized live state or throws [PluginInstallRefused].
  DistingStateSynchronized _requireLiveSession() {
    final state = _cubit.state;
    if (state is! DistingStateSynchronized) {
      throw const PluginInstallRefused(
        PluginInstallRefusal.notConnected,
        'No Disting NT is connected and synchronized.',
      );
    }
    if (state.demo) {
      throw const PluginInstallRefused(
        PluginInstallRefusal.demo,
        'Demo mode has no device to install to. Connect a Disting NT.',
      );
    }
    if (state.offline) {
      throw const PluginInstallRefused(
        PluginInstallRefusal.offline,
        'Offline mode has no device to install to. Connect a Disting NT.',
      );
    }
    if (!FirmwareVersion(state.distingVersion).hasSdCardSupport) {
      throw const PluginInstallRefused(
        PluginInstallRefusal.noSdCardSupport,
        'The connected firmware does not support SD card writes.',
      );
    }
    return state;
  }

  /// Whether [targetPath]'s directory lists the file with [size] bytes, or
  /// null when the listing cannot be read.
  Future<bool?> _isListed(String targetPath, int size) async {
    final slash = targetPath.lastIndexOf('/');
    final name = targetPath.substring(slash + 1);
    try {
      final listing = await _cubit.requireDisting().requestDirectoryListing(
        targetPath.substring(0, slash),
      );
      if (listing == null) return null;
      return listing.entries.any(
        (e) => !e.isDirectory && e.name == name && e.size == size,
      );
    } catch (_) {
      return null;
    }
  }

  /// GUIDs declared by an ELF object, or empty when none can be read.
  Future<List<String>> _readGuids(Uint8List bytes, String fileName) async {
    try {
      final guids = await ElfGuidExtractor.extractAllGuidsFromBytes(
        bytes,
        fileName,
      );
      return guids.map((g) => g.guid).toSet().toList();
    } catch (_) {
      return const [];
    }
  }
}
