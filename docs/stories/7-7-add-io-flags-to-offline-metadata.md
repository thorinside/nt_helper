# Story 7.7: Add I/O Flags to Offline Metadata

Status: pending

## Story

As a developer maintaining the nt_helper offline metadata infrastructure,
I want I/O flags stored in the offline database schema and included in JSON metadata export/import,
So that offline mode can provide I/O flag data without requiring live hardware connection.

## Context

Story 7.3 adds I/O flags to the runtime `ParameterInfo` model, enabling online mode to use hardware-provided metadata. However, offline mode currently has no access to this data because:

1. The `Parameters` database table lacks an `ioFlags` column
2. JSON metadata export/import doesn't include `ioFlags` field
3. The bundled `assets/metadata/full_metadata.json` was generated before I/O flags existed

This story adds offline metadata infrastructure for I/O flags, enabling offline and mock modes to provide the same metadata as online mode (once the bundled metadata is regenerated in Story 7.8).

**Note:** This story provides the infrastructure but does NOT regenerate the bundled metadata JSON - that's Story 7.8's responsibility.

## Acceptance Criteria

### AC-1: Database Schema Updates

1. Add `ioFlags` integer column to `Parameters` table in `lib/db/tables.dart`
2. Column is nullable with no default value (allows distinguishing "no data" from "all flags off")
3. Column appears after `powerOfTen` field (maintain logical grouping)
4. Update table documentation to describe `ioFlags` column purpose

### AC-2: Database Migration

5. Create database migration to add `ioFlags` column to existing databases
6. Migration handles databases with existing parameter data (preserves all existing data)
7. Existing parameters have `ioFlags = null` after migration (no data available)
8. Migration tested with databases at various schema versions
9. Migration rollback strategy documented (if needed)

### AC-3: JSON Export Implementation

10. Update metadata export to include `ioFlags` field in parameters
11. Export format: `"ioFlags": <int|null>` for each parameter entry
12. When `ioFlags` is null, export as `"ioFlags": null` (explicit null, not omitted)
13. Export preserves all existing fields (backwards compatible)
14. Update export version number to indicate schema change (version 2)

### AC-4: JSON Import Implementation

15. Update `MetadataImportService._importParameters()` to read `ioFlags` field
16. Handle missing `ioFlags` in old JSON files (treat as `null`, not error)
17. Handle `"ioFlags": null` explicitly (store as null in database)
18. Handle `"ioFlags": 0` through `"ioFlags": 15` (valid flag values)
19. Import validates flag values are in valid range (0-15 or null)

### AC-5: Metadata DAO Updates

20. Update `MetadataDao.getFullAlgorithmDetails()` to select `ioFlags` column
21. Update parameter queries to include `ioFlags` in SELECT statements
22. Update `ParameterEntry` wrapper class to expose `ioFlags` (if needed)
23. Verify queries work with both null and non-null `ioFlags` values

### AC-6: Offline Mode Integration

24. `OfflineDistingMidiManager` retrieves `ioFlags` from database when available
25. When `ioFlags` is null in database, return 0 (default: no flags set)
26. `ParameterInfo` constructed from database includes `ioFlags` value
27. Offline mode behavior matches online mode when metadata is available

### AC-7: Mock Mode Behavior

28. `MockDistingMidiManager` continues to return `ioFlags = 0` for all parameters
29. Mock mode doesn't require database (hardcoded mock data)
30. Document that mock mode has no I/O flag data

### AC-8: Backwards Compatibility

31. Old databases without `ioFlags` column work after migration
32. Old JSON files without `ioFlags` field import successfully (treat as null)
33. Export format remains compatible with import from older versions
34. New JSON files can be imported into older app versions (column ignored gracefully)

### AC-9: Unit Testing

35. Unit test verifies database migration adds `ioFlags` column
36. Unit test verifies JSON export includes `ioFlags` field
37. Unit test verifies JSON import reads `ioFlags` field correctly
38. Unit test verifies import handles missing `ioFlags` (old format)
39. Unit test verifies import handles `"ioFlags": null`
40. Unit test verifies import validates flag range (0-15 or null)
41. Unit test verifies offline mode retrieves `ioFlags` from database

