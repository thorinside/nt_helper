# Epic 4: MCP Library Replacement & Simplified Preset Creation API - Technical Context

**Generated:** 2025-11-07
**Epic:** 4 (MCP Library Replacement)
**Status:** Ready for Story Development
**Story Count:** 10 stories (E4.1 through E4.10)

---

## Epic Overview

**Goal:** Replace the current MCP implementation with the official `dart_mcp` library and redesign the MCP tool interface around four intuitive operations: search, new, edit, and show.

**Value:** The current 20+ tool fragmented API forces LLMs to navigate complex tool selection. Four core tools (search/new/edit/show) with flexible granularity reduce cognitive load, enable smaller models to succeed, and map to familiar CRUD patterns. Backend diffing means LLMs declare desired state rather than orchestrating low-level operations. Full mapping support enables CV/MIDI/i2c configuration without understanding NT's packed binary format.

**Key Design Principles:**
1. **Familiar Verbs** - search/new/edit/show map to CLI/database patterns LLMs already understand
2. **Flexible Granularity** - Single edit tool supports preset, slot, and parameter-level operations
3. **Backend Diffing** - LLMs send desired state, backend calculates minimal changes
4. **Full Mapping Support** - CV/MIDI/i2c/performance pages fully exposed with snake_case naming
5. **HTTP Transport** - Standard HTTP on port 3000, no stdio configuration friction

---

## Current State Analysis

### Existing MCP Infrastructure

**Current Library:** Custom MCP implementation (to be replaced)

**Key Files:**
- `lib/services/mcp_server_service.dart` - MCP server (170 lines, HTTP-based with multi-client support)
- `lib/services/disting_controller.dart` - Abstract interface for MCP tools (250 lines)
- `lib/services/disting_controller_impl.dart` - Implementation (600+ lines)
- `lib/mcp/tools/algorithm_tools.dart` - Algorithm-related MCP tools
- `lib/mcp/tools/disting_tools.dart` - Device control MCP tools

**Current Tool Count:** 20+ specialized tools including:
- `get_all_algorithms`, `search_algorithms`, `get_algorithm_by_guid`
- `create_preset`, `load_preset`, `save_preset`
- `add_algorithm`, `remove_algorithm`, `move_algorithm`
- `get_parameter_info`, `set_parameter_value`
- `get_screen_state`, `get_routing`
- And many more...

**Current Transport:** HTTP-based on port 3000 with `/mcp` endpoint

**Connection Modes:**
- Demo (Mock) - Simulated data, no hardware
- Offline - Cached algorithm data
- Connected - Live MIDI communication with Disting NT

### State Management Architecture

**DistingCubit** (`lib/cubit/disting_cubit.dart`) - Central state management (1000+ lines)
- Manages all device state via `IDistingMidiManager` hierarchy
- Exposes synchronized `Slot` objects with algorithms, parameters, and values
- Handles preset operations (new, load, save)
- Manages algorithm operations (add, remove, move)
- Controls parameter updates and mappings

**SynchronizedState** - Current device state representation
- Complete preset with all slots (0-31)
- Each slot: algorithm + parameters + values + mappings
- Mappings include: CV, MIDI, i2c, performance pages

**Key Services:**
- `AlgorithmMetadataService` - Algorithm discovery and metadata
- `MetadataSyncService` - Sync algorithm data from hardware/API
- `RoutingEditorCubit` - Routing visualization state

### Mapping System

**PackedMappingData** (`lib/models/packed_mapping_data.dart`)
- Handles NT hardware's packed binary format for parameter mappings
- Supports CV, MIDI, i2c, and performance page assignments
- Current field names use camelCase

**Mapping Types:**
1. **CV Mapping** - Physical CV inputs (0-12), modulation source, unipolar/bipolar, gate mode
2. **MIDI Mapping** - MIDI channel (0-15), CC (0-128), type (CC/note/14-bit), relative, symmetric
3. **i2c Mapping** - i2c CC (0-255), symmetric, min/max scaling
4. **Performance Pages** - Page assignment (0-15) for parameter grouping

### Database Layer

**Drift ORM** (`lib/db/database.dart`)
- Schema version 7
- Tables: presets, algorithms, parameters, mappings
- DAOs: `MetadataDao`, `PresetsDao`

---

## dart_mcp Library Research

**Package:** `dart_mcp` from `https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp`

**Key Features:**
- Official Dart/Flutter MCP implementation from Google
- Supports HTTP streaming transport (our target)
- Standard MCP protocol compliance
- Example servers available in repo

**Integration Points:**
1. Replace custom MCP server initialization with `dart_mcp` HTTP server
2. Migrate tool registration to `dart_mcp` API
3. Update tool schemas to use `dart_mcp` JSON schema format
4. Preserve existing backend controller interface (`DistingController`)

