import 'dart:convert'; // For JSON encoding/decoding
// For Uint8List in converter

import 'package:drift/drift.dart';
import 'package:nt_helper/models/packed_mapping_data.dart'; // Import needed for converter

// --- Core Algorithm and Parameter Metadata ---

@DataClassName('AlgorithmEntry')
class Algorithms extends Table {
  TextColumn get guid => text()(); // Primary key based on the 4-char GUID
  TextColumn get name => text()();
  IntColumn get numSpecifications => integer()();

  @override
  Set<Column> get primaryKey => {guid};
}

@DataClassName('SpecificationEntry')
class Specifications extends Table {
  TextColumn get algorithmGuid => text().references(Algorithms, #guid)();
  IntColumn get specIndex => integer()(); // To preserve order
  TextColumn get name => text()();
  IntColumn get minValue => integer()();
  IntColumn get maxValue => integer()();
  IntColumn get defaultValue => integer()();
  IntColumn get type => integer()();

  @override
  Set<Column> get primaryKey => {algorithmGuid, specIndex};
}

@DataClassName('UnitEntry')
class Units extends Table {
  IntColumn get id => integer().autoIncrement()(); // Simple auto ID
  TextColumn get unitString =>
      text().unique()(); // The actual string like "%", "Hz"
}

@DataClassName('ParameterEntry')
class Parameters extends Table {
  TextColumn get algorithmGuid => text().references(Algorithms, #guid)();
  IntColumn get parameterNumber => integer()();
  TextColumn get name => text()();
  IntColumn get minValue => integer().nullable()();
  IntColumn get maxValue => integer().nullable()();
  IntColumn get defaultValue => integer().nullable()();
  IntColumn get unitId =>
      integer().nullable().references(Units, #id)(); // FK to Units table
  IntColumn get powerOfTen => integer().nullable()();

  // --- NEW COLUMN ---
  // Stores the original unit index (0, 1, 2, etc.) from the device protocol
  IntColumn get rawUnitIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {algorithmGuid, parameterNumber};
}

@DataClassName('ParameterEnumEntry')
class ParameterEnums extends Table {
  TextColumn get algorithmGuid => text()(); // Part of composite FK
  IntColumn get parameterNumber => integer()(); // Part of composite FK
  IntColumn get enumIndex => integer()(); // Order matters
  TextColumn get enumString => text()();

  @override
  Set<Column> get primaryKey => {algorithmGuid, parameterNumber, enumIndex};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (algorithm_guid, parameter_number) REFERENCES parameters (algorithm_guid, parameter_number)'
      ];
}

@DataClassName('ParameterPageEntry')
class ParameterPages extends Table {
  TextColumn get algorithmGuid => text().references(Algorithms, #guid)();
  IntColumn get pageIndex => integer()(); // Preserve order
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {algorithmGuid, pageIndex};
}

// Junction table to link parameters to pages
@DataClassName('ParameterPageItemEntry')
class ParameterPageItems extends Table {
  TextColumn get algorithmGuid => text()(); // Part of composite PK & FKs
  IntColumn get pageIndex => integer()(); // Part of composite PK & FK
  IntColumn get parameterNumber => integer()(); // Part of composite PK & FK

  @override
  Set<Column> get primaryKey => {algorithmGuid, pageIndex, parameterNumber};

