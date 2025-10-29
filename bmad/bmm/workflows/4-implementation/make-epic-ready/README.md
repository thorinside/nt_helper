# Make Epic Ready Workflow

**Orchestrates parallel story context generation for all drafted stories in an epic, then marks them all as ready-for-dev.**

## Purpose

The `make-epic-ready` workflow accelerates the transition from story drafting to development by generating context files for all drafted stories in parallel, then marking them all as ready-for-dev. Designed for the Scrum Master agent after user has reviewed and approved drafted stories.

## Key Features

- **Auto-Epic Discovery**: Automatically identifies the next epic with drafted stories if not specified
- **Parallel Context Generation**: Launches multiple sub-agents simultaneously to generate context files
- **"Think Hard" Prompting**: Instructs sub-agents to be thorough in gathering context for developers
- **Optional Validation**: Can validate generated context files (optional, can be omitted for speed)
- **Batch Status Update**: Marks all stories as ready-for-dev in a single operation
- **Skip Option**: Can skip context generation if context files already exist

## When to Use

**Use make-epic-ready when:**
- SM agent has drafted multiple stories for an epic
- User has reviewed and approved the drafted stories
- You want to prepare all stories for development simultaneously
- You want to leverage parallel execution for speed

**Don't use make-epic-ready when:**
- Only 1-2 stories need context (use `story-context` directly instead)
- Stories haven't been reviewed by user yet
- Stories need significant revision before development
- You prefer manual, sequential context generation for fine control

## Usage

### Basic Usage (Auto-Discovery)

```bash
/bmad:bmm:workflows:make-epic-ready
```

Automatically finds the first epic with drafted stories and prepares them all.

### Specify Epic

```bash
/bmad:bmm:workflows:make-epic-ready epic_key=epic-3
```

Prepare all drafted stories in epic-3.

### Skip Context Generation (Context Already Exists)

```bash
/bmad:bmm:workflows:make-epic-ready epic_key=epic-3 skip_context_generation=true
```

Only mark stories as ready-for-dev, assuming context files already exist.

### Enable Context Validation

```bash
/bmad:bmm:workflows:make-epic-ready epic_key=epic-3 validate_context=true
```

Generate context and validate all files before marking stories ready.

## Configuration

The workflow can be customized via variables in `workflow.yaml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `epic_key` | Auto-discovered | Target epic to process |
| `validate_context` | false | Validate generated context files (adds time) |
| `skip_context_generation` | false | Only mark ready (assumes context exists) |

## Workflow Steps

1. **Epic Discovery**: Loads sprint-status.yaml and identifies target epic with drafted stories
2. **Story Collection**: Extracts all drafted stories from the epic in order
3. **Parallel Context Generation**:
   - Launches ALL sub-agents in PARALLEL (single message, multiple tool calls)
   - Each sub-agent receives "think hard" instruction
   - Each sub-agent executes `story-context` workflow
   - Collects results from all sub-agents
4. **Optional Validation**: Validates generated context files if enabled
5. **Batch Status Update**: Marks all stories as ready-for-dev in sprint-status.yaml
6. **Readiness Summary**: Displays completion summary with next steps

## Parallel Execution

**CRITICAL**: This workflow is designed for TRUE parallel execution:

- All sub-agents launch in a SINGLE message with MULTIPLE tool calls
- Sub-agents run CONCURRENTLY, not sequentially
- Execution time is dramatically faster than sequential processing
- Ideal for epics with 3+ stories

### Example Parallel Launch

For an epic with 5 drafted stories, the workflow:
1. Prepares 5 sub-agent configurations
2. Launches ALL 5 in a single message
3. Waits for ALL 5 to complete
4. Processes results

This is significantly faster than running 5 sequential `story-context` commands.

## "Think Hard" Prompting

Each sub-agent receives this instruction:

> "Think hard about this story's context. Consider all relevant documentation, existing code patterns, architectural decisions, and potential integration points. Be thorough in gathering context - the developer will rely on this for implementation."

This encourages:
- Deeper analysis of story requirements
- More thorough documentation gathering
- Better identification of code patterns
- More complete integration point discovery

## Sub-Agent Orchestration

This workflow coordinates **Scrum Master (Story Context Specialist)** sub-agents:

- **Workflow**: `story-context`
- **Execution Mode**: Parallel
- **Expected Output**: `.context.xml` files for each story
- **Quality Guidance**: "Think hard" instruction for thoroughness

## Output

The workflow provides:

- Epic and story discovery summary
- Real-time parallel execution status
- Context generation results for each story
- Optional validation results
- Batch status update confirmation
- Readiness summary with next steps

## Related Workflows

- **story-context**: Single story context generation (executed in parallel by make-epic-ready)
- **create-story**: Draft new stories (run before make-epic-ready)
- **finish-epic**: Execute all ready stories (run after make-epic-ready)
- **dev-story**: Single story development (alternative to finish-epic)

## Example Session

```
🎯 Target Epic: epic-3
📊 Stories to process: 5