### AC-10: Integration Testing

42. Integration test imports old JSON without `ioFlags` (no errors)
43. Integration test imports new JSON with `ioFlags` (data stored correctly)
44. Integration test verifies migration from old to new schema
45. Integration test exports and re-imports metadata (roundtrip)

### AC-11: Documentation

46. Update database schema documentation with `ioFlags` column
47. Document JSON export format version 2 changes
48. Document that bundled metadata still lacks I/O flags (Story 7.8)
49. Add inline code comments explaining null vs 0 distinction
50. Update migration documentation with schema version history

### AC-12: Code Quality

51. `flutter analyze` passes with zero warnings
52. All existing tests pass with no regressions
53. Database migrations execute successfully
54. JSON import/export roundtrip preserves all data

## Tasks / Subtasks

- [ ] Task 1: Update database schema (AC-1)
  - [ ] Add `ioFlags` column to `Parameters` table
  - [ ] Set column as nullable integer
  - [ ] Position after `powerOfTen` field
  - [ ] Update table documentation
  - [ ] Regenerate Drift code (`flutter packages pub run build_runner build`)

- [ ] Task 2: Create database migration (AC-2)
  - [ ] Write migration to add `ioFlags` column
  - [ ] Test migration on empty database
  - [ ] Test migration on database with existing data
  - [ ] Verify data preservation after migration
  - [ ] Document migration strategy

- [ ] Task 3: Update JSON export (AC-3)
  - [ ] Locate export logic in metadata export service
  - [ ] Add `ioFlags` to parameter export
  - [ ] Handle null values explicitly
  - [ ] Increment export version to 2
  - [ ] Test export produces valid JSON

- [ ] Task 4: Update JSON import (AC-4)
  - [ ] Update `_importParameters()` in `MetadataImportService`
  - [ ] Read `ioFlags` field from JSON
  - [ ] Handle missing field (old format)
  - [ ] Handle explicit null
  - [ ] Validate flag range (0-15 or null)
  - [ ] Test with various JSON formats

- [ ] Task 5: Update metadata DAO (AC-5)
  - [ ] Add `ioFlags` to parameter queries
  - [ ] Update `getFullAlgorithmDetails()` query
  - [ ] Update parameter wrapper/model classes
  - [ ] Test queries return correct data

- [ ] Task 6: Update offline mode (AC-6)
  - [ ] Modify `OfflineDistingMidiManager` to read `ioFlags` from DB
  - [ ] Default null to 0 (no flags)
  - [ ] Pass `ioFlags` to `ParameterInfo` constructor
  - [ ] Verify offline mode provides flag data

- [ ] Task 7: Verify mock mode (AC-7)
  - [ ] Confirm mock mode returns `ioFlags = 0`
  - [ ] No database dependency in mock mode
  - [ ] Document mock mode behavior

- [ ] Task 8: Test backwards compatibility (AC-8)
  - [ ] Test migration from old schema
  - [ ] Test import of old JSON format
  - [ ] Test export/import roundtrip
  - [ ] Verify graceful degradation

- [ ] Task 9: Write unit tests (AC-9)
  - [ ] Test database migration
  - [ ] Test JSON export with ioFlags
  - [ ] Test JSON import with ioFlags
  - [ ] Test import without ioFlags (old format)
  - [ ] Test import with null ioFlags
  - [ ] Test flag range validation
  - [ ] Test offline mode retrieval

- [ ] Task 10: Write integration tests (AC-10)
  - [ ] Test import old JSON format
  - [ ] Test import new JSON format
  - [ ] Test schema migration
  - [ ] Test export/import roundtrip

- [ ] Task 11: Update documentation (AC-11)
  - [ ] Update database schema docs
  - [ ] Document export format v2
  - [ ] Note bundled metadata lacks flags
  - [ ] Add inline code comments
  - [ ] Update migration history

