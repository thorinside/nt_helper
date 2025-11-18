# Epic 7 Architecture Review Summary

**Date**: 2025-11-18
**Reviewer**: Winston (Architect Agent)
**Epic**: Epic 7 - SysEx Updates & I/O Metadata Infrastructure

---

## Executive Summary

Epic 7 has been **significantly expanded** from its original scope. What began as a simple UI enhancement (parameter disabled state) has evolved into a **major architectural refactor** of the routing framework.

**Original Scope (Stories 7.1-7.2)**:
- Parameter disabled/grayed-out UI state
- Auto-refresh after parameter edits

**Updated Scope (Stories 7.1-7.9)**:
- Stories 7.1-7.2: Parameter disabled state (COMPLETED)
- **Stories 7.3-7.9: NEW - Complete I/O metadata infrastructure** (READY FOR IMPLEMENTATION)

---

## Architecture Impact Analysis

### 1. Routing Framework: Pattern Matching → Hardware Metadata

**Current State (To Be Replaced)**:
```dart
// Fragile pattern matching in lib/core/routing/multi_channel_algorithm_routing.dart
final lowerName = paramName.toLowerCase();
final isOutput = lowerName.contains('output') || (lowerName.contains('out') && !lowerName.contains('input'));

String portType = 'audio';
if (lowerName.contains('cv') || lowerName.contains('gate')) {
  portType = 'cv';
}
```

**Problems**:
- ❌ Fragile: Breaks if parameter names change
- ❌ Incomplete: Can't handle non-standard naming
- ❌ Artificial: `gate`/`clock` types don't exist in hardware
- ❌ No offline support: Requires parameter names only available online

**Future State (Epic 7)**:
```dart
// Data-driven port configuration using hardware I/O flags
final isInput = parameterInfo.isInput;
final isOutput = parameterInfo.isOutput;
final isAudio = parameterInfo.isAudio;
final isOutputMode = parameterInfo.isOutputMode;

final portType = isAudio ? PortType.audio : PortType.cv;
```

**Benefits**:
- ✅ Data-driven: Hardware provides ground truth
- ✅ Complete: Works for all algorithms
- ✅ Accurate: Only two signal types (audio/CV) as hardware defines
- ✅ Offline support: Flags stored in database

---

## 2. New SysEx Protocol Extension

### I/O Flags (SysEx 0x43 Enhancement)

**Bit Layout in Parameter Info Last Byte**:
```
Bits 0-1: powerOfTen (10^n scaling, n=0-3)
Bits 2-5: ioFlags (4-bit field):
  Bit 0 (value 1): isInput
  Bit 1 (value 2): isOutput
  Bit 2 (value 4): isAudio (true) vs CV (false)
  Bit 3 (value 8): isOutputMode
```

### Output Mode Usage Query (SysEx 0x55 - NEW)

**Purpose**: Map mode control parameters to affected outputs

**Request Format**:
```
[0xF0, 0x00, 0x21, 0x27, 0x6D, sysExId, 0x55, slot, p_high, p_mid, p_low, 0xF7]
```

**Response Format**:
```
[0xF0, ..., 0x55, slot, source_param, count, affected_1, affected_2, ..., 0xF7]
```

**Replaces**: Pattern matching like `modeParameters?.containsKey('$paramName mode')`

---

## 3. Database Schema Evolution

### Schema v7 → v8 Migration

**Change**: Add `ioFlags` column to `Parameters` table

```sql
ALTER TABLE parameters ADD COLUMN io_flags INTEGER;
```

**Migration Strategy**:
- Story 7.7: Add column (nullable, defaults to null)
- Story 7.8: Generate updated metadata bundle from hardware
- Story 7.9: Populate existing databases from bundled metadata

**Upgrade Detection**:
```sql
SELECT COUNT(*) FROM parameters WHERE io_flags IS NOT NULL;
-- If count = 0 → trigger upgrade from bundled metadata
```

---

## 4. Data Model Changes

### ParameterInfo Enhancement

```dart
class ParameterInfo {
  // Existing fields...
  final int powerOfTen;

  // NEW: Epic 7
  final int ioFlags;  // 4-bit field

  // Computed properties
  bool get isInput => (ioFlags & 0x01) != 0;
  bool get isOutput => (ioFlags & 0x02) != 0;
  bool get isAudio => (ioFlags & 0x04) != 0;
  bool get isOutputMode => (ioFlags & 0x08) != 0;
}
```

### Slot Enhancement

```dart
class Slot {
  final int index;
  final Algorithm algorithm;
  final List<ParameterInfo> parameters;
  final List<int> parameterValues;
  final RoutingInfo routing;
  final String? customName;

  // NEW: Epic 7 Story 7.4
  final Map<int, OutputModeUsage>? outputModeMap;
}
```

**outputModeMap**: Maps mode control parameter numbers → list of affected output parameters

---

## 5. Implementation Sequence (Critical)

