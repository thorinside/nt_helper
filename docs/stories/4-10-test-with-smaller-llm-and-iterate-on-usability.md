# Story 4.10: Test with smaller LLM and iterate on usability

Status: ready-for-dev

## Story

As a developer validating the "foolproof" goal,
I want to test the 4-tool API with mappings using a smaller LLM and measure success rate,
So that I can identify and fix remaining usability issues.

## Acceptance Criteria

1. Set up test environment with smaller LLM (GPT-OSS-20B or similar) connected to nt_helper MCP server
2. Conduct 12 test scenarios covering: search algorithms, create simple preset, create complex preset, modify preset, add MIDI mappings, add CV mappings, set performance pages, inspect state with mappings, handle errors
3. Measure success rate: % of scenarios where LLM successfully completes task without human intervention
4. Document failure modes: tool selection errors, schema misunderstandings, validation errors, mapping field confusion, snake_case issues
5. Identify top 3 usability issues from testing
6. Iterate on tool descriptions, JSON schemas, mapping documentation, or error messages to address issues
7. Re-test after improvements and document success rate change
8. Target: >80% success rate on simple operations, >60% on complex operations, >50% on mapping operations
9. Document findings and recommendations in `docs/mcp-api-guide.md`
10. Special focus on mapping usability: Are field names clear? Are validation errors helpful? Are examples sufficient? Is snake_case better than camelCase for LLMs?
11. `flutter analyze` passes with zero warnings

## Tasks / Subtasks

- [ ] Set up test environment (AC: 1)
  - [ ] Identify suitable smaller LLM for testing (GPT-OSS-20B or similar)
  - [ ] Set up MCP server connection (HTTP on port 3000)
  - [ ] Verify LLM can access all 4 tools (search, new, edit, show)
  - [ ] Verify LLM can read JSON schemas
  - [ ] Test basic tool invocation

- [ ] Design test scenarios (AC: 2)
  - [ ] Scenario 1: Search for algorithm by name (simple)
  - [ ] Scenario 2: Search for algorithm by category (simple)
  - [ ] Scenario 3: Create blank preset (simple)
  - [ ] Scenario 4: Create preset with 1 algorithm (simple)
  - [ ] Scenario 5: Create preset with 3 algorithms (complex)
  - [ ] Scenario 6: Modify preset - change parameter value (simple)
  - [ ] Scenario 7: Modify preset - add MIDI mapping to parameter (mapping)
  - [ ] Scenario 8: Modify preset - add CV mapping to parameter (mapping)
  - [ ] Scenario 9: Modify preset - assign parameters to performance page (mapping)
  - [ ] Scenario 10: Inspect preset with mappings (simple)
  - [ ] Scenario 11: Handle validation error gracefully (error handling)
  - [ ] Scenario 12: Partial mapping update - MIDI only (mapping, complex)

- [ ] Conduct initial testing round (AC: 3-4)
  - [ ] Run each scenario with smaller LLM
  - [ ] Record: success/failure for each scenario
  - [ ] Document failure modes when they occur
  - [ ] Note: tool selection errors (wrong tool chosen)
  - [ ] Note: schema misunderstandings (incorrect parameters)
  - [ ] Note: validation errors (invalid values)
  - [ ] Note: mapping field confusion (wrong field names, wrong types)
  - [ ] Note: snake_case issues (used camelCase instead)
  - [ ] Calculate success rate: (successful scenarios / total scenarios) * 100%

- [ ] Analyze results and identify usability issues (AC: 5)
  - [ ] Review all failure modes
  - [ ] Group similar failures
  - [ ] Identify patterns (e.g., all MIDI mapping attempts failed)
  - [ ] Rank issues by frequency and impact
  - [ ] Select top 3 usability issues to address
  - [ ] Document specific problems for each issue

- [ ] Implement improvements (AC: 6)
  - [ ] For each top issue: determine root cause
  - [ ] Improve tool descriptions if needed
  - [ ] Improve JSON schemas if needed
  - [ ] Improve mapping documentation if needed
  - [ ] Improve error messages if needed
  - [ ] Add missing examples if needed
  - [ ] Clarify field names or types if needed
  - [ ] Consider snake_case vs camelCase based on LLM performance

- [ ] Re-test and measure improvement (AC: 7)
  - [ ] Run all 12 scenarios again with smaller LLM
  - [ ] Record success/failure for each scenario
  - [ ] Calculate new success rate
  - [ ] Document success rate change (before → after)
  - [ ] Verify improvements addressed identified issues
  - [ ] If success rate still below target: identify new issues and iterate

- [ ] Validate success rate targets (AC: 8)
  - [ ] Simple operations (scenarios 1-4, 6, 10): Target >80% success
  - [ ] Complex operations (scenarios 5, 11): Target >60% success
  - [ ] Mapping operations (scenarios 7-9, 12): Target >50% success
  - [ ] If below target: iterate on improvements
  - [ ] Document final success rates

- [ ] Document findings and recommendations (AC: 9-10)
  - [ ] Add testing results section to `docs/mcp-api-guide.md`
  - [ ] Document test scenarios used
  - [ ] Document initial vs final success rates
  - [ ] Document identified usability issues and solutions
  - [ ] Document mapping usability findings:
    - Are field names clear? (snake_case vs camelCase)
    - Are validation errors helpful?
    - Are examples sufficient?
    - Are mapping concepts well-explained?
  - [ ] Include recommendations for LLM clients
  - [ ] Include recommendations for future API improvements