- [ ] Task 12: Code quality validation (AC-12)
  - [ ] Run `flutter analyze`
  - [ ] Run all tests
  - [ ] Test migrations
  - [ ] Verify import/export

## Dev Notes

### Architecture Context

**Current Database Schema (Parameters table):**
```dart
@DataClassName('ParameterEntry')
class Parameters extends Table {
  TextColumn get algorithmGuid => text().references(Algorithms, #guid)();
  IntColumn get parameterNumber => integer()();
  TextColumn get name => text()();
  IntColumn get minValue => integer().nullable()();
  IntColumn get maxValue => integer().nullable()();
  IntColumn get defaultValue => integer().nullable()();
  IntColumn get unitId => integer().nullable().references(Units, #id)();
  IntColumn get powerOfTen => integer().nullable()();
  IntColumn get rawUnitIndex => integer().nullable()();

  @override
  Set<Column> get primaryKey => {algorithmGuid, parameterNumber};
}
```

**New Schema (add this column):**
```dart
  IntColumn get ioFlags => integer().nullable()();  // Add after rawUnitIndex
```

### Database Migration Strategy

**Migration approach:**
1. Drift handles schema changes automatically via migrations
2. Bump schema version in database.dart
3. Add migration logic in `MigrationStrategy`
4. Migration adds column with ALTER TABLE
5. Existing rows get `ioFlags = null`

**Migration code example:**
```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
  },
  onUpgrade: (Migrator m, int from, int to) async {
    if (from < 2) {
      // Add ioFlags column in schema version 2
      await m.addColumn(parameters, parameters.ioFlags);
    }
  },
);
```

### JSON Export Format

**Export format (version 2):**
```json
{
  "exportDate": "2025-11-18T...",
  "exportVersion": 2,
  "exportType": "full_metadata",
  "tables": {
    "parameters": [
      {
        "algorithmGuid": "clck",
        "parameterNumber": 0,
        "name": "Clock",
        "minValue": 0,
        "maxValue": 1,
        "defaultValue": 0,
        "unitId": 521,
        "powerOfTen": 0,
        "rawUnitIndex": 1,
        "ioFlags": 5
      }
    ]
  }
}
```

**Null vs 0 distinction:**
- `"ioFlags": null` - No data available (old hardware, not queried)
- `"ioFlags": 0` - Flags explicitly set to 0 (no input, output, audio, or mode flags)

### JSON Import Updates

**Current import code:**
```dart
for (final paramData in paramsList) {
  entries.add(
    ParametersCompanion(
      algorithmGuid: Value(paramData['algorithmGuid'] as String),
      parameterNumber: Value(paramData['parameterNumber'] as int),
      name: Value(paramData['name'] as String),
      minValue: Value(paramData['minValue'] as int?),
      maxValue: Value(paramData['maxValue'] as int?),
      defaultValue: Value(paramData['defaultValue'] as int?),
      unitId: Value(paramData['unitId'] as int?),
      powerOfTen: Value(paramData['powerOfTen'] as int?),
      rawUnitIndex: Value(paramData['rawUnitIndex'] as int?),
    ),
  );
}
```

**Updated import code:**
```dart
for (final paramData in paramsList) {
  // Validate ioFlags if present
  int? ioFlags = paramData['ioFlags'] as int?;
  if (ioFlags != null && (ioFlags < 0 || ioFlags > 15)) {
    // Invalid flag value, treat as null
    ioFlags = null;
  }

  entries.add(
    ParametersCompanion(
      algorithmGuid: Value(paramData['algorithmGuid'] as String),
      parameterNumber: Value(paramData['parameterNumber'] as int),
      name: Value(paramData['name'] as String),
      minValue: Value(paramData['minValue'] as int?),
      maxValue: Value(paramData['maxValue'] as int?),
      defaultValue: Value(paramData['defaultValue'] as int?),
      unitId: Value(paramData['unitId'] as int?),
      powerOfTen: Value(paramData['powerOfTen'] as int?),
      rawUnitIndex: Value(paramData['rawUnitIndex'] as int?),
      ioFlags: Value(ioFlags),  // NEW
    ),
  );
}
```