Stories **must be implemented sequentially** to avoid code conflicts:

```
7.3 (I/O Flags - Runtime)
 ├─> 7.4 (Output Mode - Runtime)
 └─> 7.7 (I/O Flags - Database)
      └─> 7.8 (Generate Bundle)
           └─> 7.9 (Upgrade Existing DBs)
                └─> 7.5 (Routing I/O Refactor)
                     └─> 7.6 (Routing Mode Refactor)
```

**Dependency Rationale**:
- 7.4 needs 7.3's `isOutputMode` flag
- 7.8 needs 7.7's export capability
- 7.9 needs 7.8's bundled data
- 7.5 needs 7.9 for offline support
- 7.6 needs 7.4's output mode data

**Code Overlap Zones**:
- Stories 7.3-7.6: All modify routing framework
- Stories 7.7-7.9: All modify database/import/export
- **Parallel work would cause merge conflicts**

---

## 6. Files Modified Across Epic 7

### Core Data Models
- `lib/domain/disting_nt_sysex.dart` - ParameterInfo class, message type enum
- `lib/models/slot.dart` - Slot model with output mode map

### SysEx Handling (Stories 7.3-7.4)
- `lib/domain/sysex/sysex_parser.dart` - Message parser
- `lib/domain/sysex/response_factory.dart` - Response dispatcher
- `lib/domain/sysex/responses/parameter_info_response.dart` - 0x43 parser (extract ioFlags)
- `lib/domain/sysex/responses/output_mode_usage_response.dart` - 0x55 parser (**NEW**)
- `lib/domain/sysex/requests/request_output_mode_usage.dart` - 0x55 request (**NEW**)

### Routing Framework (Stories 7.5-7.6)
- `lib/core/routing/algorithm_routing.dart` - Base class
- `lib/core/routing/multi_channel_algorithm_routing.dart` - **Remove pattern matching**
- `lib/core/routing/models/port.dart` - **Remove gate/clock types, keep audio/CV only**

### Database & Offline (Stories 7.7-7.9)
- `lib/db/tables.dart` - Schema definitions (**add ioFlags column**)
- `lib/db/database.dart` - Database class (**add migration v7→v8**)
- `lib/services/metadata_import_service.dart` - JSON import
- `lib/services/algorithm_json_exporter.dart` - JSON export
- `lib/services/metadata_upgrade_service.dart` - Upgrade service (**NEW**)

### MIDI Managers (All Stories)
- `lib/domain/i_disting_midi_manager.dart` - Interface (**add requestOutputModeUsage()**)
- `lib/domain/disting_midi_manager.dart` - Live hardware implementation
- `lib/domain/offline_disting_midi_manager.dart` - Database implementation
- `lib/domain/mock_disting_midi_manager.dart` - Mock data (return ioFlags=0)

### State Management (Stories 7.4, 7.5, 7.6)
- `lib/cubit/disting_cubit.dart` - Central state management
- `lib/cubit/routing_editor_cubit.dart` - Routing state orchestration

### Assets (Story 7.8)
- `assets/metadata/full_metadata.json` - Bundled metadata (**replace with v2 format**)

---

## 7. Metadata Format Evolution

### Version 1 (Current)
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

### Version 2 (Epic 7)
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

**Compatibility**:
- v2 importer handles v1 format (missing ioFlags → null)
- v1 importer ignores ioFlags field (graceful degradation)

---

## 8. Testing Strategy

### Unit Tests
- **Story 7.3**: Bit extraction, helper getters, SysEx parsing
- **Story 7.4**: Request encoding, response parsing, state updates
- **Story 7.5**: Input/output detection via flags, port type inference
- **Story 7.6**: Mode parameter identification, output mode lookup
- **Story 7.7**: Database migration, JSON import/export
- **Story 7.9**: Upgrade detection, selective updates

### Integration Tests
- **Story 7.3**: Verify I/O flags parse from live hardware
- **Story 7.4**: Verify output mode usage queries work
- **Story 7.8**: Verify metadata collection from all algorithms
- **Story 7.7**: Migration from v1 to v2 schema
- **Story 7.9**: Upgrade from old database with null flags

### End-to-End Tests
- Fresh install: Bundled metadata loaded with I/O flags
- Existing install: Database upgraded with I/O flags
- Offline mode: Routing uses I/O flags from database
- Online mode: Routing uses I/O flags from hardware

---

## 9. Success Criteria

Epic 7 is complete when:

1. ✅ I/O flags extracted from SysEx and stored in ParameterInfo
2. ✅ Output mode usage relationships queried and stored in state
3. ✅ Routing framework uses I/O flags (no pattern matching)
4. ✅ Routing framework uses output mode data (no pattern matching)
5. ✅ Database schema supports I/O flags
6. ✅ Bundled metadata includes I/O flags for all factory algorithms
7. ✅ Existing databases automatically upgraded with I/O flags
8. ✅ Offline mode has full I/O flag support
9. ✅ Port types reduced to audio/CV only (no artificial gate/clock)
10. ✅ All tests pass, zero analyzer warnings

