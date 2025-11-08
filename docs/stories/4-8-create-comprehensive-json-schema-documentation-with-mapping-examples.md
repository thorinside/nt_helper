# Story 4.8: Create comprehensive JSON schema documentation with mapping examples

Status: drafted

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

- [ ] Update JSON schemas for all tools with complete mapping documentation (AC: 1-2)
  - [ ] Review existing tool schemas (search, new, edit, show)
  - [ ] Add mapping structure documentation to each relevant tool
  - [ ] Use snake_case for all field names
  - [ ] Document all optional fields clearly
  - [ ] Explain purpose of each mapping field
  - [ ] Document valid ranges for each field

- [ ] Document CV mapping fields (AC: 3)
  - [ ] `source` (int): Algorithm output index for observing other algorithm outputs (advanced usage, 0=not used)
  - [ ] `cv_input` (int, 0-12): Physical CV input number (0=disabled, 1-12=inputs)
  - [ ] `is_unipolar` (bool): Unipolar (0-10V) vs bipolar (-5V to +5V) mode
  - [ ] `is_gate` (bool): Gate mode for trigger/gate signals
  - [ ] `volts` (float): Voltage scaling factor
  - [ ] `delta` (float): Sensitivity/responsiveness

- [ ] Document MIDI mapping fields (AC: 4)
  - [ ] `is_midi_enabled` (bool): Enable/disable MIDI control
  - [ ] `midi_channel` (int, 0-15): MIDI channel number
  - [ ] `midi_type` (enum): "cc", "note_momentary", "note_toggle", "cc_14bit_low", "cc_14bit_high"
  - [ ] `midi_cc` (int, 0-128): MIDI CC number (128=aftertouch)
  - [ ] `is_midi_symmetric` (bool): Symmetric scaling around center value
  - [ ] `is_midi_relative` (bool): Relative mode for incremental changes
  - [ ] `midi_min` (int): Minimum value for scaling range
  - [ ] `midi_max` (int): Maximum value for scaling range

- [ ] Document i2c and performance page fields (AC: 5-6)
  - [ ] `is_i2c_enabled` (bool): Enable/disable i2c control
  - [ ] `i2c_cc` (int, 0-255): i2c CC number
  - [ ] `is_i2c_symmetric` (bool): Symmetric scaling
  - [ ] `i2c_min` (int): Minimum value for scaling
  - [ ] `i2c_max` (int): Maximum value for scaling
  - [ ] `performance_page` (int, 0-15): Performance page assignment (0=not assigned, 1-15=page number)

- [ ] Create schema examples (AC: 7-9)
  - [ ] Example: Preset with MIDI mappings on multiple parameters
  - [ ] Example: Slot with CV mappings on envelope parameters
  - [ ] Example: Parameter with i2c mapping for external control
  - [ ] Example: Parameter with performance page assignment
  - [ ] Example: Partial mapping update (MIDI only, preserve CV/i2c)
  - [ ] Example: Map filter cutoff to MIDI CC 74
  - [ ] Example: Map envelope parameters to CV inputs
  - [ ] Example: Assign multiple parameters to performance page 1
  - [ ] Example: Use CV source to observe another algorithm's output

- [ ] Create mapping guide document (AC: 10-12)
  - [ ] Create `docs/mcp-mapping-guide.md`
  - [ ] Explain CV mapping concepts and use cases
  - [ ] Explain MIDI mapping concepts and use cases
  - [ ] Explain i2c mapping concepts and use cases
  - [ ] Explain performance page organization strategies
  - [ ] Document CV source advanced usage (observing algorithm outputs)
  - [ ] Troubleshooting section: common validation errors
  - [ ] Troubleshooting section: mapping conflicts
  - [ ] Troubleshooting section: performance page best practices
  - [ ] Explain disabled mappings omitted from `show` but preserved when editing

- [ ] Update project documentation (AC: 13-14)
  - [ ] Add link to mapping guide in `CLAUDE.md`
  - [ ] Add link to mapping guide in MCP server documentation
  - [ ] Update README if needed
  - [ ] Run `flutter analyze` and fix warnings

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