### Offline Mode Integration

**Offline MIDI manager update:**
```dart
// In OfflineDistingMidiManager, when constructing ParameterInfo from DB:
final parameterInfo = ParameterInfo(
  algorithmIndex: slotIndex,
  parameterNumber: dbParam.parameterNumber,
  min: dbParam.minValue ?? 0,
  max: dbParam.maxValue ?? 0,
  defaultValue: dbParam.defaultValue ?? 0,
  unit: dbParam.unitId ?? 0,
  name: dbParam.name,
  powerOfTen: dbParam.powerOfTen ?? 0,
  ioFlags: dbParam.ioFlags ?? 0,  // NEW - default to 0 if null
);
```

### Files to Modify

**Database Schema:**
- `lib/db/tables.dart` - Add `ioFlags` column to Parameters table
- `lib/db/database.dart` - Update schema version, add migration

**JSON Export:**
- `lib/services/algorithm_json_exporter.dart` - Include ioFlags in export (if used)
- Or wherever full metadata export is implemented

**JSON Import:**
- `lib/services/metadata_import_service.dart` - Read ioFlags in `_importParameters()`

**Offline Mode:**
- `lib/domain/offline_disting_midi_manager.dart` - Use ioFlags from database

**Tests:**
- `test/db/database_test.dart` - Migration tests
- `test/services/metadata_import_service_test.dart` - Import/export tests
- `test/domain/offline_disting_midi_manager_test.dart` - Offline mode tests

### Schema Version History

**Version 1:** Original schema with powerOfTen, rawUnitIndex
**Version 2:** Added ioFlags column to Parameters table (this story)

### Testing Strategy

**Unit Tests:**
- Migration adds column successfully
- Export includes ioFlags field
- Import reads ioFlags correctly
- Import handles missing ioFlags (old format)
- Import validates flag range
- Offline mode retrieves from database

**Integration Tests:**
- Import old JSON (v1) without ioFlags
- Import new JSON (v2) with ioFlags
- Migration from v1 to v2 schema
- Export/import roundtrip preserves data

**Manual Testing:**
- Clear app data, verify migration runs
- Import old bundled metadata (still v1)
- Export current database to JSON
- Re-import exported JSON

### Important Notes

**This story does NOT:**
- Regenerate bundled metadata with I/O flags (Story 7.8)
- Query hardware for I/O flag data (Story 7.3)
- Change runtime SysEx parsing (Story 7.3)

**This story ONLY:**
- Adds database infrastructure
- Adds JSON export/import support
- Enables offline mode to store/retrieve I/O flags (once data is available)

**After this story:**
- Offline mode CAN store I/O flags if they exist in database
- Offline mode WILL still have `ioFlags = null` for all params (no data yet)
- Story 7.8 will populate the data by regenerating bundled metadata

### Related Stories

- **Story 7.3** - Adds ioFlags to ParameterInfo runtime model (prerequisite)
- **Story 7.8** - Regenerates bundled metadata with I/O flags (follows this story)
- **Story 7.5** - Consumes I/O flags in routing (depends on this for offline support)

### Reference Documents

- `lib/db/tables.dart` - Database schema definitions
- `lib/db/database.dart` - Database class and migrations
- `lib/services/metadata_import_service.dart` - JSON import logic
- Drift documentation: https://drift.simonbinder.eu/docs/advanced-features/migrations/

## Dev Agent Record

### Context Reference

- TBD: docs/stories/7-7-add-io-flags-to-offline-metadata.context.xml

### Agent Model Used

TBD

### Completion Notes List

- TBD

### File List

**Modified:**
- TBD

**Added:**
- TBD

### Change Log

- **2025-11-18:** Story created by Business Analyst (Mary)