Stories to Process:
- e3-1-integrate-droptarget
- e3-2-handle-dropped-files
- e3-3-detect-file-conflicts
- e3-4-display-package-install-dialog
- e3-5-execute-package-installation

Processing Plan:
- Generate story context: YES (parallel execution)
- Validate context: NO (omitted for speed)
- Mark stories ready: YES (all stories)

═══════════════════════════════════════════════════════════
🚀 Launching Parallel Context Generation
═══════════════════════════════════════════════════════════

Strategy: Launch 5 sub-agents in parallel
Sub-Agent Type: Scrum Master (Story Context Specialist)
Workflow: story-context

[5 sub-agents launch simultaneously...]

✅ All context files generated successfully

✓ e3-1-integrate-droptarget → docs/stories/e3-1-integrate-droptarget.context.xml
✓ e3-2-handle-dropped-files → docs/stories/e3-2-handle-dropped-files.context.xml
✓ e3-3-detect-file-conflicts → docs/stories/e3-3-detect-file-conflicts.context.xml
✓ e3-4-display-package-install-dialog → docs/stories/e3-4-display-package-install-dialog.context.xml
✓ e3-5-execute-package-installation → docs/stories/e3-5-execute-package-installation.context.xml

═══════════════════════════════════════════════════════════
📋 Marking Stories Ready for Development
═══════════════════════════════════════════════════════════

Stories to Update: 5
Status Change: drafted → ready-for-dev

✅ Sprint status updated

✓ e3-1-integrate-droptarget: drafted → ready-for-dev
✓ e3-2-handle-dropped-files: drafted → ready-for-dev
✓ e3-3-detect-file-conflicts: drafted → ready-for-dev
✓ e3-4-display-package-install-dialog: drafted → ready-for-dev
✓ e3-5-execute-package-installation: drafted → ready-for-dev

═══════════════════════════════════════════════════════════
🎉 EPIC epic-3 STORIES ARE READY! 🎉
═══════════════════════════════════════════════════════════

Stories Prepared: 5
Context Files Generated: 5
Stories Marked Ready: 5

Next Steps:
1. Stories are now ready for development
2. Run finish-epic epic_key=epic-3 to process all stories automatically
3. Or manually run dev-story for individual story control

Start Development:
Run: finish-epic epic_key=epic-3
```

## Performance Comparison

### Sequential Execution (NOT this workflow)
- Story 1 context: 30 seconds
- Story 2 context: 30 seconds
- Story 3 context: 30 seconds
- **Total: ~90 seconds**

### Parallel Execution (this workflow)
- All 3 stories simultaneously: 30 seconds
- **Total: ~30 seconds** (3x faster!)

For epics with 5-7 stories, time savings are even more significant.

## Error Handling

The workflow halts and provides guidance for:

- **No Drafted Stories**: Suggests running `create-story` or checking different epic
- **Context Generation Failures**: Lists failed stories with specific errors
- **Validation Failures**: Identifies problematic context files with issues
- **Missing Epic**: Suggests verifying epic key

When halted, the workflow provides clear recovery steps.

## Notes

- Context generation is TRUE parallel execution (all sub-agents launch in single message)
- Sub-agents receive "think hard" instruction for thorough context gathering
- Validation is optional and can be omitted for faster execution
- Can skip context generation if context files already exist
- Integrates seamlessly with `finish-epic` for end-to-end epic completion
- Designed specifically for Scrum Master agent workflow
