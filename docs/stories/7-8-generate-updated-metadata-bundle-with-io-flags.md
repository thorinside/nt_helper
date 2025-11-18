# Story 7.8: Generate Updated Metadata Bundle with I/O Flags

Status: pending

## Story

As a developer maintaining the nt_helper bundled metadata,
I want to regenerate `assets/metadata/full_metadata.json` with I/O flag data from live hardware,
So that offline mode has access to I/O flags without requiring users to connect to hardware.

## Context

Story 7.7 adds database and JSON infrastructure for I/O flags, but the bundled metadata file (`assets/metadata/full_metadata.json`) was generated before I/O flags existed. This file is loaded on first app launch to populate the offline database, providing metadata for all factory algorithms.

Without regenerated metadata:
- Offline mode has `ioFlags = null` for all parameters (no data)
- Routing editor can't use I/O flags in offline mode
- Users must connect to hardware to get I/O flag data

This story connects to live hardware, queries all algorithms for I/O flags, and regenerates the bundled metadata JSON with complete I/O flag data.

**Note:** This is a utility/maintenance story that produces an asset update, not code changes.

## Acceptance Criteria

### AC-1: Hardware Connection Setup

1. Access to distingNT hardware with latest firmware (supports I/O flags)
2. Hardware has all factory algorithms available
3. MIDI connection stable and reliable
4. Sufficient time allocated for querying all algorithms (potentially long-running)

### AC-2: Metadata Collection Script

5. Create or update metadata collection script/tool
6. Script connects to hardware via MIDI
7. Script iterates through all factory algorithms
8. For each algorithm:
   - Load algorithm into slot
   - Request all parameter info (SysEx 0x43)
   - Collect I/O flags from responses
   - Store parameter metadata with I/O flags

### AC-3: Data Validation

9. Verify all factory algorithms queried successfully
10. Verify no algorithms skipped or failed
11. Verify I/O flags present for all parameters
12. Validate flag values are in valid range (0-15)
13. Cross-reference with known algorithm list (completeness check)
14. Spot-check known algorithms for expected flag values

### AC-4: JSON Export Generation

15. Export collected metadata to JSON using updated export format (v2)
16. Include all required tables: units, algorithms, parameters, enums, pages
17. Include `ioFlags` field for all parameters
18. Verify JSON is valid and well-formed
19. Verify export version is 2 (indicates I/O flags present)
20. Verify file size is reasonable (should be similar to old version)

### AC-5: Bundle Update

21. Replace `assets/metadata/full_metadata.json` with new version
22. Verify new file loads successfully in app
23. Verify offline mode has I/O flags after loading new metadata
24. Test import with new bundled metadata on fresh install
25. Verify no data loss or corruption

### AC-6: Backwards Compatibility

26. Old app versions ignore `ioFlags` field gracefully (tested in Story 7.7)
27. New app can still import old metadata (null flags, tested in Story 7.7)
28. Document metadata version in export file (v2)

### AC-7: Documentation

29. Document metadata collection process for future updates
30. Document hardware setup requirements
31. Document export verification steps
32. Add metadata generation date to JSON file
33. Update CHANGELOG or release notes about new metadata

### AC-8: Code Quality

34. Metadata collection script is repeatable and documented
35. JSON file passes validation (well-formed JSON)
36. No `flutter analyze` warnings related to bundled asset
37. App loads and uses new metadata successfully

## Tasks / Subtasks

- [ ] Task 1: Prepare hardware and environment (AC-1)
  - [ ] Verify hardware has latest firmware
  - [ ] Establish stable MIDI connection
  - [ ] Verify all factory algorithms available
  - [ ] Allocate time for metadata collection (~30-60 min)

- [ ] Task 2: Create/update collection script (AC-2)
  - [ ] Write or locate existing metadata collection tool
  - [ ] Implement algorithm iteration logic
  - [ ] Implement parameter info querying
  - [ ] Implement I/O flag extraction from responses
  - [ ] Store data in structured format

