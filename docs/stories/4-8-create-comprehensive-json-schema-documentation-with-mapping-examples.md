# Story 4.8: Create comprehensive JSON schema documentation with mapping examples

Status: done

## Story

As an LLM client learning the API,
I want detailed JSON schema documentation with mapping field descriptions and examples,
So that I understand how to work with CV/MIDI/i2c mappings and performance pages.

## Acceptance Criteria

1. JSON schema for all tools includes complete mapping structure documentation using snake_case
2. Mapping field descriptions explain purpose and valid ranges for each field
3. CV mapping documentation explains: `source` (algorithm output for observing other algorithm outputs - advanced usage), `cv_input` (physical CV input 0-12), `is_unipolar` (unipolar vs bipolar), `is_gate` (gate mode), `volts` (voltage scaling), `delta` (sensitivity)
4. MIDI mapping documentation explains: `midi_type` values (cc, note_momentary, note_toggle, cc_14bit_low, cc_14bit_high), `midi_channel` (0-15), `midi_cc` (0-128, 128=aftertouch), `is_midi_symmetric`, `is_midi_relative`, `midi_min`/`midi_max` (scaling range)
5. i2c mapping documentation explains: `i2c_cc` (0-255), `is_i2c_symmetric`, `i2c_min`/`i2c_max` (scaling range)
6. Performance page documentation explains: pages 1-15 for parameter grouping/organization, 0 = not assigned
7. Schema examples include: preset with MIDI mappings, slot with CV mappings, parameter with i2c mapping, parameter with performance page assignment
8. Schema examples show partial mapping updates (e.g., update only MIDI, preserve CV/i2c)
9. Schema examples show common patterns: map filter cutoff to MIDI CC, map envelope to CV input, assign multiple params to performance page, observe algorithm output as CV source
10. Helper documentation created: `docs/mcp-mapping-guide.md` explaining mapping concepts and use cases
11. Mapping guide includes troubleshooting: common validation errors, mapping conflicts, performance page best practices
12. Mapping guide explains that disabled mappings are omitted from `show` output but preserved when editing
13. Update main `CLAUDE.md` with link to mapping guide
14. `flutter analyze` passes with zero warnings

## Tasks / Subtasks

- [x] Update JSON schemas for all tools with complete mapping documentation (AC: 1-2)
  - [x] Review existing tool schemas (search, new, edit, show)
  - [x] Add mapping structure documentation to each relevant tool
  - [x] Use snake_case for all field names
  - [x] Document all optional fields clearly
  - [x] Explain purpose of each mapping field
  - [x] Document valid ranges for each field

- [x] Document CV mapping fields (AC: 3)
  - [x] `source` (int): Algorithm output index for observing other algorithm outputs (advanced usage, 0=not used)
  - [x] `cv_input` (int, 0-12): Physical CV input number (0=disabled, 1-12=inputs)
  - [x] `is_unipolar` (bool): Unipolar (0-10V) vs bipolar (-5V to +5V) mode
  - [x] `is_gate` (bool): Gate mode for trigger/gate signals
  - [x] `volts` (float): Voltage scaling factor
  - [x] `delta` (float): Sensitivity/responsiveness

- [x] Document MIDI mapping fields (AC: 4)
  - [x] `is_midi_enabled` (bool): Enable/disable MIDI control
  - [x] `midi_channel` (int, 0-15): MIDI channel number
  - [x] `midi_type` (enum): "cc", "note_momentary", "note_toggle", "cc_14bit_low", "cc_14bit_high"
  - [x] `midi_cc` (int, 0-128): MIDI CC number (128=aftertouch)
  - [x] `is_midi_symmetric` (bool): Symmetric scaling around center value
  - [x] `is_midi_relative` (bool): Relative mode for incremental changes
  - [x] `midi_min` (int): Minimum value for scaling range
  - [x] `midi_max` (int): Maximum value for scaling range

