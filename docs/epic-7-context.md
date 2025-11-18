# Epic 7: SysEx Updates - Technical Context

**Generated:** 2025-11-18
**Epic:** 7 (SysEx Updates & I/O Metadata)
**Status:** Ready for Story Development
**Story Count:** 9 stories (E7.1 through E7.9)

---

## Epic Overview

**Goal:** Extract and utilize I/O metadata from distingNT firmware SysEx messages to replace pattern matching in the routing framework with explicit hardware-provided data.

**Value:** The distingNT firmware now encodes parameter I/O metadata (input/output direction, audio/CV signal type, output mode control) in SysEx responses. Currently, nt_helper infers these properties through fragile parameter name pattern matching. This epic transitions the routing framework to use explicit hardware data as the single source of truth, enabling:
- Data-driven port configuration (no pattern matching)
- Accurate routing visualization for all algorithms
- Offline mode support via bundled metadata
- Future-proof architecture as firmware evolves

**Key Design Principles:**
1. **Hardware as Source of Truth** - I/O flags and output mode data come from firmware, not heuristics
2. **Offline Parity** - Bundled metadata enables offline mode to match online capabilities
3. **Backward Compatibility** - Database migrations and import/export preserve existing user data
4. **Sequential Implementation** - Stories build on each other to avoid code conflicts

---

## Current State Analysis

### Existing SysEx Infrastructure

**SysEx Parser** (`lib/domain/sysex/sysex_parser.dart`)
- Parses incoming SysEx messages from distingNT
- Identifies message type from byte 6 (e.g., 0x43 = parameter info, 0x44 = all parameter values)
- Extracts payload and dispatches to response handlers

**Response Factory** (`lib/domain/sysex/response_factory.dart`)
- Maps message types to response classes
- Example: `respParameterInfo(0x43)` → `ParameterInfoResponse`

**Current Parameter Info Parsing:**
```dart
// lib/domain/sysex/responses/parameter_info_response.dart
ParameterInfo parse() {
  return ParameterInfo(
    algorithmIndex: decode8(data.sublist(0, 1)),
    parameterNumber: decode16(data, 1),
    min: decode16(data, 4),
    max: decode16(data, 7),
    defaultValue: decode16(data, 10),
    unit: decode8(data.sublist(13, 14)),
    name: decodeNullTerminatedAscii(data, 14).value,
    powerOfTen: data.last,  // Only extracts powerOfTen from last byte
  );
}
```

**Missing:** I/O flags extraction from bits 2-5 of last byte

### Routing Framework Architecture

**AlgorithmRouting Base Class** (`lib/core/routing/algorithm_routing.dart`)
- Factory method `AlgorithmRouting.fromSlot()` creates routing instances
- Specialized subclasses: `PolyAlgorithmRouting`, `MultiChannelAlgorithmRouting`, `ES5DirectOutputAlgorithmRouting`

**Port Model** (`lib/core/routing/models/port.dart`)
- Represents input/output connection points
- Current types: `audio`, `cv`, `gate`, `clock` (gate/clock are artificial)
- Output mode: `add`, `replace`

**Current Pattern Matching (to be replaced):**
```dart
// lib/core/routing/multi_channel_algorithm_routing.dart:748-766

// Input/output detection via name matching
final lowerName = paramName.toLowerCase();
final isOutput = lowerName.contains('output') ||
                 (lowerName.contains('out') && !lowerName.contains('input'));

// Port type inference via name matching
String portType = 'audio';
if (lowerName.contains('cv') ||
    lowerName.contains('gate') ||
    lowerName.contains('clock')) {
  portType = 'cv'; // or 'gate' or 'clock'
}

// Mode parameter detection via name matching
final hasMatchingModeParameter =
    modeParameters?.containsKey('$paramName mode') ?? false;
```

**Problems:**
- Fragile: Breaks if parameter names change
- Incomplete: Can't handle non-standard naming
- Artificial: `gate`/`clock` types don't exist in hardware
- No offline support: Pattern matching requires parameter names only available online

### Offline Metadata Infrastructure

**Database Schema** (`lib/db/tables.dart`)
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
  // Missing: ioFlags column
}
```

**Metadata Import/Export** (`lib/services/metadata_import_service.dart`)
- Imports bundled metadata on first launch: `assets/metadata/full_metadata.json`
- Current format lacks `ioFlags` field in parameters
- Import only runs once (empty database detection)

**Current Bundled Metadata:**
- Format version: 1
- Generated: 2025-10-23
- Contains: ~100 factory algorithms, ~2000 parameters
- Missing: I/O flags for all parameters

---

## Firmware Changes (distingNT Repository)

### Commit 71bf796: I/O Flags in Parameter Definitions

**Change:** Last byte of parameter info response now contains both scaling and I/O flags

**Bit Layout:**
```
Bits 0-1: powerOfTen (10^n scaling where n = 0-3)
Bits 2-5: ioFlags (4-bit field):
  Bit 0 (value 1): isInput - Parameter is an input
  Bit 1 (value 2): isOutput - Parameter is an output
  Bit 2 (value 4): isAudio - Audio signal (true) vs CV (false)
  Bit 3 (value 8): isOutputMode - Parameter controls output mode