---

## 10. Risks and Mitigations

### Risk: Sequential Implementation Bottleneck
- **Impact**: Can't parallelize work, slows development
- **Mitigation**: Stories are sized for 2-4 hour completion, rapid iteration possible
- **Status**: Accepted - dependency chain is necessary to avoid conflicts

### Risk: Database Migration Failure
- **Impact**: Users lose offline metadata
- **Mitigation**:
  - Migration is additive (adds column, doesn't modify data)
  - Story 7.9 re-imports from bundled metadata (idempotent)
  - Database backup encouraged in release notes
- **Status**: Low risk, well-tested migration pattern

### Risk: Bundled Metadata Incomplete
- **Impact**: Missing I/O flags for some algorithms in offline mode
- **Mitigation**:
  - Story 7.8 collects from all hardware algorithms
  - Validation step checks completeness
  - Missing flags fallback to safe defaults (no routing assumptions)
- **Status**: Mitigated

### Risk: Breaking Existing Routing Visualizations
- **Impact**: Routing editor shows incorrect/missing connections
- **Mitigation**:
  - Incremental refactor (7.5 then 7.6)
  - Test suite covers major routing configurations
  - Manual testing with Clock, Poly CV, Euclidean algorithms
- **Status**: Mitigated with testing

---

## 11. Future Enhancements (Beyond Epic 7)

**Not in scope for Epic 7, but enabled by this architecture**:

- Community plugin I/O flags (when hardware supports it)
- Metadata version tracking for automatic bundle updates
- Visual output mode grouping in routing editor
- i2c routing visualization using I/O metadata
- GitHub Actions workflow to regenerate metadata on firmware updates
- Automated validation of bundled metadata completeness
- Diff reports showing metadata changes between firmware versions

---

## 12. Architecture Document Updates

The following sections of `docs/architecture.md` have been updated:

1. **Change Log**: Added v1.1 entry for Epic 7 updates
2. **Routing Framework Section**:
   - Added "Epic 7: I/O Metadata Infrastructure (In Development)" subsection
   - Documented current pattern matching (to be replaced)
   - Documented future hardware I/O flags approach
   - Included implementation sequence and benefits
3. **SysEx Command System**:
   - Added documentation for SysEx 0x55 (Output Mode Usage Query)
   - Included request/response format details
4. **Database Schema**:
   - Updated schema version: "Next Version (Epic 7): 8"
   - Added `ioFlags` column documentation to Parameters table
   - Documented migration strategy (v7→v8)
5. **Data Models**:
   - Updated Slot model documentation with `outputModeMap` field
   - Documented Epic 7 additions and purpose

**Reference Document**: `docs/epic-7-context.md` contains complete technical details for implementation.

---

## 13. Recommendations

### For Immediate Implementation

1. **Start with Story 7.3** - Foundation for everything else
   - Extract I/O flags from SysEx 0x43
   - Add helper getters to ParameterInfo
   - Propagate through state management
   - Test with live hardware

2. **Follow Sequential Order** - Do NOT skip or parallelize
   - Each story builds on previous
   - Code conflicts will occur if order violated
   - Estimated 2-4 hours per story = ~14-28 hours total for Epic 7

3. **Test Incrementally** - Don't wait until end
   - Run tests after each story
   - Manual test routing editor after 7.5 and 7.6
   - Verify offline mode after 7.9

### For Architecture Alignment

1. **Port Type Simplification** - Remove artificial types
   - Hardware has only audio/CV
   - No gate/clock types needed
   - Simplifies compatibility logic

2. **Pattern Matching Removal** - Use data over heuristics
   - Trust hardware I/O flags
   - No fallback to name matching
   - Clear error if flags missing

3. **Offline Parity** - Ensure offline mode matches online
   - Bundled metadata must be complete
   - Database upgrade path well-tested
   - No feature gaps between modes

---

## Conclusion

Epic 7 represents a **significant architectural improvement** that transitions nt_helper from heuristic-based routing to data-driven, hardware-authoritative routing. The expanded scope is justified by:

1. **Firmware Evolution**: distingNT now provides I/O metadata, making pattern matching obsolete
2. **Offline Mode Gaps**: Current approach can't work offline, Epic 7 enables full parity
3. **Maintainability**: Eliminating pattern matching removes fragile code
4. **Future-Proofing**: Hardware metadata will evolve, this architecture adapts automatically

**The architecture document has been updated** to reflect these changes, providing clear guidance for implementation.

**Status**: Epic 7 Stories 7.3-7.9 are fully specified, documented, and ready for sequential implementation.

---

**Reviewed by**: Winston (Architect Agent)
**Date**: 2025-11-18
**Next Steps**: Begin implementation with Story 7.3