- [x] Document i2c and performance page fields (AC: 5-6)
  - [x] `is_i2c_enabled` (bool): Enable/disable i2c control
  - [x] `i2c_cc` (int, 0-255): i2c CC number
  - [x] `is_i2c_symmetric` (bool): Symmetric scaling
  - [x] `i2c_min` (int): Minimum value for scaling
  - [x] `i2c_max` (int): Maximum value for scaling
  - [x] `performance_page` (int, 0-15): Performance page assignment (0=not assigned, 1-15=page number)

- [x] Create schema examples (AC: 7-9)
  - [x] Example: Preset with MIDI mappings on multiple parameters
  - [x] Example: Slot with CV mappings on envelope parameters
  - [x] Example: Parameter with i2c mapping for external control
  - [x] Example: Parameter with performance page assignment
  - [x] Example: Partial mapping update (MIDI only, preserve CV/i2c)
  - [x] Example: Map filter cutoff to MIDI CC 74
  - [x] Example: Map envelope parameters to CV inputs
  - [x] Example: Assign multiple parameters to performance page 1
  - [x] Example: Use CV source to observe another algorithm's output

- [x] Create mapping guide document (AC: 10-12)
  - [x] Create `docs/mcp-mapping-guide.md`
  - [x] Explain CV mapping concepts and use cases
  - [x] Explain MIDI mapping concepts and use cases
  - [x] Explain i2c mapping concepts and use cases
  - [x] Explain performance page organization strategies
  - [x] Document CV source advanced usage (observing algorithm outputs)
  - [x] Troubleshooting section: common validation errors
  - [x] Troubleshooting section: mapping conflicts
  - [x] Troubleshooting section: performance page best practices
  - [x] Explain disabled mappings omitted from `show` but preserved when editing

- [x] Update project documentation (AC: 13-14)
  - [x] Add link to mapping guide in `CLAUDE.md`
  - [x] Add link to mapping guide in MCP server documentation
  - [x] Update README if needed
  - [x] Run `flutter analyze` and fix warnings

## Dev Notes

### Architecture Context

- Tool schemas: `lib/mcp/tools/algorithm_tools.dart`, `lib/mcp/tools/disting_tools.dart`
- MCP server: `lib/services/mcp_server_service.dart`
- Mapping model: `lib/models/packed_mapping_data.dart`
- Existing documentation: `assets/mcp_docs/`, `README.md`

### Mapping Concepts to Explain

**CV Mapping**:
- Physical CV inputs: Hardware control voltage inputs (1-12)
- Unipolar vs bipolar: Voltage range modes
- Gate mode: For trigger/gate signals
- CV source: Advanced feature to observe another algorithm's output (modulation routing)

**MIDI Mapping**:
- MIDI channels: 0-15 (maps to MIDI channels 1-16)
- MIDI CC: Control Change messages (0-127 standard, 128=aftertouch)
- MIDI types: CC (continuous), Note (on/off), 14-bit CC (high-res)
- Symmetric scaling: Center-based scaling for bidirectional controls
- Relative mode: Incremental changes vs absolute values

**i2c Mapping**:
- i2c control: Inter-IC communication for external modules
- i2c CC: Similar to MIDI CC but for i2c bus (0-255 range)

**Performance Pages**:
- Organization: Group related parameters for live performance
- Pages 1-15: Can assign up to 15 different pages
- Page 0: Special value meaning "not assigned"
- Use case: Quick access to frequently-adjusted parameters

### Example Documentation Structure

```markdown
## CV Mapping

### source
- **Type**: integer
- **Range**: 0 or algorithm output index
- **Purpose**: Observe another algorithm's output as modulation source (advanced)
- **Default**: 0 (not used)
- **Example**: Set to 1 to use the first output of a previous algorithm as modulation

### cv_input
- **Type**: integer
- **Range**: 0-12
- **Purpose**: Physical CV input for hardware control voltage
- **Default**: 0 (disabled)
- **Example**: Set to 1 to control parameter from CV Input 1

### is_unipolar
- **Type**: boolean
- **Purpose**: Voltage range mode
- **Values**:
  - `true`: Unipolar (0V to +10V)
  - `false`: Bipolar (-5V to +5V)
- **Default**: false
```

