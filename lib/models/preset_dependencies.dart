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

  int get totalCount =>
      wavetables.length +
      sampleFolders.length +
      multisampleFolders.length +
      fmBanks.length +
      granulatorSamples.length +
      midiFiles.length +
      threePotPrograms.length +
      luaScripts.length +
      communityPlugins.length +
      pluginData.length;

  bool get isEmpty => totalCount == 0;

  bool get hasCommunityPlugins => communityPlugins.isNotEmpty;
}
