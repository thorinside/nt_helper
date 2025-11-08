# LLM Usability Testing - Execution Guide

## Quick Start

This guide walks through executing the LLM usability test for Story 4.10.

## Prerequisites

1. **nt_helper running**:
   ```bash
   flutter run -d macos --print-dtd
   ```
   - Note the DTD URL for MCP connection
   - Ensure MCP server is running on localhost:3000

2. **Ollama LLM running**:
   ```bash
   # On dionysus server
   ollama pull llama2  # or other model
   ollama serve        # or already running as service
   ```
   - Verify connection: `curl http://dionysus:11434/api/tags`

3. **Python test harness prerequisites**:
   ```bash
   pip install requests
   # Or: pip3 install requests
   ```

## Test Execution

### Option 1: Automated Test Harness (Recommended for Initial Round)

```bash
cd /Users/nealsanche/nosuch/nt_helper

# Run with defaults (localhost:3000 for MCP, dionysus:11434 for LLM)
python3 test_harness_llm_usability.py

# Or with custom parameters
python3 test_harness_llm_usability.py \
  --mcp-host localhost \
  --mcp-port 3000 \
  --llm-host dionysus \
  --llm-port 11434 \
  --llm-model llama2 \
  --output llm_test_results_baseline.json
```

The script will:
1. Run all 12 scenarios sequentially
2. Record tool selection, parameters, and results
3. Measure success rate by operation type
4. Save detailed results to JSON file
5. Display summary with failure modes

### Option 2: Manual Testing (For Detailed Observation)

If you want to observe the LLM decision-making process more closely:

1. **Terminal 1 - Start nt_helper MCP Server**:
   ```bash
   flutter run -d macos
   # Wait for "MCP server started on port 3000"
   ```

2. **Terminal 2 - Test individual scenario**:
   ```bash
   # Use curl to interact with MCP server directly
   curl -X POST http://localhost:3000/mcp/invoke \
     -H "Content-Type: application/json" \
     -d '{"tool": "search", "arguments": {"type": "algorithm", "query": "filter"}}'
   ```

3. **Terminal 3 - Query LLM directly**:
   ```bash
   curl -X POST http://dionysus:11434/api/generate \
     -H "Content-Type: application/json" \
     -d '{
       "model": "llama2",
       "prompt": "I want to search for filter algorithms in the Disting NT. What tool and parameters should I use?",
       "stream": false
     }'
   ```

4. **Observe and record**:
   - LLM response
   - Tool choice
   - Parameter validity
   - Tool execution result

## Test Results Interpretation

### Success Rate Targets

- **Simple operations**: Target >80%
  - Scenarios: 1, 2, 3, 4, 6, 10
  - These should be easiest - basic tool selection and simple parameters

- **Complex operations**: Target >60%
  - Scenarios: 5, 11
  - Involve multi-item arrays and error handling

- **Mapping operations**: Target >50%
  - Scenarios: 7, 8, 9, 12
  - Most challenging - complex nested structures, many fields, validation details

### Failure Mode Categories

Review the `failure_mode` field in results:

1. **tool_selection**: Wrong MCP tool chosen
   - Fix: Improve tool descriptions in schema
   - Re-test scenarios: 1-6, 10-12

2. **invalid_parameters**: Correct tool but invalid parameters
   - Fix: Simplify schemas, add inline docs
   - Re-test affected scenarios

3. **parse_error**: Could not parse LLM response
   - Issue: LLM format inconsistent
   - Try: Different LLM model or temperature

4. **validation_error**: Tool returned error
   - Fix: Improve error messages with hints
   - Re-test: Scenario 11 specifically

5. **mapping_confusion**: Fields unclear or wrong types
   - Fix: Add more mapping examples
   - Re-test: Scenarios 7-9, 12

## Results Analysis

After running tests, analyze results:

```bash
# View results
cat llm_test_results_baseline.json | python3 -m json.tool

# Count failures by mode
python3 << 'EOF'
import json
with open('llm_test_results_baseline.json') as f:
    results = json.load(f)
    failures = {}
    for r in results:
        if not r['success']:
            mode = r['failure_mode'] or 'unknown'
            failures[mode] = failures.get(mode, 0) + 1
    print("Failure modes:", failures)
    for mode, count in sorted(failures.items(), key=lambda x: x[1], reverse=True):
        print(f"  {mode}: {count}")
EOF
```

## Improvement Implementation

### If Tool Selection Errors Common

1. **Review current tool descriptions**:
   ```bash
   grep -A5 '"description"' lib/mcp/tools/disting_tools.dart | head -50
   ```

