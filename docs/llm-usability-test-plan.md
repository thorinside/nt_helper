# LLM Usability Test Plan - Story 4.10

## Overview

This document outlines the testing plan for validating the 4-tool MCP API with a smaller language model (Ollama's local instance at http://dionysus:11434). The goal is to measure usability and identify improvements needed to achieve the "foolproof" objective.

## Test Environment Setup

### MCP Server Configuration
- **Application**: nt_helper (Flutter)
- **Server**: McpServerService with HTTP transport
- **Port**: 3000 (standard MCP HTTP endpoint)
- **Transport**: HTTP/JSON

### Smaller LLM Configuration
- **Model**: Ollama (Local instance)
- **Endpoint**: http://dionysus:11434
- **Model**: llama2-7b or similar (configurable)
- **Test Duration**: 2-3 hours per full test run
- **Temperature**: 0.7 (default, for consistent but creative responses)

### Prerequisites
1. MCP server running on localhost:3000
2. nt_helper app in connected or demo mode
3. Ollama running on dionysus:11434 with suitable model loaded
4. Test harness script or manual testing capability
5. Recording mechanism for tool calls and responses

## Test Scenarios (12 Total)

### Simple Operations (6 scenarios)
Target: >80% success rate

**Scenario 1: Search Algorithm by Name**
- Goal: Find a common algorithm (e.g., "filter")
- Tool: search
- Expected: Tool returns list of filter algorithms
- Success criteria: Correct tool selected, valid JSON parameters, successful response

**Scenario 2: Search Algorithm by Category**
- Goal: Find all algorithms in a category (e.g., "Audio-IO")
- Tool: search
- Expected: All algorithms in category returned
- Success criteria: Correct tool selected, valid JSON parameters, successful response

**Scenario 3: Create Blank Preset**
- Goal: Create new empty preset
- Tool: new
- Parameters: name only (no algorithms)
- Expected: Empty preset created
- Success criteria: Correct tool selected, valid JSON, response includes new preset

**Scenario 4: Create Preset with Single Algorithm**
- Goal: Create preset with one algorithm (e.g., "Filter")
- Tool: new
- Parameters: name + algorithms array with 1 item
- Expected: Preset created with algorithm in slot 0
- Success criteria: Correct tool selected, valid JSON, algorithm properly added

**Scenario 6: Modify Parameter Value**
- Goal: Change a parameter value on existing algorithm
- Tool: edit with target="parameter"
- Parameters: slot_index, parameter name, value
- Expected: Parameter value updated
- Success criteria: Correct tool selected, valid JSON, value changed

**Scenario 10: Inspect Preset State**
- Goal: View current preset configuration
- Tool: show with target="preset"
- Expected: Complete preset structure returned
- Success criteria: Correct tool selected, valid JSON, shows all slots and parameters

### Complex Operations (2 scenarios)
Target: >60% success rate

**Scenario 5: Create Preset with 3 Algorithms**
- Goal: Create preset with multiple algorithms
- Tool: new or edit
- Parameters: name + algorithms array with 3 items
- Expected: Preset created with 3 algorithms
- Complexity: Multi-item array handling, correct ordering
- Success criteria: Correct tool selected, valid JSON, all 3 algorithms added in order

**Scenario 11: Handle Validation Error**
- Goal: Attempt invalid operation and handle error gracefully
- Tool: edit
- Parameters: Invalid MIDI channel (16 instead of 0-15)
- Expected: Validation error returned
- Complexity: Understanding error messages, error recovery
- Success criteria: Correct tool selected, error message understood, can recover

### Mapping Operations (4 scenarios)
Target: >50% success rate

**Scenario 7: Add MIDI Mapping**
- Goal: Add MIDI control to parameter
- Tool: edit with target="parameter"
- Parameters: slot_index, parameter, mapping with MIDI fields
- Expected: Parameter mapped to MIDI control
- Complexity: Multiple nested mapping fields, required flag (is_midi_enabled)
- Success criteria: Correct tool selected, valid JSON mapping structure, mapping applied

**Scenario 8: Add CV Mapping**
- Goal: Add CV input control to parameter
- Tool: edit with target="parameter"
- Parameters: slot_index, parameter, mapping with CV fields
- Expected: Parameter mapped to CV input
- Complexity: CV-specific fields (source, cv_input, volts, delta)
- Success criteria: Correct tool selected, valid JSON mapping structure, mapping applied

**Scenario 9: Assign to Performance Page**
- Goal: Organize parameter on performance page
- Tool: edit with target="parameter"
- Parameters: slot_index, parameter, mapping with performance_page
- Expected: Parameter assigned to page
- Complexity: Understanding performance page concept, integer range validation
- Success criteria: Correct tool selected, valid JSON, parameter organized

**Scenario 12: Partial MIDI Update**
- Goal: Update only MIDI mapping without changing value
- Tool: edit with target="parameter"
- Parameters: slot_index, parameter, mapping (no value field)
- Expected: Only mapping updated, value preserved
- Complexity: Understanding partial updates, mapping-only edits
- Success criteria: Correct tool selected, valid JSON, mapping updated without affecting value

## Success Criteria Definition

A scenario is **successful** if ALL of the following are true:
1. LLM selects the correct MCP tool (search, new, edit, or show)
2. LLM provides valid JSON parameters matching the tool's schema
3. Tool executes without validation error
4. LLM can verify the result (with show tool if needed)
5. No human intervention required during the scenario

A scenario **fails** if ANY of the following occur:
- Wrong tool selected (e.g., new instead of edit for modification)
- Invalid JSON (syntax error or schema violation)
- Validation error from tool (e.g., MIDI channel 16 when max is 15)
- LLM cannot complete task or needs guidance
- Timeout or tool unresponsiveness

## Failure Mode Categories

### Tool Selection Errors
- Using `new` instead of `edit` for modifications
- Using `edit` with wrong target (preset vs slot vs parameter)
- Using `show` when `edit` is needed
- Choosing wrong granularity level

### Schema Misunderstandings
- Missing required fields (e.g., is_midi_enabled in MIDI mapping)
- Wrong parameter types (string instead of integer)
- Incorrect array/object structure (flat vs nested)
- Invalid enum values

### Validation Errors
- MIDI channel 16 (should be 0-15)
- CV input 13 (should be 0-12)
- Performance page 16 (should be 0-15)
- Missing is_midi_enabled flag
- Invalid MIDI CC (should be 0-127)

### Mapping Field Confusion
- Using camelCase instead of snake_case (e.g., midiChannel vs midi_channel)
- Confusing cv_input with source field
- Confusing MIDI channel 0-15 with 1-16
- Not understanding partial updates
- Missing nested field structure

### snake_case vs camelCase Issues
- LLM consistently uses camelCase despite documentation
- LLM mixes snake_case and camelCase in single request
- Error messages suggest camelCase was attempted

## Testing Procedure

### Pre-Test Setup
1. Ensure MCP server is running on localhost:3000
2. Verify LLM endpoint is reachable (http://dionysus:11434)
3. Create clean test preset or reset to known state
4. Prepare test results spreadsheet

### Testing Round Execution
1. For each scenario:
   - Present goal to LLM
   - Record LLM's tool selection
   - Record LLM's parameters (JSON)
   - Execute tool and record response
   - Note: success/failure and failure mode
   - If mapping test: verify field names are snake_case
   - Record time to completion (optional metric)

2. After all 12 scenarios:
   - Calculate success rates:
     - Simple: successes / 6
     - Complex: successes / 2
     - Mapping: successes / 4
     - Overall: successes / 12
   - Identify failure mode patterns
   - Document top 3 issues by frequency and impact

### Post-Test Analysis
1. Review all failures
2. Group by failure mode category
3. Identify which issues appear most frequently
4. Estimate impact of each issue on user experience
5. Select top 3 issues to address

## Expected Outcome Metrics

### Baseline Success Rates (Initial Testing)
- Simple operations: Expected 80-90%
- Complex operations: Expected 50-70%
- Mapping operations: Expected 30-60%

### After Improvements
- Simple operations: Target >80% (should improve to 90%+)
- Complex operations: Target >60% (should improve to 70%+)
- Mapping operations: Target >50% (most likely to improve significantly)

### Key Measurement: Improvement Delta
- Document before/after for each category
- Identify which improvements had most impact
- Validate that targeted fixes actually help

## Common Improvements to Consider

### If Tool Selection Errors Common
- **Action**: Improve tool descriptions in MCP definitions
- **Measurement**: Re-run affected scenarios (1, 3, 4, 5, 6, 11)
- **Success**: Tool selection improves by 30%+

### If Schema Misunderstandings Common
- **Action**: Add inline documentation in schemas, simplify structure
- **Measurement**: Re-run mapping scenarios (7, 8, 9, 12)
- **Success**: Valid JSON submissions improve by 40%+

### If Validation Errors Common
- **Action**: Improve error messages with hints and examples
- **Measurement**: Re-run scenario 11 and any failing mappings
- **Success**: LLM recovers from errors without intervention

### If Mapping Field Confusion Common
- **Action**: Add mapping examples, improve field descriptions
- **Measurement**: Re-run all mapping scenarios
- **Success**: Mapping success rate improves by 30%+

### If snake_case Issues Common
- **Action**: Add prominent reminders in schemas
- **Decision**: Consider supporting camelCase or validation hints
- **Measurement**: Re-run mapping scenarios
- **Success**: LLM uses correct naming consistently

## Documentation Updates Required

After testing completes:

1. Add "Testing and Validation" section to docs/mcp-api-guide.md:
   - Test scenarios overview
   - Initial vs final success rates
   - Identified usability issues and solutions
   - Mapping usability findings
   - Recommendations for LLM clients

2. Update tool documentation:
   - Clarify tool descriptions if needed
   - Add examples if schema understanding was issue
   - Improve field documentation if confusion detected

3. Update mapping guide:
   - Clarify field purposes and ranges
   - Add validation examples
   - Document snake_case requirement clearly

## Timeline Estimate

- Initial testing: 1.5-2 hours (12 scenarios × 5-10 min each)
- Analysis: 30 minutes
- Improvements: 1-2 hours (depends on complexity)
- Re-testing: 1.5 hours
- Documentation: 1 hour
- **Total**: 6-7 hours

## Success Definition for Story

Story 4.10 is complete when:
- ✓ All 12 test scenarios executed and documented
- ✓ Baseline success rates measured
- ✓ Top 3 usability issues identified and documented
- ✓ Improvements implemented and re-tested
- ✓ Success rate targets achieved or documented why they cannot be met
- ✓ Testing results and recommendations added to docs/mcp-api-guide.md
- ✓ flutter analyze passes with zero warnings
- ✓ Story file updated with File List and completion notes

## Notes for Testing

- Keep detailed notes on LLM decision-making process
- Record exact parameter values LLM attempts to use
- Note any patterns in failures (e.g., all MIDI tests fail, or just certain channels)
- Consider repeating a failed scenario after improvements to see if fix helps
- Document any surprising successes or insights
- Save complete test logs for future reference
