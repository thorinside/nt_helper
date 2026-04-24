import 'package:nt_helper/models/collected_file.dart';

/// Result of [FileCollector.collectDependencies].
///
/// Contains the set of files that were successfully read from the SD card
/// alongside any human-readable warnings (missing files, oversized files,
/// read errors). Callers should surface the warnings to the user — an
/// otherwise-successful package may be incomplete.
class CollectionResult {
  final List<CollectedFile> files;
  final List<String> warnings;

  const CollectionResult({required this.files, required this.warnings});

  bool get hasWarnings => warnings.isNotEmpty;
}