### Common Patterns to Document

1. **Filter Control via MIDI CC**:
   - Map cutoff frequency to MIDI CC 74
   - Enable MIDI on channel 0
   - Use full range (0-127)

2. **Envelope Control via CV Input**:
   - Map attack/decay/release to CV inputs 1-3
   - Use unipolar mode for envelope parameters
   - Adjust volts for sensitivity

3. **Performance Page Organization**:
   - Page 1: Main synthesis parameters (oscillator, filter)
   - Page 2: Modulation parameters (LFO, envelope)
   - Page 3: Effects parameters (reverb, delay)

4. **CV Source Modulation**:
   - Use LFO output (algorithm 0, output 0) as modulation source
   - Set source=0 to observe algorithm 0's first output
   - Apply to filter cutoff for sweeping effect

### Troubleshooting Examples

**"MIDI channel must be 0-15, got 16"**:
- Explanation: MIDI channels are 0-indexed (0-15 represents MIDI channels 1-16)
- Solution: Use values 0-15, not 1-16

**"CV input must be 0-12, got 13"**:
- Explanation: Disting NT has 12 CV inputs (1-12), 0=disabled
- Solution: Use values 0-12 only

**"Performance page must be 0-15, got 16"**:
- Explanation: 15 pages available (1-15), 0=not assigned
- Solution: Use values 0-15 only

**Mapping Conflicts**:
- Problem: Multiple parameters assigned to same MIDI CC
- Effect: MIDI messages control all mapped parameters simultaneously
- Solution: Use unique MIDI CCs per parameter or intentionally link related parameters

### Testing Strategy

- Review all tool schemas for completeness
- Validate all examples are syntactically correct
- Test examples with actual MCP client
- Get feedback on clarity from test users
- Ensure links work in documentation

### Project Structure Notes

- New file: `docs/mcp-mapping-guide.md`
- Update: `CLAUDE.md` (add link to mapping guide)
- Update: Tool schemas in `lib/mcp/tools/`
- Update: MCP documentation in `assets/mcp_docs/` if needed

### References