**Example Server Pattern** (from dart_mcp examples):
```dart
// Initialize HTTP server with dart_mcp
final server = McpServer(
  name: 'nt_helper',
  version: '1.0.0',
  capabilities: ServerCapabilities(
    tools: ToolsCapability(),
  ),
);

// Register tools
server.addTool(
  Tool(
    name: 'search',
    description: 'Search for algorithms...',
    inputSchema: {...},
  ),
  handler: (arguments) async {
    // Tool implementation
  },
);

// Start HTTP server on port 3000
await server.listen(port: 3000, path: '/mcp');
```

---

## New API Design

### Four Core Tools

**1. search** - Algorithm discovery
- Input: `type` (required: "algorithm"), `query` (string)
- Output: Array of matching algorithms with guid, name, category, description
- Fuzzy matching (≥70% similarity) or exact GUID
- Category filtering
- Top 10 results sorted by relevance

**2. new** - Preset initialization
- Input: `name` (string), `algorithms` (optional array)
- Output: Created preset state with all slots and mappings
- Creates blank preset OR preset with initial algorithms
- Algorithms specified by GUID or name (fuzzy matching)
- Supports specifications for algorithm creation
- All mappings disabled by default (CV/MIDI/i2c enabled=false, performance_page=0)

**3. edit** - State modification (3 granularity levels)
- **Preset-level**: `target: "preset"`, `data: { name, slots: [...] }`
  - Backend diff engine calculates: add/remove/move algorithms, change parameters, update mappings
  - Validates all changes before applying (fail fast)
  - Auto-saves preset after successful application

- **Slot-level**: `target: "slot"`, `slot_index: N`, `data: { algorithm, name, parameters: [...] }`
  - Updates single slot without affecting others
  - Partial mapping updates supported

- **Parameter-level**: `target: "parameter"`, `slot_index: N`, `parameter: "name"|N`, `value: N`, `mapping: {...}`
  - Quick parameter tweaks by name or number
  - Partial mapping updates (e.g., update only MIDI, preserve CV/i2c)

**4. show** - State inspection (5 target types)
- **Preset**: `target: "preset"` - Complete preset with all slots, parameters, mappings
- **Slot**: `target: "slot"`, `identifier: N` - Single slot with all parameters and mappings
- **Parameter**: `target: "parameter"`, `identifier: "slot:param"` - Single parameter with mapping
- **Screen**: `target: "screen"` - Current device screen as base64 JPEG
- **Routing**: `target: "routing"` - Routing state with physical names (Input N, Output N)

### Mapping Representation

**Format:** JSON with snake_case field names (LLM-friendly)

**CV Mapping Structure:**
```json
{
  "cv": {
    "source": 0,              // Algorithm output for modulation (advanced)
    "cv_input": 3,            // Physical CV input (0-12)
    "is_unipolar": false,     // Unipolar vs bipolar
    "is_gate": false,         // Gate mode
    "volts": 10.0,            // Voltage scaling
    "delta": 0.5              // Sensitivity
  }
}
```

**MIDI Mapping Structure:**
```json
{
  "midi": {
    "is_midi_enabled": true,
    "midi_channel": 0,        // 0-15
    "midi_type": "cc",        // "cc"|"note_momentary"|"note_toggle"|"cc_14bit_low"|"cc_14bit_high"
    "midi_cc": 74,            // 0-128 (128=aftertouch)
    "is_midi_symmetric": false,
    "is_midi_relative": false,
    "midi_min": 0,            // Scaling range
    "midi_max": 127
  }
}
```

**i2c Mapping Structure:**
```json
{
  "i2c": {
    "is_i2c_enabled": true,
    "i2c_cc": 100,            // 0-255
    "is_i2c_symmetric": false,
    "i2c_min": 0,             // Scaling range
    "i2c_max": 255
  }
}
```

**Performance Page:**
```json
{
  "performance_page": 5      // 1-15 (0 = not assigned)
}
```

**Mapping Inclusion Rules:**
- Disabled mappings omitted from `show` output
- CV mapping included if: `cv_input > 0` OR `source > 0`
- MIDI mapping included if: `is_midi_enabled == true`
- i2c mapping included if: `is_i2c_enabled == true`
- Performance page included if: `performance_page > 0`

**Partial Update Support:**
- When mapping omitted from parameter JSON, existing mapping preserved
- When mapping included, only specified types updated (others preserved)
- Example: `{ "midi": {...} }` updates only MIDI, preserves CV/i2c/performance_page

---

## Backend Diff Engine Design

**Purpose:** Hide NT hardware complexities from LLM clients

**Input:** Desired preset state (JSON from LLM)
**Output:** Sequence of NT hardware operations

**Diff Operations:**
1. **Add Algorithm** - New slot with algorithm not in current state
2. **Remove Algorithm** - Slot exists in current but not in desired
3. **Move Algorithm** - Slot reordering (complex NT operation)
4. **Change Parameter** - Parameter value differs
5. **Update Mapping** - Mapping differs or newly enabled/disabled

