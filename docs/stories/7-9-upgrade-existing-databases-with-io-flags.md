# Story 7.9: Upgrade Existing Databases with I/O Flags

Status: pending

## Story

As a user who installed nt_helper before I/O flags were added,
I want my existing offline database automatically upgraded with I/O flag data from the bundled metadata,
So that offline mode works with I/O flags without requiring me to reinstall the app or connect to hardware.

## Context

When users upgrade from an older version of nt_helper to a version with I/O flags:
1. Database schema migrates (adds `ioFlags` column) → all values = null
2. Bundled metadata (`assets/metadata/full_metadata.json`) has I/O flags (from Story 7.8)
3. But existing installations never re-import the bundled metadata (only runs on empty database)
4. Result: Offline mode has no I/O flags, routing editor can't use flag data

This story implements a simple upgrade mechanism: If all parameters have `ioFlags = null`, re-import parameter I/O flags from the bundled metadata to fill in the known data.

**Strategy:** Selective parameter field update (ioFlags only), preserving all other user data.

## Acceptance Criteria

### AC-1: Detect Missing I/O Flags

1. On app startup, after database initialization, check if I/O flags need upgrading
2. Query database: Count parameters where `ioFlags IS NOT NULL`
3. If count = 0 (all parameters have null flags) → trigger upgrade
4. If count > 0 (some flags exist) → skip upgrade (assume data is present)
5. Check is fast and non-blocking (doesn't delay app startup)

### AC-2: Selective Import from Bundled Metadata

6. Load bundled metadata JSON (`assets/metadata/full_metadata.json`)
7. Parse parameters table from JSON
8. For each parameter in bundled metadata:
   - Look up matching parameter in database by (algorithmGuid, parameterNumber)
   - Update ONLY the `ioFlags` field if parameter exists
   - Preserve all other fields (name, min, max, unit, etc.)
9. Use batch update for performance (not individual updates)
10. Skip parameters not found in database (new algorithms added later)

### AC-3: Preserve User Data

11. User presets remain unchanged (not touched during upgrade)
12. User templates remain unchanged
13. Saved parameter values remain unchanged
14. Only parameter metadata (`ioFlags` field) is updated
15. No data loss or corruption

### AC-4: Upgrade Logging

16. Log when upgrade is triggered: "Upgrading database with I/O flags from bundled metadata"
17. Log number of parameters updated
18. Log if bundled metadata is missing or invalid (skip upgrade gracefully)
19. Log upgrade completion: "I/O flags upgrade complete: X parameters updated"
20. Errors during upgrade are logged but don't prevent app startup

### AC-5: Idempotent Upgrade

21. Upgrade is safe to run multiple times (idempotent)
22. If run on database that already has flags → no changes made
23. If run on database with partial flags → fills in missing flags only
24. No negative side effects from re-running upgrade

### AC-6: Fresh Install Behavior

25. Fresh installs skip upgrade (already have I/O flags from bundled import)
26. Fresh install detection: hasCachedAlgorithms() == false → normal import
27. Existing install detection: hasCachedAlgorithms() == true + all flags null → upgrade
28. Upgrade only runs on existing installations with missing data

### AC-7: Offline Mode Verification

29. After upgrade, offline mode has I/O flags for all factory algorithms
30. `ParameterInfo` constructed from database includes `ioFlags` values
31. Routing editor can use I/O flags in offline mode
32. No hardware connection required for upgrade

### AC-8: Performance

33. Upgrade completes in reasonable time (< 5 seconds for ~2000 parameters)
34. Uses batch operations (not individual updates)
35. Doesn't block UI thread during upgrade
36. Progress not displayed to user (happens silently in background)

### AC-9: Error Handling

37. If bundled metadata file missing → log warning, skip upgrade
38. If bundled metadata invalid JSON → log error, skip upgrade
39. If database update fails → log error, continue app startup
40. App remains functional even if upgrade fails

### AC-10: Unit Testing

41. Unit test verifies upgrade detection (all null → trigger)
42. Unit test verifies upgrade skip (has flags → skip)
43. Unit test verifies selective field update (ioFlags only)
44. Unit test verifies batch update performance
45. Unit test verifies idempotent behavior
46. Unit test verifies error handling (missing file, invalid JSON)

### AC-11: Integration Testing

47. Integration test simulates old database upgrade
48. Integration test verifies I/O flags present after upgrade
49. Integration test verifies user presets preserved
50. Integration test verifies fresh install unaffected

### AC-12: Documentation

51. Document upgrade mechanism in code comments
52. Document that upgrade runs once on first startup after schema migration
53. Add inline comments explaining selective update logic
54. Update architecture docs about metadata upgrade strategy

### AC-13: Code Quality

55. `flutter analyze` passes with zero warnings
56. All existing tests pass with no regressions
57. Upgrade doesn't cause database corruption
58. Logging is clear and actionable

## Tasks / Subtasks

- [ ] Task 1: Implement upgrade detection (AC-1)
  - [ ] Add method to check if upgrade needed
  - [ ] Query count of parameters with non-null ioFlags
  - [ ] Return true if count = 0, false otherwise
  - [ ] Make check fast and non-blocking

- [ ] Task 2: Implement selective import logic (AC-2)
  - [ ] Load bundled metadata JSON
  - [ ] Parse parameters from JSON
  - [ ] Build map of (algorithmGuid, parameterNumber) → ioFlags
  - [ ] Generate batch UPDATE statements
  - [ ] Execute batch update

- [ ] Task 3: Integrate into startup flow (AC-1, AC-6)
  - [ ] Call upgrade check after database initialization
  - [ ] Only run on existing installations (not fresh installs)
  - [ ] Run before loading offline metadata into memory
  - [ ] Don't block UI initialization

- [ ] Task 4: Add logging (AC-4)
  - [ ] Log upgrade trigger
  - [ ] Log parameter count updated
  - [ ] Log errors gracefully
  - [ ] Log completion

- [ ] Task 5: Ensure data preservation (AC-3)
  - [ ] Verify UPDATE only touches ioFlags column
  - [ ] Verify presets table untouched
  - [ ] Verify templates untouched
  - [ ] Test with existing user data

- [ ] Task 6: Implement error handling (AC-9)
  - [ ] Handle missing bundled metadata
  - [ ] Handle invalid JSON
  - [ ] Handle database errors
  - [ ] Continue app startup on failure

- [ ] Task 7: Optimize performance (AC-8)
  - [ ] Use batch UPDATE (not loop)
  - [ ] Run on background isolate if needed
  - [ ] Measure upgrade time
  - [ ] Ensure < 5 second completion

- [ ] Task 8: Write unit tests (AC-10)
  - [ ] Test upgrade detection logic
  - [ ] Test selective update
  - [ ] Test idempotent behavior
  - [ ] Test error handling
  - [ ] Test batch operations

- [ ] Task 9: Write integration tests (AC-11)
  - [ ] Test full upgrade flow
  - [ ] Test fresh install unaffected
  - [ ] Test user data preserved
  - [ ] Test offline mode works after upgrade

- [ ] Task 10: Document implementation (AC-12)
  - [ ] Add code comments
  - [ ] Update architecture docs
  - [ ] Document upgrade trigger conditions

- [ ] Task 11: Validation (AC-13)
  - [ ] Run flutter analyze
  - [ ] Run all tests
  - [ ] Manual test upgrade scenario
  - [ ] Verify no data corruption

## Dev Notes

### Architecture Context

**Upgrade Trigger Logic:**
```dart
class MetadataUpgradeService {
  Future<bool> needsIoFlagsUpgrade(AppDatabase database) async {
    // Check if any parameters have ioFlags set
    final countWithFlags = await database.customSelect(
      'SELECT COUNT(*) as count FROM parameters WHERE io_flags IS NOT NULL',
      readsFrom: {database.parameters},
    ).getSingle();

    final count = countWithFlags.read<int>('count');
    return count == 0; // Need upgrade if all flags are null
  }
}
```

**Selective Update Implementation:**
```dart
Future<void> upgradeIoFlags(AppDatabase database) async {
  // Load bundled metadata
  final jsonString = await rootBundle.loadString(
    'assets/metadata/full_metadata.json',
  );
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final tables = data['tables'] as Map<String, dynamic>;
  final paramsList = tables['parameters'] as List<dynamic>;

  // Build update batch
  final updates = <({String guid, int paramNum, int ioFlags})>[];
  for (final paramData in paramsList) {
    final ioFlags = paramData['ioFlags'] as int?;
    if (ioFlags != null) {
      updates.add((
        guid: paramData['algorithmGuid'] as String,
        paramNum: paramData['parameterNumber'] as int,
        ioFlags: ioFlags,
      ));
    }
  }

  // Execute batch update
  await database.batch((batch) {
    for (final update in updates) {
      batch.execute(
        'UPDATE parameters SET io_flags = ? WHERE algorithm_guid = ? AND parameter_number = ?',
        [update.ioFlags, update.guid, update.paramNum],
      );
    }
  });

  print('I/O flags upgrade complete: ${updates.length} parameters updated');
}
```

**Integration into Startup:**
```dart
// In AlgorithmMetadataService.initialize()
Future<void> initialize(AppDatabase database) async {
  if (_isInitialized) return;

  // Import bundled metadata if database is empty
  await _checkAndImportBundledMetadata(database);

  // NEW: Upgrade existing databases with I/O flags
  await _upgradeIoFlagsIfNeeded(database);

  await _loadFeatures();
  await _loadAlgorithms();
  await _mergeSyncedAlgorithms(database);

  _isInitialized = true;
}

Future<void> _upgradeIoFlagsIfNeeded(AppDatabase database) async {
  try {
    final upgradeService = MetadataUpgradeService();
    if (await upgradeService.needsIoFlagsUpgrade(database)) {
      print('Upgrading database with I/O flags from bundled metadata');
      await upgradeService.upgradeIoFlags(database);
    }
  } catch (e) {
    // Log error but don't fail initialization
    print('I/O flags upgrade failed: $e');
  }
}
```

### Upgrade Scenarios

**Scenario 1: Fresh Install**
- Database empty
- `_checkAndImportBundledMetadata()` imports full metadata (includes ioFlags)
- `needsIoFlagsUpgrade()` returns false (flags already present)
- No upgrade needed ✅

**Scenario 2: Existing Install (pre-I/O flags)**
- Database has parameters from old version
- Schema migration added `ioFlags` column → all null
- `needsIoFlagsUpgrade()` returns true (count = 0)
- Upgrade runs, fills in ioFlags from bundled metadata ✅

**Scenario 3: Existing Install (post-I/O flags, used hardware)**
- Database has parameters with ioFlags from live hardware
- `needsIoFlagsUpgrade()` returns false (count > 0)
- No upgrade needed ✅

**Scenario 4: Partial Data**
- Database has some parameters with ioFlags, some null (edge case)
- `needsIoFlagsUpgrade()` returns false (count > 0)
- Could enhance to check percentage, but simple "any flags exist" is safer
- User can sync with hardware or reinstall for complete data

### SQL Performance

**Batch UPDATE is critical:**
- ~2000 parameters across ~100 algorithms
- Individual UPDATEs: ~2000 statements → slow
- Batch UPDATE: Single transaction → fast

**Batch operation example:**
```sql
BEGIN TRANSACTION;
UPDATE parameters SET io_flags = 5 WHERE algorithm_guid = 'clck' AND parameter_number = 0;
UPDATE parameters SET io_flags = 2 WHERE algorithm_guid = 'clck' AND parameter_number = 1;
-- ... ~2000 more updates
COMMIT;
```

### Error Handling Strategy

**Non-critical errors (log and continue):**
- Bundled metadata file missing → Skip upgrade
- JSON parse error → Skip upgrade
- Database error during upgrade → Skip upgrade

**Critical errors (fail startup):**
- None - upgrade failures should never prevent app from starting
- Worst case: User has offline mode without I/O flags (same as before upgrade)

### Testing Strategy

**Unit Tests:**
- Mock database with null ioFlags → verify upgrade triggers
- Mock database with some ioFlags → verify upgrade skips
- Mock bundled metadata → verify selective update
- Test error handling for each failure mode

**Integration Tests:**
- Create test database with old schema
- Run migration to add ioFlags column
- Run upgrade
- Verify ioFlags populated
- Verify presets unchanged

**Manual Testing:**
1. Install old version of app
2. Use offline mode (populate database)
3. Upgrade to new version
4. Verify I/O flags appear in offline mode
5. Verify saved presets still work

### Files to Modify

**New Service:**
- `lib/services/metadata_upgrade_service.dart` - New file for upgrade logic

**Existing Services:**
- `lib/services/algorithm_metadata_service.dart` - Add upgrade check to initialize()

**Database:**
- No schema changes (migration from Story 7.7 already done)

**Tests:**
- `test/services/metadata_upgrade_service_test.dart` - New test file
- `test/services/algorithm_metadata_service_test.dart` - Add upgrade tests

### Important Notes

**This story assumes:**
- Story 7.7 completed (database schema has ioFlags column)
- Story 7.8 completed (bundled metadata has ioFlags data)
- Migration already run (ioFlags column exists with null values)

**This story does NOT:**
- Modify database schema (already done in Story 7.7)
- Generate metadata (already done in Story 7.8)
- Handle output mode usage data (runtime-only data, not in metadata)

**Upgrade is one-time:**
- Runs once when first detecting all-null flags
- After upgrade, never runs again (count > 0)
- Future app updates with new metadata would need different strategy

**Future enhancement:**
- Could add metadata version number to detect newer bundled data
- Could run upgrade if bundled version > stored version
- Current approach is simpler: only runs once to fill missing data

### Related Stories

- **Story 7.7** - Adds database infrastructure (prerequisite)
- **Story 7.8** - Generates bundled metadata with ioFlags (prerequisite)
- **Story 7.3** - Adds ioFlags to ParameterInfo model (related)

### Reference Documents

- `lib/services/algorithm_metadata_service.dart` - Startup initialization
- `lib/services/metadata_import_service.dart` - Import patterns
- `lib/db/database.dart` - Database operations

## Dev Agent Record

### Context Reference

- TBD: docs/stories/7-9-upgrade-existing-databases-with-io-flags.context.xml

### Agent Model Used

TBD

### Completion Notes List

- TBD

### File List

**Modified:**
- lib/services/algorithm_metadata_service.dart - Add upgrade check to initialization

**Added:**
- lib/services/metadata_upgrade_service.dart - New upgrade service
- test/services/metadata_upgrade_service_test.dart - Unit tests

### Change Log

- **2025-11-18:** Story created by Business Analyst (Mary)