- [Source: docs/architecture.md#Critical Architecture: MCP Server]
- [Source: docs/epics.md#Story E4.8]
- [Source: lib/models/packed_mapping_data.dart - mapping structure]
- [Source: docs/manual-1.10.0.md - firmware manual]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List

**Created:**
- docs/mcp-mapping-guide.md - Complete mapping guide with field documentation, examples, troubleshooting

**Modified:**
- lib/services/mcp_server_service.dart - Enhanced tool schemas with detailed mapping field documentation
- CLAUDE.md - Added MCP API Documentation section with links to mapping guide

---

## Senior Developer Review (AI)

**Reviewer:** Neal
**Date:** 2025-11-08
**Outcome:** Approve

### Summary

Story 4.8 successfully delivers detailed JSON schema documentation for all mapping types (CV, MIDI, i2c, performance pages) with examples and troubleshooting guidance. The implementation is thorough and well-executed, meeting all 14 acceptance criteria with high quality.

Key achievements:
- Created 601-line mapping guide with detailed field documentation
- Enhanced MCP tool schemas with snake_case mapping fields
- Provided 9 common patterns and troubleshooting examples
- All tests pass, flutter analyze shows zero warnings
- Documentation properly linked from CLAUDE.md

### Key Findings

#### High Severity
None identified.

#### Medium Severity
None identified.

#### Low Severity
None identified.

### Acceptance Criteria Coverage

All 14 acceptance criteria fully satisfied:

**AC 1-2 (JSON Schema):** Tool schemas in `mcp_server_service.dart` include complete mapping structure documentation with snake_case naming (cv_input, midi_type, i2c_cc, performance_page). All fields have clear descriptions and valid ranges.

**AC 3 (CV Mapping):** Documented all CV fields including:
- `source` (algorithm output for advanced modulation)
- `cv_input` (0-12, physical CV inputs)
- `is_unipolar` (voltage range mode)
- `is_gate` (gate/trigger mode)
- `volts` (scaling factor)
- `delta` (sensitivity)

**AC 4 (MIDI Mapping):** Documented all MIDI fields including all 5 `midi_type` values (cc, note_momentary, note_toggle, cc_14bit_low, cc_14bit_high), channels (0-15), CC values (0-128 for aftertouch), symmetric/relative modes, and min/max scaling.

**AC 5-6 (i2c and Performance Pages):** Documented i2c fields (is_i2c_enabled, i2c_cc 0-255, is_i2c_symmetric, i2c_min/max) and performance pages (0=not assigned, 1-15=page numbers) with clear explanations.

**AC 7-9 (Examples):** Provided examples for:
- Preset with MIDI mappings (lines 497-541)
- Slot with CV mappings (multiple examples)
- Parameters with i2c mapping and performance pages
- Partial mapping updates (line 364-386)
- Common patterns: Filter control via MIDI CC, envelope via CV, performance page organization, CV source modulation

**AC 10-12 (Mapping Guide):** Created `/docs/mcp-mapping-guide.md` (601 lines) with:
- Complete field documentation for all mapping types
- Troubleshooting section covering common validation errors
- Mapping conflicts guidance
- Performance page best practices
- Explanation that disabled mappings are omitted from `show` but preserved when editing

**AC 13 (Documentation Links):** Successfully added link to mapping guide in CLAUDE.md (line 111).

**AC 14 (Code Quality):** `flutter analyze` passes with zero warnings confirmed.

### Test Coverage and Gaps

**Test Coverage:** Good
- Tests passing (230+ tests executed)
- MCP tool tests exist: search_tool_test, new_tool_test, edit_*_tool_test, show_tool_test
- Mapping editor tests cover autosave, 14-bit CC support, field validation

**No Gaps Identified:** Story focused on documentation rather than implementation. Existing tests cover the underlying functionality.

### Architectural Alignment

**Excellent Alignment** with Epic 4 technical context:
- Follows snake_case naming convention for all MCP API fields (decision documented in tech context)
- Mapping documentation aligns with `PackedMappingData` model structure
- Schema definitions in `mcp_server_service.dart` match dart_mcp library patterns
- Documentation correctly references disabled mapping omission from `show` output

**No architectural violations identified.**

### Security Notes

**Not Applicable:** This story is documentation-only with no security implications. The documented mapping validation rules (MIDI channel 0-15, CV input 0-12, etc.) correctly match the implemented validation in existing code.

### Best-Practices and References

**Documentation Quality:**
- Clear structure with table of contents
- Consistent formatting throughout
- Examples use valid JSON syntax
- Field descriptions include purpose, range, and explanations
- Troubleshooting section addresses common errors with solutions

**LLM-Friendly Design:**
- snake_case naming reduces cognitive load for LLMs (consistent with Epic 4 design decision)
- Detailed field descriptions enable LLMs to construct valid requests
- Examples cover simple to complex scenarios
- Troubleshooting provides actionable error messages

**References:**
- [Epic 4 Technical Context](/Users/nealsanche/nosuch/nt_helper/docs/epic-4-context.md)
- [MCP Mapping Guide](/Users/nealsanche/nosuch/nt_helper/docs/mcp-mapping-guide.md)
- [MCP Server Implementation](/Users/nealsanche/nosuch/nt_helper/lib/services/mcp_server_service.dart)

### Action Items

No action items. Story is complete and approved.
