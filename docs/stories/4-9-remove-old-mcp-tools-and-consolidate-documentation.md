# Story 4.9: Remove old MCP tools and consolidate documentation

Status: ready-for-dev

## Story

As a developer maintaining clean codebase,
I want to remove all old MCP tool implementations and update documentation,
So that we have a single source of truth for the new 4-tool API.

## Acceptance Criteria

1. Remove all old tool registrations from `mcp_server_service.dart` (keep only: search, new, edit, show)
2. Remove old tool implementation files if no longer needed
3. Keep backend services that are reused by new tools (diffing logic, validation, SynchronizedState rendering, etc.)
4. Update or remove hardcoded documentation resources to reflect new tool set
5. Create new `docs/mcp-api-guide.md` documenting the 4-tool API with mapping support
6. Include workflow examples: "Creating a simple preset", "Modifying existing preset with mappings", "Exploring algorithms", "Setting up MIDI control", "Organizing with performance pages"
7. Include JSON schema reference for each tool with complete mapping field documentation
8. Include troubleshooting section for common errors (including mapping validation errors)
9. Add section on granularity: when to use preset vs slot vs parameter edits
10. Add section on mapping strategies: when to use CV vs MIDI vs i2c, performance page organization, using CV source for modulation
11. Update main `CLAUDE.md` with link to new MCP API guide
12. `flutter analyze` passes with zero warnings
13. All tests pass

## Tasks / Subtasks

- [ ] Identify old MCP tools to remove (AC: 1)
  - [ ] Review current tool registrations in `mcp_server_service.dart`
  - [ ] List all old tools (excluding search, new, edit, show)
  - [ ] Document which tools are being replaced by new 4-tool API
  - [ ] Identify any tools that might still be needed

- [ ] Remove old tool registrations (AC: 1-2)
  - [ ] Remove old tool registrations from `mcp_server_service.dart`
  - [ ] Keep only: search, new, edit, show
  - [ ] Identify old tool implementation files
  - [ ] Remove old implementation files if no longer needed
  - [ ] Search codebase for any references to removed tools

- [ ] Preserve reusable backend services (AC: 3)
  - [ ] Identify backend services used by new tools
  - [ ] Keep: DistingController, DistingControllerImpl
  - [ ] Keep: AlgorithmMetadataService
  - [ ] Keep: Validation logic
  - [ ] Keep: SynchronizedState rendering logic
  - [ ] Keep: Diff engine (from Story 4.4)
  - [ ] Remove only tool-specific implementations

- [ ] Update documentation resources (AC: 4)
  - [ ] Review `assets/mcp_docs/` directory
  - [ ] Update or remove resources for old tools
  - [ ] Keep bus-mapping, routing-concepts, etc.
  - [ ] Update usage-guide to reflect 4-tool API
  - [ ] Update README MCP section

- [ ] Create MCP API guide document (AC: 5-10)
  - [ ] Create `docs/mcp-api-guide.md`
  - [ ] Document 4-tool API overview (search, new, edit, show)
  - [ ] Include workflow examples (see subtasks below)
  - [ ] Include JSON schema reference for each tool
  - [ ] Include complete mapping field documentation
  - [ ] Include troubleshooting section
  - [ ] Add granularity section (preset vs slot vs parameter)
  - [ ] Add mapping strategies section

- [ ] Create workflow examples (AC: 6)
  - [ ] Example: "Creating a simple preset" (new tool, add algorithms)
  - [ ] Example: "Modifying existing preset with mappings" (edit tool, update mappings)
  - [ ] Example: "Exploring algorithms" (search tool, category filtering)
  - [ ] Example: "Setting up MIDI control" (edit tool, MIDI mapping)
  - [ ] Example: "Organizing with performance pages" (edit tool, performance_page assignment)
  - [ ] Include complete JSON requests and responses for each example

- [ ] Create troubleshooting section (AC: 8)
  - [ ] Common validation errors: MIDI channel out of range, CV input invalid, etc.
  - [ ] Mapping validation errors: enabled flag missing, CC out of range
  - [ ] Algorithm not found errors: fuzzy matching tips
  - [ ] Specification validation errors: required vs optional
  - [ ] Mode errors: offline/demo mode restrictions

- [ ] Create granularity section (AC: 9)
  - [ ] When to use preset-level edits: Complete restructuring, reordering algorithms, bulk changes
  - [ ] When to use slot-level edits: Change algorithm in single slot, update all parameters for one algorithm
  - [ ] When to use parameter-level edits: Quick parameter tweaks, mapping updates, individual value changes
  - [ ] Performance considerations: Smaller edits = faster, less error-prone
  - [ ] Examples for each granularity level

- [ ] Create mapping strategies section (AC: 10)
  - [ ] When to use CV mapping: Hardware control voltage inputs, modular synthesis integration
  - [ ] When to use MIDI mapping: MIDI controller integration, DAW automation
  - [ ] When to use i2c mapping: External i2c modules, ES-5 expander
  - [ ] Performance page organization: Group by function, by algorithm, or by performance context
  - [ ] Using CV source for modulation: LFO → filter cutoff, envelope → VCA
  - [ ] Best practices: Avoid conflicts, use unique CCs, organize performance pages logically

- [ ] Update main documentation and test (AC: 11-13)
  - [ ] Add link to `mcp-api-guide.md` in `CLAUDE.md`
  - [ ] Add link to `mcp-mapping-guide.md` (from Story 4.8) in `CLAUDE.md`
  - [ ] Update README MCP section with link to API guide
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Run `flutter test` and ensure all pass
  - [ ] Remove tests for deleted tools
  - [ ] Update remaining tests to reflect new API

