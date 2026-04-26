/// Represents all dependencies found in a preset
class PresetDependencies {
  final Set<String> wavetables = <String>{};
  final Set<String> sampleFolders = <String>{};
  final Set<String> sampleFiles = <String>{};
  final Set<String> multisampleFolders = <String>{};
  final Set<String> fmBanks = <String>{};
  final Set<String> granulatorSamples = <String>{};
  final Set<String> midiFiles = <String>{};
  final Set<String> threePotPrograms = <String>{};
  final Set<String> luaScripts = <String>{};
  final Set<String> communityPlugins = <String>{};
  final Set<String> pluginData = <String>{};

  /// Whole-tree bundling flags. Some algorithms (`midp` MIDI Player, `quan`
  /// Quantizer, etc.) reference files by integer index into a runtime
  /// directory listing rather than by name string. We can't resolve those
  /// indices without the live NT, so when a preset uses one of those
  /// algorithms we bundle the relevant directory tree wholesale and let the
  /// destination NT pick the same index. The trees are small (KB–low MB).
  bool bundleMidiTree = false;
  bool bundleSclTree = false;
  bool bundleKbmTree = false;

  /// Maps plugin GUID to SD card file path (from AlgorithmInfo.filename)
  /// Used for direct SD card reads during export when connected to hardware
  final Map<String, String> pluginPaths = <String, String>{};

  int get totalCount =>
      wavetables.length +
      sampleFolders.length +
      sampleFiles.length +
      multisampleFolders.length +
      fmBanks.length +
      granulatorSamples.length +
      midiFiles.length +
      threePotPrograms.length +
      luaScripts.length +
      communityPlugins.length +
      pluginData.length +
      (bundleMidiTree ? 1 : 0) +
      (bundleSclTree ? 1 : 0) +
      (bundleKbmTree ? 1 : 0);

  bool get isEmpty => totalCount == 0;

  bool get hasCommunityPlugins =>
      communityPlugins.isNotEmpty || pluginPaths.isNotEmpty;
}
