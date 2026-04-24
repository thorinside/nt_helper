/// Configuration options for package creation
class PackageConfig {
  final bool includeWavetables;
  final bool includeSamples;
  final bool includeFMBanks;
  final bool includeThreePot;
  final bool includeLua;
  final bool includeReadme;
  final bool includeCommunityPlugins;

  const PackageConfig({
    this.includeWavetables = true,
    this.includeSamples = true,
    this.includeFMBanks = true,
    this.includeThreePot = true,
    this.includeLua = true,
    this.includeReadme = true,
    // Community plugins are included by default so a packaged preset
    // can be restored onto a blank SD card without separately tracking
    // down each plugin binary. Users can opt out per-package.
    this.includeCommunityPlugins = true,
  });

  PackageConfig copyWith({
    bool? includeWavetables,
    bool? includeSamples,
    bool? includeFMBanks,
    bool? includeThreePot,
    bool? includeLua,
    bool? includeReadme,
    bool? includeCommunityPlugins,
  }) {
    return PackageConfig(
      includeWavetables: includeWavetables ?? this.includeWavetables,
      includeSamples: includeSamples ?? this.includeSamples,
      includeFMBanks: includeFMBanks ?? this.includeFMBanks,
      includeThreePot: includeThreePot ?? this.includeThreePot,
      includeLua: includeLua ?? this.includeLua,
      includeReadme: includeReadme ?? this.includeReadme,
      includeCommunityPlugins:
          includeCommunityPlugins ?? this.includeCommunityPlugins,
    );
  }
}