  @override
  List<String> get customConstraints => [
        'FOREIGN KEY (algorithm_guid, page_index) REFERENCES parameter_pages (algorithm_guid, page_index)',
        'FOREIGN KEY (algorithm_guid, parameter_number) REFERENCES parameters (algorithm_guid, parameter_number)'
      ];
}

// --- Preset Structure ---

@DataClassName('PresetEntry')
class Presets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get lastModified =>
      dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PresetSlotEntry')
class PresetSlots extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get presetId => integer().references(Presets, #id)();
  IntColumn get slotIndex => integer()(); // Order within the preset
  TextColumn get algorithmGuid => text().references(Algorithms, #guid)();
  TextColumn get customName => text().nullable()();

  @override
  List<String> get customConstraints => [
        'UNIQUE (preset_id, slot_index)'
      ]; // Ensure slot order is unique per preset
}

@DataClassName('PresetParameterValueEntry')
class PresetParameterValues extends Table {
  IntColumn get id =>
      integer().autoIncrement()(); // This is automatically the primary key
  IntColumn get presetSlotId =>
      integer().references(PresetSlots, #id, onDelete: KeyAction.cascade)();
  IntColumn get parameterNumber => integer()();
  IntColumn get value => integer()(); // The actual saved integer value

  // Add a unique constraint for the combination if needed logically
  @override
  List<String> get customConstraints =>
      ['UNIQUE (preset_slot_id, parameter_number)'];
}

/// Stores the string representation of a parameter's value for a specific slot
/// in a saved preset, if applicable (e.g., for enums, notes).
@DataClassName('PresetParameterStringValueEntry')
class PresetParameterStringValues extends Table {
  IntColumn get presetSlotId =>
      integer().references(PresetSlots, #id, onDelete: KeyAction.cascade)();
  IntColumn get parameterNumber => integer()();
  TextColumn get stringValue => text()(); // The string representation

  @override
  Set<Column> get primaryKey => {presetSlotId, parameterNumber};
}

// Need a type converter for PackedMappingData -> Blob
class PackedMappingDataConverter
    extends TypeConverter<PackedMappingData, Uint8List> {
  const PackedMappingDataConverter();

  @override
  PackedMappingData fromSql(Uint8List fromDb) {
    // TODO: Verify this is the correct way to reconstruct PackedMappingData
    // This assumes the first byte is the version and the rest is data.
    if (fromDb.isEmpty) return PackedMappingData.filler(); // Or throw error?
    final version = fromDb[0];
    final data = fromDb.sublist(1);
    return PackedMappingData.fromBytes(version, data);
  }

  @override
  Uint8List toSql(PackedMappingData value) {
    // TODO: Verify this is the correct way to serialize PackedMappingData
    // This assumes a toBytes() method exists and includes the version.
    // Prepending the version byte manually if toBytes() doesn't include it.
    final dataBytes = value.toBytes();
    return Uint8List.fromList([value.version, ...dataBytes]);
  }
}

@DataClassName('PresetMappingEntry')
class PresetMappings extends Table {
  IntColumn get presetSlotId => integer().references(PresetSlots, #id)();
  IntColumn get parameterNumber => integer()();
  // Store PackedMappingData as a BLOB using a type converter
  BlobColumn get packedData => blob().map(const PackedMappingDataConverter())();

  @override
  Set<Column> get primaryKey => {presetSlotId, parameterNumber};
}

// Type converter for List<int> -> JSON String
class IntListConverter extends TypeConverter<List<int>, String> {
  const IntListConverter();

  @override
  List<int> fromSql(String fromDb) {
    if (fromDb.isEmpty) return [];
    return (json.decode(fromDb) as List).cast<int>();
  }

  @override
  String toSql(List<int> value) {
    return json.encode(value);
  }
}

@DataClassName('PresetRoutingEntry')
class PresetRoutings extends Table {
  IntColumn get presetSlotId => integer().references(PresetSlots, #id)();
  // Store List<int> as a JSON encoded string
  TextColumn get routingInfoJson => text().map(const IntListConverter())();

  @override
  Set<Column> get primaryKey => {presetSlotId};
}

// --- SD Card Preset Indexing ---

@DataClassName('SdCardEntry')
class SdCards extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userLabel => text().unique()();
  TextColumn get systemIdentifier =>
      text().nullable().unique()(); // Optional system-level unique ID
}

@DataClassName('IndexedPresetFileEntry')
class IndexedPresetFiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sdCardId => integer().references(SdCards, #id)();
  TextColumn get relativePath =>
      text()(); // Relative to SD card's presets directory
  TextColumn get fileName => text()();
  TextColumn get absolutePathAtScanTime => text()();
  TextColumn get algorithmNameFromPreset => text().nullable()();
  TextColumn get notesFromPreset => text().nullable()();
  TextColumn get otherExtractedMetadataJson => text().nullable()();
  DateTimeColumn get lastSeenUtc => dateTime()();

  @override
  List<String> get customConstraints => ['UNIQUE (sd_card_id, relative_path)'];
}

// --- General Metadata Cache ---

@DataClassName('MetadataCacheEntry')
class MetadataCache extends Table {
  // A unique key to identify the cached data (e.g., 'unit_strings_ordered_list')
  TextColumn get cacheKey => text()();
  // The cached data, stored as a JSON string or other suitable format
  TextColumn get cacheValue => text()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}
