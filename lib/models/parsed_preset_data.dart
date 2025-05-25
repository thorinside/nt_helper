class ParsedPresetData {
  final String relativePath; // Relative to the SD card's preset directory root
  final String fileName;
  final String absolutePathAtScanTime;
  final String? algorithmName;
  final String? notes;
  final String? otherMetadataJson; // For any other structured data as JSON

  ParsedPresetData({
    required this.relativePath,
    required this.fileName,
    required this.absolutePathAtScanTime,
    this.algorithmName,
    this.notes,
    this.otherMetadataJson,
  });

  // Optional: Add factory constructors for fromJson, etc., if needed later
}