```

**Example Values:**
- `0x00` = No scaling, no I/O metadata
- `0x04` = No scaling, input parameter (bit 0 set)
- `0x08` = No scaling, output parameter (bit 1 set)
- `0x15` = 10^1 scaling, input + audio (bits 0,2 set)

**Audio vs CV Interpretation:**
- Audio flag affects hardware display only (VU meters vs voltage)
- Does NOT affect signal processing (everything is voltage in Eurorack)
- Purely cosmetic distinction for UI presentation

### Commit 39b5376: Output Mode Usage (SysEx 0x55)

**New Message Type:** 0x55 - Query output mode usage relationships

**Request Format:**
```
[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, p_high, p_mid, p_low, 0xF7]
```
- Queries which parameters are affected by a mode control parameter
- Parameter number encoded as 16-bit value in three 7-bit bytes

**Response Format:**
```
[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot,
 source_high, source_mid, source_low,  // Mode control parameter
 count,                                 // Number of affected parameters
 affected_1_high, affected_1_mid, affected_1_low,  // First affected param
 ...
 0xF7]
```

**Purpose:** Explicitly maps mode parameters to their controlled outputs
- Replaces pattern matching: `'$paramName mode'`
- Enables accurate Add/Replace mode visualization
- Supports complex routing configurations

---

## State Management

### DistingCubit (`lib/cubit/disting_cubit.dart`)

**Current State:**
- Central source of truth for device state
- Manages `Slot` objects with algorithms and parameters
- Handles SysEx communication via `IDistingMidiManager`

**Required Changes:**
- Store output mode usage map per slot
- Propagate I/O flags through `Slot` model
- Trigger output mode queries when `isOutputMode` flag detected

### Slot Model (`lib/models/slot.dart`)

**Current:**
```dart
class Slot {
  final String? algorithmGuid;
  final List<ParameterValue> parameters;
  final PackedMappingData? mappingData;
  // ...
}
```

**Required:**
```dart
class Slot {
  final String? algorithmGuid;
  final List<ParameterValue> parameters;
  final PackedMappingData? mappingData;
  final Map<int, OutputModeUsage>? outputModeMap;  // NEW
  // ...
}
```

### MIDI Managers

**IDistingMidiManager Interface** - Base interface for all modes

**DistingMidiManager** - Live hardware communication
- Sends/receives SysEx messages
- Needs: `requestOutputModeUsage(slot, parameterNumber)` method

**OfflineDistingMidiManager** - Cached database data
- Reads parameter metadata from database
- Needs: Return `ioFlags` from database (once available)

**MockDistingMidiManager** - Simulated data
- Returns hardcoded mock data
- Behavior: Return `ioFlags = 0` (no metadata in mock mode)

---

## Data Flow

### Story 7.3: Runtime I/O Flags

```
Hardware → SysEx 0x43 Response → ParameterInfoResponse.parse()
  → Extract ioFlags from last byte (bits 2-5)
  → ParameterInfo with ioFlags field
  → DistingCubit state
  → Routing framework (Story 7.5)
```

### Story 7.4: Output Mode Usage

```
ParameterInfo with isOutputMode=true detected
  → DistingCubit triggers SysEx 0x55 request
  → Hardware responds with affected parameter list
  → OutputModeUsageResponse.parse()
  → Store in Slot.outputModeMap
  → Routing framework (Story 7.6)
```

### Story 7.7-7.9: Offline Metadata

```
Story 7.7: Database schema + JSON format updated

Story 7.8: Hardware collection
  → Query all algorithms for parameter info with ioFlags
  → Export to JSON v2 format
  → Replace assets/metadata/full_metadata.json

Story 7.9: Upgrade detection
  → App startup: Check if all ioFlags == null
  → If yes: Import ioFlags from bundled metadata
  → Offline mode now has I/O flags
```

### Story 7.5-7.6: Routing Refactor

```
Story 7.5:
  AlgorithmRouting.fromSlot()
    → Read ParameterInfo.isInput/isOutput (not name matching)
    → Read ParameterInfo.isAudio → PortType.audio/cv
    → Create ports with correct types and colors

