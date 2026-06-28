class AlgorithmGuidUtils {
  /// Factory GUIDs are lowercase alphanumeric, possibly space-padded to 4 chars
  /// (e.g. `spcn`, `env2`, `lfo `). Community plugins use uppercase GUIDs.
  static bool isFactoryGuid(String guid) =>
      RegExp(r'^[a-z0-9 ]+$').hasMatch(guid);
}
