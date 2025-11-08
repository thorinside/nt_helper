# Story 4-11: Improve MCP Tool Usability

## Story
As a user interacting with the Disting NT through MCP tools, I want improved error messages, routing helpers, and workflow simplifications so that I can create and configure presets more efficiently without needing to memorize bus numbers or deal with cryptic errors.

## Context
During the creation of an East Coast synthesis preset, several friction points were identified:
- Complex parameter editing with unclear error messages
- Routing configuration requires memorizing bus numbers
- Preset naming doesn't work properly
- No templates for common synthesis patterns
- Limited feedback on configuration

## Acceptance Criteria

### AC1: Enhanced Error Messages
- [x] Parameter validation errors include valid range information
- [x] Error messages include algorithm name for context
- [x] Error messages show attempted value vs valid values
- [ ] Test coverage for error message formatting

### AC2: Bus Number Mapping Helper
- [x] Create BusMapping class with semantic names
- [x] Support bus number to name conversion (13 → "Output 1")
- [x] Support name to bus number conversion ("Aux 1" → 21)
- [ ] Integrate into show/edit tool responses
- [ ] Test coverage for all bus mappings

### AC3: Fix Preset Naming
- [x] Preset name updates work correctly via edit tool
- [x] Name-only updates don't cause errors
- [x] Preset name persists after configuration
- [ ] Test coverage for preset naming scenarios

### AC4: Routing Helpers in Edit Tool
- [ ] Support parameter names instead of numbers ("Main output" vs 19)
- [ ] Support routing aliases ("Aux 1" instead of 21)
- [ ] Backward compatibility with existing number-based approach
- [ ] Clear error messages for invalid parameter names
- [ ] Test coverage for routing helpers

### AC5: Visual Routing in Show Command
- [ ] Add "routing_diagram" option to show tool
- [ ] Generate ASCII art representation of signal flow
- [ ] Show connections between algorithms
- [ ] Include bus names in diagram
- [ ] Test coverage for routing diagram generation

### AC6: Preset Template System
- [ ] Define template structure and storage
- [ ] Create common synthesis templates:
  - East Coast (VCO→VCF→VCA→ENV)
  - West Coast (Complex Osc→LPG→Function)
  - Drum Voice (Osc→Filter→ENV→Mix)
  - Effects Chain (In→Delay→Reverb→Out)
- [ ] Extend 'new' tool to support templates
- [ ] Template validation and error handling
- [ ] Test coverage for template system

### AC7: High-Level Workflow Tools
- [ ] Create 'quick_patch' tool for one-step preset creation
- [ ] Create 'connect' tool for semantic routing
- [ ] Create 'modulate' tool for modulation routing
- [ ] Documentation for new workflow tools
- [ ] Test coverage for workflow tools

## Technical Approach
1. Start with quick wins (AC1-3) for immediate improvements
2. Add routing infrastructure (AC4-5)
3. Implement template system (AC6)
4. Build high-level tools on top (AC7)

## Definition of Done
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] Flutter analyze shows no issues
- [ ] Documentation updated
- [ ] Changes tested with actual MCP client interaction

## Notes
Priority order based on implementation effort and user impact:
1. Bus mapping and error messages (Quick wins)
2. Fix preset naming
3. Routing helpers
4. Templates and workflow tools