2. **Improve descriptions to clarify**:
   - When to use each tool
   - Differences between granularity levels
   - Common mistakes to avoid

3. **Example improvement**:
   ```
   OLD: "Modify preset, slot, or parameter"
   NEW: "Modify preset, slot, or parameter. Use target='parameter' for quick tweaks,
        target='slot' to change algorithm, target='preset' for bulk changes."
   ```

### If Schema Misunderstandings Common

1. **Identify which fields cause confusion**:
   - Check failed scenario parameters
   - Look for missing required fields
   - Check for type mismatches

2. **Improve schema documentation**:
   - Add "required" field descriptions
   - Add inline examples
   - Highlight tricky fields

3. **Simplify if possible**:
   - Reduce nested structure depth
   - Consolidate related fields
   - Remove unnecessary optional fields

### If Mapping Confusion Common

1. **Check field naming**:
   - Verify all fields use snake_case
   - Confirm naming is clear
   - Check for ambiguous field pairs (e.g., source vs cv_input)

2. **Add mapping examples**:
   - Update mcp-mapping-guide.md
   - Add complete JSON examples
   - Document field purposes clearly

3. **Create mapping field reference table**:
   ```markdown
   | Field | Type | Range | Purpose |
   |-------|------|-------|---------|
   | midi_channel | integer | 0-15 | MIDI channel (1=0, 16=15) |
   | cv_input | integer | 0-12 | Physical CV input (0=disabled) |
   | ...
   ```

## Re-Testing After Improvements

1. **Document changes made**:
   - What improvements were implemented
   - Which scenarios should improve
   - Expected new success rate

2. **Run tests again**:
   ```bash
   python3 test_harness_llm_usability.py \
     --output llm_test_results_improved.json
   ```

3. **Compare results**:
   ```bash
   python3 << 'EOF'
   import json

   with open('llm_test_results_baseline.json') as f:
       baseline = json.load(f)
   with open('llm_test_results_improved.json') as f:
       improved = json.load(f)

   print("Success Rate Comparison:")
   print(f"  Baseline: {sum(1 for r in baseline if r['success'])}/{len(baseline)}")
   print(f"  Improved: {sum(1 for r in improved if r['success'])}/{len(improved)}")

   # By operation type
   for op_type in ['simple', 'complex', 'mapping']:
       base_count = len([r for r in baseline if r['op_type'] == op_type])
       base_success = sum(1 for r in baseline if r['op_type'] == op_type and r['success'])
       imp_success = sum(1 for r in improved if r['op_type'] == op_type and r['success'])
       print(f"  {op_type}: {base_success}/{base_count} → {imp_success}/{base_count}")
   EOF
   ```

## Common Issues and Solutions

### MCP Server Not Responding

```bash
# Check if running
curl http://localhost:3000/mcp/invoke -X OPTIONS

# Check logs
# Look at nt_helper console output
# Look for "MCP server started"
```

### LLM Not Responding

```bash
# Check Ollama
curl http://dionysus:11434/api/tags

# Restart if needed
ssh dionysus "pkill ollama; sleep 2; ollama serve &"

# Or run locally instead
# ollama serve  # on local machine
# Then use --llm-host localhost
```

### LLM Responses Inconsistent

- Try different temperature (lower = more consistent)
- Try different model (llama2, mistral, neural-chat, etc.)
- Increase timeout if responses are slow

### Test Harness Timeout

- Increase `--timeout` parameter if available
- Run slower (add delays between scenarios)
- Check network connectivity

## Documentation

After testing completes, document findings in:
- `docs/mcp-api-guide.md` - Add "Testing and Validation" section
- `docs/llm-usability-test-results.md` - Detailed findings
- `docs/llm-test-execution-guide.md` - This file

## Next Steps

1. **Run initial test round** - Establish baseline
2. **Analyze results** - Identify top 3 issues
3. **Implement improvements** - Target highest-impact issues
4. **Re-test** - Verify improvements work
5. **Document** - Add findings to mcp-api-guide.md
6. **Validate** - Confirm targets are met

## Testing Timeline Estimate

- Initial test run: 30-60 minutes (depending on LLM speed)
- Analysis: 15-20 minutes
- Improvements: 30-120 minutes
- Re-testing: 30-60 minutes
- Documentation: 30 minutes

**Total: 2-4 hours per iteration**

## Success Criteria

Story 4.10 complete when:
- ✓ All 12 scenarios executed
- ✓ Baseline success rates documented
- ✓ Top 3 issues identified
- ✓ Improvements implemented and re-tested
- ✓ Target success rates achieved or documented blockers
- ✓ Findings added to mcp-api-guide.md
- ✓ flutter analyze passes