## Dev Notes

### Architecture Context

- MCP server: `lib/services/mcp_server_service.dart` (tool registrations)
- Tool implementations: `lib/mcp/tools/algorithm_tools.dart`, `lib/mcp/tools/disting_tools.dart`
- Documentation: `assets/mcp_docs/`, `README.md`, `CLAUDE.md`
- Backend services: `lib/services/` (controller, metadata service, etc.)

### Old Tools to Remove

Review current tool registrations and identify which are being replaced. Likely candidates for removal:
- `list_algorithms` (replaced by `search` with type="algorithm")
- `get_algorithm_details` (replaced by `search` with exact match)
- `get_current_preset` (replaced by `show` with target="preset")
- `add_algorithm` (replaced by `new` or `edit`)
- `remove_algorithm` (replaced by `edit`)
- `set_parameter_value` (replaced by `edit` with target="parameter")
- `get_parameter_value` (replaced by `show` with target="parameter")
- `move_algorithm_up/down` (replaced by `edit` with slot reordering)
- `set_preset_name` (replaced by `edit` with preset name)
- `get_preset_name` (replaced by `show` with target="preset")
- `new_preset` (replaced by `new`)
- `save_preset` (auto-save in new tools)
- `get_module_screenshot` (replaced by `show` with target="screen")
- `build_preset_from_json` (replaced by `new` or `edit`)

May keep temporarily:
- `get_cpu_usage` (not replaced by 4-tool API, still useful)
- `get_routing` (replaced by `show` with target="routing" in Story 4.7)

### Backend Services to Preserve

- `DistingController` interface
- `DistingControllerImpl` implementation
- `AlgorithmMetadataService`
- Diff engine (from Story 4.4)
- Validation logic (from Stories 4.4-4.6)
- SynchronizedState rendering
- Routing state access

### MCP API Guide Structure

```markdown
# MCP API Guide

## Overview
- 4-tool API design philosophy
- Benefits over previous 20+ tool approach
- Connection setup

## Core Tools

### search
- Purpose and use cases
- Parameters and schema
- Examples: search by name, category, GUID
- Fuzzy matching behavior

### new
- Purpose and use cases
- Parameters and schema
- Examples: blank preset, preset with algorithms
- Specification handling

### edit
- Purpose and use cases
- Three granularity levels: preset, slot, parameter
- Parameters and schema for each level
- Mapping support
- Examples for each granularity

### show
- Purpose and use cases
- Five target types: preset, slot, parameter, screen, routing
- Parameters and schema for each target
- Mapping inclusion rules
- Examples for each target

## Workflow Examples
- Creating a simple preset
- Modifying existing preset with mappings
- Exploring algorithms
- Setting up MIDI control
- Organizing with performance pages

## Granularity Guide
- When to use preset-level edits
- When to use slot-level edits
- When to use parameter-level edits
- Performance considerations

## Mapping Strategies
- CV mapping use cases
- MIDI mapping use cases
- i2c mapping use cases
- Performance page organization
- CV source for modulation
- Best practices

## Troubleshooting
- Common validation errors
- Mapping validation errors
- Algorithm lookup issues
- Specification errors
- Mode restrictions

## JSON Schema Reference
- Complete schemas for all tools
- Mapping field documentation
- Examples for each schema

## Migration from Old API
- Tool mapping: old tool → new equivalent
- Breaking changes
- Migration strategies
```

### Workflow Example Format

Each workflow example should include:
1. Goal: What we're trying to accomplish
2. Prerequisites: Starting state
3. Steps: Sequence of MCP tool calls with complete JSON
4. Verification: How to check it worked (show tool)
5. Notes: Tips, common mistakes, variations

Example:
```markdown
## Workflow: Setting up MIDI Control

**Goal**: Map filter cutoff parameter to MIDI CC 74 on channel 1

**Prerequisites**: Preset with filter algorithm in slot 0

**Steps**:

1. Inspect current state:
```json
{
  "tool": "show",
  "arguments": {
    "target": "parameter",
    "identifier": "0:5"
  }
}
```

2. Update MIDI mapping:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Cutoff Frequency",
    "mapping": {
      "midi": {
        "is_midi_enabled": true,
        "midi_channel": 0,
        "midi_type": "cc",
        "midi_cc": 74
      }
    }
  }
}
```

3. Verify:
```json
{
  "tool": "show",
  "arguments": {
    "target": "parameter",
    "identifier": "0:5"
  }
}
```

**Notes**:
- MIDI channels are 0-indexed (0 = MIDI channel 1)
- CC 74 is commonly used for filter cutoff
- Mapping preserves current parameter value
```

### Testing Strategy

- Verify all old tool references removed
- Verify new tools work as documented
- Test all workflow examples
- Verify links in documentation work
- Check for broken tests
- Run full test suite

### Project Structure Notes

- New file: `docs/mcp-api-guide.md`
- Update: `CLAUDE.md` (add links)
- Update: `README.md` (MCP section)
- Update: `assets/mcp_docs/usage-guide.md` or remove
- Clean up: `lib/mcp/tools/` (remove old implementations)
- Clean up: `test/mcp/tools/` (remove old tests)

### References

- [Source: docs/architecture.md#Critical Architecture: MCP Server]
- [Source: docs/epics.md#Story E4.9]
- [Source: README.md - MCP tool reference documentation]
- [Source: assets/mcp_docs/]

## Dev Agent Record

### Context Reference

- `docs/stories/4-9-remove-old-mcp-tools-and-consolidate-documentation.context.xml`

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