Story 7.6:
  AlgorithmRouting.fromSlot()
    → Read ParameterInfo.isOutputMode flag
    → Lookup Slot.outputModeMap[parameterNumber]
    → Get affected parameter list
    → Read mode parameter value (0=Add, 1=Replace)
    → Set Port.outputMode for affected parameters
```

---

## Key Design Decisions

### Why Sequential Implementation?

**Code Overlap:**
- Stories 7.3-7.6 all modify routing framework
- Stories 7.7-7.9 all modify database/import/export
- Parallel work would cause merge conflicts

**Dependency Chain:**
- 7.4 needs 7.3's `isOutputMode` flag
- 7.8 needs 7.7's export capability
- 7.9 needs 7.8's bundled data
- 7.5 needs 7.9 for offline support
- 7.6 needs 7.4's output mode data

### Why Not Store Output Mode Usage Offline?

**Reasons:**
- Dynamic data queried on-demand from hardware
- Rarely changes (algorithm-specific relationships)
- Complex to store (junction table or JSON field)
- Not critical for offline mode functionality

**Alternative:**
- Pattern matching fallback for offline mode
- Future: Could pre-populate from known algorithm metadata

### Why Remove gate/clock Port Types?

**Hardware Reality:**
- Only two signal types in firmware: audio and CV
- gate/clock are artificial classifications

**Benefits:**
- Accurate representation of hardware capabilities
- Simpler port model (2 types instead of 4)
- No confusion about gate vs CV vs clock

**Compatibility:**
- All port types are voltage-compatible in Eurorack
- `Port.isCompatibleWith()` returns true for all types
- No connection restrictions by type

---

## Migration Strategy

### Database Schema Migration (Story 7.7)

**Migration Path:**
```
Schema v1 (current):
  - Parameters table without ioFlags

Schema v2 (after migration):
  - Parameters table with ioFlags (nullable integer)
  - Existing rows: ioFlags = null