- [ ] Final validation (AC: 11)
  - [ ] Run `flutter analyze` and fix warnings
  - [ ] Review all changes made during iteration
  - [ ] Ensure documentation is complete
  - [ ] Verify all test scenarios documented

## Dev Notes

### Architecture Context

- MCP server: `lib/services/mcp_server_service.dart`
- Tools: `lib/mcp/tools/algorithm_tools.dart`, `lib/mcp/tools/disting_tools.dart`
- Documentation: `docs/mcp-api-guide.md`, `docs/mcp-mapping-guide.md`
- JSON schemas: Embedded in tool definitions

### Test Scenario Design Principles

**Simple operations**:
- Single tool call
- Minimal parameters
- Clear expected outcome
- Easy to verify success
- Examples: search by name, create blank preset, inspect preset

**Complex operations**:
- Multiple tool calls or complex parameters
- Requires understanding of relationships
- May involve error handling
- Examples: create preset with 3 algorithms, handle validation error

**Mapping operations**:
- Involves mapping field structures
- Requires understanding of mapping types (CV/MIDI/i2c)
- Tests partial updates and preservation
- Examples: add MIDI mapping, partial MIDI update

### Success Rate Calculation

```
Success Rate = (Successful Scenarios / Total Scenarios) * 100%

Simple Success Rate = (Successful Simple Scenarios / Total Simple Scenarios) * 100%
Complex Success Rate = (Successful Complex Scenarios / Total Complex Scenarios) * 100%
Mapping Success Rate = (Successful Mapping Scenarios / Total Mapping Scenarios) * 100%
```

### Scenario Success Criteria

A scenario is successful if:
1. LLM selects correct tool
2. LLM provides correct parameters (JSON schema validation)
3. Tool executes without error
4. LLM can verify the result (if verification step included)
5. No human intervention required

A scenario fails if:
- LLM selects wrong tool
- LLM provides incorrect parameters
- Tool returns validation error due to LLM mistake
- LLM cannot complete task without human guidance

### Common Failure Modes to Watch For

**Tool Selection Errors**:
- Uses `new` instead of `edit` for modifications
- Uses `edit` with preset target instead of slot target when appropriate
- Uses wrong granularity level

**Schema Misunderstandings**:
- Missing required fields
- Wrong parameter types (string instead of int)
- Incorrect nesting (flat instead of nested objects)

**Validation Errors**:
- MIDI channel 16 (should be 0-15)
- CV input 13 (should be 0-12)
- Performance page 16 (should be 0-15)
- Missing required mapping fields (e.g., `is_midi_enabled`)

**Mapping Field Confusion**:
- Using camelCase instead of snake_case
- Confusing `cv_input` with `source`
- Confusing MIDI channel 0-15 with 1-16
- Not understanding partial updates

**snake_case vs camelCase**:
- Do smaller LLMs prefer snake_case or camelCase?
- Measure error rates for each convention
- Consider switching if one is significantly better

### Usability Improvement Strategies

**If tool selection errors are common**:
- Improve tool descriptions
- Add more examples showing when to use each tool
- Clarify granularity levels (preset vs slot vs parameter)

**If schema misunderstandings are common**:
- Simplify schemas
- Add more inline documentation
- Add more examples
- Highlight required vs optional fields

**If validation errors are common**:
- Improve error messages
- Add hints in schemas (e.g., "MIDI channel 0-15, not 1-16")
- Add validation examples to documentation

**If mapping field confusion is common**:
- Add more mapping examples
- Improve field descriptions
- Add mapping field reference table
- Consider renaming confusing fields

**If snake_case issues are common**:
- If LLM consistently uses camelCase, consider supporting both
- OR add prominent snake_case reminder in schemas
- OR add validation that suggests snake_case alternative when camelCase detected

### Testing Environment Notes

**Smaller LLM Selection**:
- GPT-OSS-20B or similar size
- Should be capable but not cutting-edge
- Goal: If it works for smaller LLM, will definitely work for larger ones
- Consider: GPT-3.5 as baseline comparison

**Test Setup**:
- Automated if possible (scripted scenarios)
- Manual observation of LLM behavior
- Record all tool calls and responses
- Track time to completion (usability metric)

### Documentation Updates

Add to `docs/mcp-api-guide.md`:

```markdown
## Testing and Validation

This API has been tested with smaller language models to ensure usability.

### Test Results
- **Simple Operations**: 85% success rate (target: >80%)
- **Complex Operations**: 65% success rate (target: >60%)
- **Mapping Operations**: 55% success rate (target: >50%)

### Common Issues Found
1. [Issue description and solution]
2. [Issue description and solution]
3. [Issue description and solution]

### Recommendations for LLM Clients
- Always use snake_case for field names
- Refer to examples when constructing complex mapping objects
- Use slot-level edits for single-algorithm changes
- Use parameter-level edits for quick tweaks
- Verify changes with `show` tool after `edit`

### Field Naming Convention
We use snake_case (not camelCase) for all JSON fields based on testing with smaller LLMs, which showed [X]% better success rates with snake_case.
```

### Project Structure Notes

- Testing results: Document in `docs/mcp-api-guide.md`
- Test scenarios: May create `test/mcp/integration/llm_usability_test.dart` if automated
- No new code files required (testing and documentation only)

### References

- [Source: docs/architecture.md#Critical Architecture: MCP Server]
- [Source: docs/epics.md#Story E4.10]
- [Source: docs/epics.md#Epic 4 Expanded Goal - "foolproof" objective]

## Dev Agent Record

### Context Reference

<!-- Path(s) to story context XML will be added here by context workflow -->

### Agent Model Used

### Debug Log References

### Completion Notes List

### File List