**Validation Rules:**
- Slot index range: 0-31
- Algorithm exists and specifications valid
- Parameter values within min/max range
- MIDI channel: 0-15
- MIDI CC: 0-128 (128=aftertouch)
- MIDI type: valid enum value
- CV input: 0-12
- i2c CC: 0-255
- Performance page: 0-15

**Error Handling:**
- Fail fast on first validation error
- No partial changes applied
- Clear error messages with actionable guidance

**Auto-save:**
- Successful edits trigger automatic preset save
- Keeps hardware in sync with LLM's mental model

---

## Implementation Roadmap

### Story E4.1: dart_mcp Foundation
**Focus:** Library migration and HTTP transport
**Key Tasks:**
- Add `dart_mcp` dependency
- Remove old MCP library
- Initialize HTTP server on port 3000
- Configure streamable HTTP transport
- Verify MCP handshake works

### Story E4.2: search Tool
**Focus:** Algorithm discovery
**Key Tasks:**
- Fuzzy matching (≥70% similarity)
- Exact GUID lookup
- Category filtering
- Return top 10 sorted by relevance
- Works in all connection modes

### Story E4.3: new Tool
**Focus:** Preset initialization
**Key Tasks:**
- Blank preset creation
- Preset with initial algorithms
- Algorithm identification (GUID or fuzzy name)
- Specification support
- Default mappings (all disabled)

### Story E4.4: edit Tool - Preset Level
**Focus:** Complete preset modification with diffing
**Key Tasks:**
- Preset JSON structure with mappings
- Backend diff engine (add/remove/move/change/update)
- Validation (all mapping fields)
- Auto-save after success
- snake_case field names

### Story E4.5: edit Tool - Slot Level
**Focus:** Single slot modification
**Key Tasks:**
- Slot JSON structure with mappings
- Partial mapping updates
- Slot name updates
- Algorithm change handling
- Validation

### Story E4.6: edit Tool - Parameter Level
**Focus:** Quick parameter tweaks
**Key Tasks:**
- Parameter identification (name or number)
- Value and/or mapping updates
- Partial mapping updates
- Strict validation
- Disabled mappings omitted from response

### Story E4.7: show Tool
**Focus:** State inspection
**Key Tasks:**
- Preset target with all mappings
- Slot target with enabled mappings
- Parameter target with mapping
- Screen target (base64 JPEG)
- Routing target (physical names)
- Disabled mappings omitted

### Story E4.8: JSON Schema Documentation
**Focus:** Mapping field documentation
**Key Tasks:**
- Complete mapping structure docs
- Field descriptions with ranges
- snake_case naming throughout
- Examples for all mapping types
- Partial update examples
- Create `docs/mcp-mapping-guide.md`

### Story E4.9: Cleanup and Consolidation
**Focus:** Remove old tools
**Key Tasks:**
- Remove old tool registrations
- Keep reused backend services
- Create `docs/mcp-api-guide.md`
- Workflow examples
- Update main `CLAUDE.md`

### Story E4.10: LLM Usability Testing
**Focus:** Validate "foolproof" goal
**Key Tasks:**
- Test with smaller LLM (GPT-OSS-20B)
- 12 test scenarios covering all operations
- Measure success rate (>80% simple, >60% complex, >50% mapping)
- Identify and fix top 3 usability issues
- Special focus on mapping usability
- Document findings

---

## Key Technical Decisions

### snake_case vs camelCase for JSON Fields
**Decision:** Use snake_case for all MCP API JSON fields

**Rationale:**
1. LLMs trained on more snake_case data (Python, SQL, CLI tools)
2. Easier to read: `midi_channel` vs `midiChannel`
3. Reduces cognitive load for parsing field names
4. Common in REST APIs and database schemas

**Impact:**
- Internal `PackedMappingData` uses camelCase (Dart convention)
- MCP API layer translates to snake_case
- All JSON schema examples use snake_case

### Partial Mapping Updates
**Decision:** Support partial mapping updates at all granularity levels

**Rationale:**
1. LLMs can update just MIDI without knowing CV/i2c state
2. Reduces payload size and complexity
3. Prevents accidental mapping overwrites
4. More intuitive: "change only what you specify"

**Implementation:**
- When mapping object included: update only specified types
- When mapping object omitted: preserve all existing mappings
- Empty mapping object `{}`: valid, preserves all

### Disabled Mappings Omitted from show Output
**Decision:** Only include mapping object if at least one type is enabled

**Rationale:**
1. Reduces output noise for LLMs
2. Clear signal: "this parameter has active mappings"
3. Saves tokens in LLM context
4. Still preserves disabled mappings internally (just not shown)