- [ ] Task 3: Collect metadata from hardware (AC-2, AC-3)
  - [ ] Run collection script against hardware
  - [ ] Monitor progress and handle any failures
  - [ ] Validate all algorithms collected
  - [ ] Verify flag data completeness
  - [ ] Spot-check known algorithms

- [ ] Task 4: Generate JSON export (AC-4)
  - [ ] Export collected data to JSON v2 format
  - [ ] Include all required tables
  - [ ] Verify ioFlags present for all params
  - [ ] Validate JSON structure
  - [ ] Check file size is reasonable

- [ ] Task 5: Update bundled metadata (AC-5)
  - [ ] Replace `assets/metadata/full_metadata.json`
  - [ ] Test app loads new metadata
  - [ ] Verify offline mode has I/O flags
  - [ ] Test fresh install scenario
  - [ ] Verify no data corruption

- [ ] Task 6: Test backwards compatibility (AC-6)
  - [ ] Confirm old apps ignore new field
  - [ ] Confirm new app imports old format
  - [ ] Document metadata version

- [ ] Task 7: Document process (AC-7)
  - [ ] Document collection process
  - [ ] Document hardware requirements
  - [ ] Document verification steps
  - [ ] Update changelog/release notes

- [ ] Task 8: Final validation (AC-8)
  - [ ] Verify script is documented
  - [ ] Validate JSON file
  - [ ] Run flutter analyze
  - [ ] Test app with new metadata

## Dev Notes

### Architecture Context

**Metadata Collection Workflow:**
```
1. Connect to hardware
2. For each factory algorithm:
   a. Load into slot 0
   b. Request number of parameters (0x42)
   c. For each parameter:
      - Request parameter info (0x43)
      - Extract: name, min, max, default, unit, powerOfTen, ioFlags
   d. Request enum strings (0x49) if applicable
   e. Request parameter pages (0x52)
3. Build complete metadata structure
4. Export to JSON v2 format
5. Replace bundled asset file
```

**Data Collection Considerations:**
- Some algorithms take time to load
- SysEx responses may need debouncing/waiting
- Order of algorithms doesn't matter (will be sorted)
- Community plugins not included (only factory algorithms)

### Collection Script Options

**Option 1: Desktop tool using nt_helper codebase**
- Use existing SysEx infrastructure
- Run in demo/test mode with actual hardware
- Export directly using `AlgorithmJsonExporter`

**Option 2: Python script (if distingNT repo has tools)**
- Use existing Python tools from distingNT repository
- Convert output to nt_helper JSON format

**Option 3: MCP-based collection**
- Use nt_helper with MCP tools
- External script drives collection via MCP API
- Export using existing export tools

**Recommended: Option 1** - Leverage existing codebase and SysEx handling

### Metadata Collection Tool Example

**Conceptual structure:**
```dart
class MetadataCollector {
  final IDistingMidiManager midiManager;
  final Map<String, AlgorithmMetadata> collected = {};

  Future<void> collectAllAlgorithms() async {
    final numAlgorithms = await midiManager.requestNumAlgorithms();

    for (int i = 0; i < numAlgorithms; i++) {
      // Load algorithm into slot 0
      await midiManager.setAlgorithm(0, i);
      await Future.delayed(Duration(milliseconds: 500)); // Wait for load

      // Get algorithm info
      final algorithmInfo = await midiManager.requestAlgorithmInfo(0);

      // Get parameter count
      final numParams = await midiManager.requestNumParameters(0);

      // Collect all parameters
      final parameters = <ParameterInfo>[];
      for (int p = 0; p < numParams; p++) {
        final paramInfo = await midiManager.requestParameterInfo(0, p);
        parameters.add(paramInfo);
      }

      // Store collected data
      collected[algorithmInfo.guid] = AlgorithmMetadata(
        info: algorithmInfo,
        parameters: parameters,
        // ... other metadata
      );
    }
  }

  Future<void> exportToJson(String path) async {
    // Use AlgorithmJsonExporter or similar
    // Generate JSON v2 format with ioFlags
  }
}
```