```

**Drift Migration:**
```dart
onUpgrade: (Migrator m, int from, int to) async {
  if (from < 2) {
    await m.addColumn(parameters, parameters.ioFlags);
  }
}
```

### JSON Format Evolution (Story 7.7)

**Version 1 (current):**
```json
{
  "exportVersion": 1,
  "exportType": "full_metadata",
  "tables": {
    "parameters": [
      {
        "algorithmGuid": "clck",
        "parameterNumber": 0,
        "powerOfTen": 0
      }
    ]
  }
}
```

**Version 2 (with I/O flags):**
```json
{
  "exportVersion": 2,
  "exportType": "full_metadata",
  "tables": {
    "parameters": [
      {
        "algorithmGuid": "clck",
        "parameterNumber": 0,
        "powerOfTen": 0,
        "ioFlags": 5
      }
    ]
  }
}
```

**Import Compatibility:**
- v2 importer handles v1 format (missing ioFlags → null)
- v1 importer ignores ioFlags field (graceful degradation)

### Existing Database Upgrade (Story 7.9)

**Detection Logic:**
```sql
SELECT COUNT(*) FROM parameters WHERE io_flags IS NOT NULL
```
- If count = 0 → all flags are null → trigger upgrade
- If count > 0 → some flags exist → skip upgrade

**Upgrade Process:**
1. Load bundled metadata JSON
2. Build map: (algorithmGuid, parameterNumber) → ioFlags
3. Batch UPDATE: Set ioFlags for matching parameters
4. Preserve all other fields (name, min, max, etc.)
5. Preserve user presets/templates

**Performance:**
- ~2000 parameters across ~100 algorithms
- Batch operation in single transaction
- Target: < 5 seconds

---

## Testing Strategy

### Unit Testing

**Story 7.3:**
- Bit extraction: `powerOfTen` and `ioFlags` from last byte
- Helper getters: `isInput`, `isOutput`, `isAudio`, `isOutputMode`
- SysEx parsing with various flag combinations

**Story 7.4:**
- Request message encoding (16-bit to three 7-bit bytes)
- Response parsing (0, 1, many affected parameters)
- State updates when responses received

**Story 7.5:**
- Input/output detection via flags (not pattern matching)
- Port type inference via `isAudio` flag
- Audio/CV port colors

**Story 7.6:**
- Mode parameter identification via `isOutputMode` flag
- Output mode usage lookup
- Add/Replace mode determination

**Story 7.7:**
- Database migration adds `ioFlags` column
- JSON export includes `ioFlags` field
- JSON import reads `ioFlags` field

**Story 7.8:**
- (Mostly manual - hardware collection script)

**Story 7.9:**
- Upgrade detection (all null → trigger)
- Selective update (ioFlags only)
- Idempotent behavior

### Integration Testing

**Hardware Tests (require physical distingNT):**
- Story 7.3: Verify I/O flags parse correctly from live hardware
- Story 7.4: Verify output mode usage queries work
- Story 7.8: Verify metadata collection from all algorithms

**Database Tests:**
- Story 7.7: Migration from v1 to v2 schema
- Story 7.9: Upgrade from old database with null flags

**End-to-End Tests:**
- Fresh install: Bundled metadata loaded with I/O flags
- Existing install: Database upgraded with I/O flags
- Offline mode: Routing uses I/O flags from database
- Online mode: Routing uses I/O flags from hardware

### Manual Testing

**Routing Editor Verification:**
- Load various algorithms (Clock, Poly CV, Euclidean)
- Verify ports show correct types (audio vs CV colors)
- Verify input/output indicators
- Verify output mode connections (Add vs Replace)

**Offline Mode Verification:**
- Disconnect hardware
- Verify routing editor still functional
- Verify I/O flags available from database
- Verify pattern matching no longer used

---

## Files Overview

### Core Data Models
- `lib/domain/disting_nt_sysex.dart` - ParameterInfo class, message type enum
- `lib/models/slot.dart` - Slot model with output mode map

### SysEx Handling
- `lib/domain/sysex/sysex_parser.dart` - Message parser
- `lib/domain/sysex/response_factory.dart` - Response dispatcher
- `lib/domain/sysex/responses/parameter_info_response.dart` - 0x43 parser
- `lib/domain/sysex/responses/output_mode_usage_response.dart` - 0x55 parser (new)
- `lib/domain/sysex/requests/request_output_mode_usage.dart` - 0x55 request (new)

### Routing Framework
- `lib/core/routing/algorithm_routing.dart` - Base class
- `lib/core/routing/multi_channel_algorithm_routing.dart` - Main pattern matching site
- `lib/core/routing/models/port.dart` - Port model (remove gate/clock types)

### Database & Offline
- `lib/db/tables.dart` - Schema definitions (add ioFlags column)
- `lib/db/database.dart` - Database class (add migration)
- `lib/services/metadata_import_service.dart` - JSON import
- `lib/services/algorithm_json_exporter.dart` - JSON export
- `lib/services/metadata_upgrade_service.dart` - Upgrade service (new)

### MIDI Managers
- `lib/domain/i_disting_midi_manager.dart` - Interface
- `lib/domain/disting_midi_manager.dart` - Live hardware
- `lib/domain/offline_disting_midi_manager.dart` - Database
- `lib/domain/mock_disting_midi_manager.dart` - Mock data

### State Management
- `lib/cubit/disting_cubit.dart` - Central state management

### Assets
- `assets/metadata/full_metadata.json` - Bundled metadata (replace in 7.8)

---

## Success Criteria

**Epic 7 Complete When:**
1. ✅ I/O flags extracted from SysEx and stored in ParameterInfo
2. ✅ Output mode usage relationships queried and stored in state
3. ✅ Routing framework uses I/O flags (no pattern matching)
4. ✅ Routing framework uses output mode data (no pattern matching)
5. ✅ Database schema supports I/O flags
6. ✅ Bundled metadata includes I/O flags for all factory algorithms
7. ✅ Existing databases automatically upgraded with I/O flags
8. ✅ Offline mode has full I/O flag support
9. ✅ Port types reduced to audio/CV only
10. ✅ All tests pass, zero analyzer warnings

**User-Visible Impact:**
- Routing editor accurately reflects hardware I/O configuration
- No broken routing for non-standard parameter names
- Offline mode feature parity with online mode
- Future firmware updates automatically supported

---

## Future Enhancements

**Beyond Epic 7:**
- Community plugin I/O flags (when hardware supports it)
- Metadata version tracking for automatic bundle updates
- Visual output mode grouping in routing editor
- i2c routing visualization using I/O metadata

**Metadata Collection Automation:**
- GitHub Actions workflow to regenerate metadata on firmware updates
- Automated validation of bundled metadata completeness
- Diff reports showing metadata changes between versions

---

## References

**distingNT Repository:**
- Commit 71bf796: "support i/o flags in parameter definitions"
- Commit 39b5376: "add output mode parsing"
- File: `tools/dnt_preset_editor.html` (reference implementation)

**nt_helper Documentation:**
- `docs/architecture.md` - Overall architecture
- `docs/epics.md` - Epic 7 overview
- `docs/stories/7-*.md` - Individual story specifications
- `docs/parameter-flag-analysis-report.md` - Parameter flag research

**External Resources:**
- Drift migrations: https://drift.simonbinder.eu/docs/advanced-features/migrations/
- Eurorack CV/gate standards: https://www.doepfer.de/a100_man/a100t_e.htm