**Impact:**
- `show` returns sparse mapping data
- LLMs don't need to filter enabled vs disabled
- Editing still preserves hidden disabled mappings

---

## Testing Strategy

### Unit Tests
- Tool input validation
- Diff engine logic (add/remove/move/change/update)
- Mapping validation (all fields, all types)
- snake_case translation
- Partial update merging

### Integration Tests
- End-to-end preset creation workflow
- Multi-step edit operations
- Mapping CRUD operations
- Error handling and rollback behavior

### LLM Usability Tests (Story E4.10)
- Small model success rate measurement
- Failure mode analysis
- Iterative improvements based on findings

### Manual Testing
- Test with actual NT hardware
- Verify mapping behavior
- Screen capture and routing display
- Cross-platform compatibility (all MCP clients)

---

## Risk Mitigation

**Risk 1: dart_mcp API Changes**
- Mitigation: Pin to stable version, study examples thoroughly
- Fallback: Keep old MCP server as reference during migration

**Risk 2: Diff Engine Complexity**
- Mitigation: Incremental implementation (add/remove first, then move)
- Extensive unit tests for edge cases

**Risk 3: Mapping Translation Bugs**
- Mitigation: Comprehensive validation tests
- Round-trip tests (set → get → verify)

**Risk 4: LLM Usability Issues**
- Mitigation: Story E4.10 dedicated to testing and iteration
- Collect actual failure modes and fix root causes

**Risk 5: Performance with Large Presets**
- Mitigation: Diff engine optimized for minimal operations
- Backend handles complexity, not LLM

---

## Success Criteria

1. ✅ dart_mcp library integrated and working
2. ✅ Four tools (search/new/edit/show) fully functional
3. ✅ Full mapping support with snake_case naming
4. ✅ Backend diff engine calculates minimal changes
5. ✅ JSON schema documentation complete
6. ✅ Old tools removed, documentation consolidated
7. ✅ LLM usability >80% for simple operations
8. ✅ All tests pass
9. ✅ `flutter analyze` passes with zero warnings
10. ✅ No regressions in existing functionality

---

## References

**Existing Code:**
- `lib/services/mcp_server_service.dart` - Current MCP server
- `lib/services/disting_controller.dart` - Controller interface
- `lib/cubit/disting_cubit.dart` - State management
- `lib/models/packed_mapping_data.dart` - Mapping model

**External Resources:**
- dart_mcp: `https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp`
- dart_mcp examples: `https://github.com/dart-lang/ai/tree/main/pkgs/dart_mcp/example`
- MCP protocol spec: Model Context Protocol documentation

**Documentation:**
- Epic spec: `docs/epics.md` (Epic 4 section)
- Architecture: `docs/architecture.md` (MCP Server Integration section)
- Workflow status: `docs/bmm-workflow-status.md`

---

## Notes for Story Development

**Story Creation Workflow:**
- Use `/bmad:bmm:workflows:create-story` workflow
- Reference this context document for technical details
- Each story should be self-contained and vertically sliced
- Target 2-4 hour completion time per story
- All stories depend on previous stories (sequential)

**Code Quality Standards:**
- Zero `flutter analyze` warnings
- All tests must pass
- No debug logging added
- snake_case for all MCP API JSON fields
- Clear error messages with actionable guidance

**Dependencies:**
- Stories E4.1-E4.3 are foundation (must complete first)
- Stories E4.4-E4.6 build edit tool incrementally
- Story E4.7 (show) can overlap with E4.4-E4.6
- Story E4.8 (docs) depends on E4.7
- Story E4.9 (cleanup) depends on E4.8
- Story E4.10 (testing) is final validation

---

## Post-Review Follow-ups

**Story 4.10 Review Action Items** (2025-11-08):

1. **[High] Conduct Actual LLM Testing** - Story 4.10 prepared testing infrastructure but deferred actual LLM testing. Either execute testing with Ollama using test_harness_llm_usability.py, or create follow-up story for empirical validation (AC #3, #7, #8 not met).

2. **[High] Clarify Documentation Claims** - Update docs/mcp-api-guide.md Testing section to distinguish baseline projections (84%/60%/51%) from measured results to avoid misleading users (lines 1435-1440).

3. **[Medium] Enhance Error Messages** - Add concrete examples to validation error messages for CV input, MIDI channel, and mapping fields in lib/mcp/tools/disting_tools.dart to improve LLM understanding.

4. **[Medium] Validate Test Harness** - Run test_harness_llm_usability.py against localhost:3000 to verify integration works, or document known limitations.

5. **[Low] Relocate Test Harness** - Move test_harness_llm_usability.py from project root to test/integration/ or test/tools/ for consistency with project structure.

6. **[Low] Add Error Recovery Scenarios** - Extend llm-usability-test-plan.md with scenarios covering network failures, partial errors, and retry logic for more complete test coverage.