### Known Factory Algorithms (Spot Check)

**Algorithms to verify have correct I/O flags:**
- **clck (Clock)**: Clock parameter should have `isInput = true`
- **pycv (Poly CV)**: Gate outputs should have `isOutput = true, isAudio = false`
- **eucl (Euclidean)**: Should have output mode parameters with `isOutputMode = true`
- **AA** algorithms (Audio processing): Should have `isAudio = true` for audio I/O

### Bundled Metadata File Location

**Current file:**
- `assets/metadata/full_metadata.json`

**Backup strategy:**
- Keep copy of old metadata: `assets/metadata/full_metadata_v1_backup.json`
- Allows rollback if new version has issues

### Verification Checklist

**Before replacing bundled file:**
- [ ] JSON is valid (use JSON validator)
- [ ] All factory algorithms present (count matches known list)
- [ ] All parameters have ioFlags field
- [ ] Flag values are in range (0-15)
- [ ] File size is reasonable (~similar to old version)
- [ ] Test import in dev environment

**After replacing bundled file:**
- [ ] Fresh install loads successfully
- [ ] Offline mode shows I/O flags for parameters
- [ ] No database errors
- [ ] Routing editor works with I/O flags
- [ ] Export version is 2

### Files to Modify

**Assets:**
- `assets/metadata/full_metadata.json` - Replace with new version

**Optional Scripts (if creating new tools):**
- `tools/metadata_collector.dart` - New metadata collection script (if needed)
- Or use existing debug/export tools

**Documentation:**
- `docs/metadata-generation.md` - Document process (if doesn't exist)
- `CHANGELOG.md` - Note metadata bundle update

### Testing Strategy

**Pre-Generation:**
- Verify hardware connection stable
- Verify firmware version supports I/O flags
- Test collection script with single algorithm

**Post-Generation:**
- Validate JSON structure
- Verify data completeness
- Spot-check known algorithms
- Test import in dev environment

**Integration Testing:**
- Fresh install with new metadata
- Offline mode uses I/O flags
- Routing editor visualizes correctly
- No regressions in existing functionality

### Time Estimates

**Metadata Collection:**
- ~100 factory algorithms
- ~30-60 seconds per algorithm (load + query)
- Total: ~50-100 minutes

**Development:**
- Script creation/update: 2-4 hours
- Data collection: 1-2 hours
- Validation and testing: 2-3 hours
- Total: 5-9 hours

### Important Notes

**This story produces:**
- Updated bundled metadata JSON file
- Documentation for future metadata regeneration
- Validation that I/O flags are complete

**This story does NOT:**
- Change any code (pure asset update)
- Modify database schema (Story 7.7)
- Change SysEx parsing (Story 7.3)

**Dependencies:**
- Requires Story 7.7 (database infrastructure for ioFlags)
- Requires Story 7.3 (SysEx parsing includes ioFlags)
- Requires live hardware with I/O flag support

**Success Criteria:**
- Offline mode has I/O flags for all factory algorithms
- Users don't need hardware to get I/O flag data
- Fresh installs have complete metadata

### Related Stories

- **Story 7.7** - Adds database/JSON infrastructure (prerequisite)
- **Story 7.3** - Adds ioFlags to ParameterInfo (prerequisite)
- **Story 7.5** - Uses I/O flags in routing (benefits from this data)

### Reference Documents

- `lib/services/algorithm_json_exporter.dart` - Export implementation
- `lib/services/metadata_import_service.dart` - Import verification
- distingNT firmware documentation (I/O flag support)

## Dev Agent Record

### Context Reference

- TBD: docs/stories/7-8-generate-updated-metadata-bundle-with-io-flags.context.xml

### Agent Model Used

TBD

### Completion Notes List

- TBD

### File List

**Modified:**
- assets/metadata/full_metadata.json (replaced with new version)

**Added:**
- tools/metadata_collector.dart (if new script created)
- assets/metadata/full_metadata_v1_backup.json (backup of old version)

### Change Log

- **2025-11-18:** Story created by Business Analyst (Mary)
