# Finish Epic Workflow

**Orchestrates sequential story development through dev-story and review-story workflows until all stories in an epic are completed.**

## Purpose

The `finish-epic` workflow automates the repetitive cycle of story development and review, reducing manual workflow invocation while maintaining user-centric control. It handles the complete dev-review-retry cycle for all stories in an epic, stopping only when impediments require user intervention.

## Key Features

- **Auto-Epic Discovery**: Automatically identifies the next epic with pending stories if not specified
- **Sequential Processing**: Processes stories one at a time in sprint-status.yaml order
- **Auto-Retry on Review Feedback**: When review-story identifies needed changes, automatically re-runs dev-story (configurable max cycles)
- **Intelligent Impediment Detection**: Stops and provides actionable guidance for blockers (test failures, missing dependencies, unclear ACs)
- **Resume Capability**: Provides exact resume commands when halted

## When to Use

**Use finish-epic when:**
- You have multiple stories ready for development in an epic
- Stories are well-defined with clear acceptance criteria
- You want to automate the dev → review → fix → review cycle
- You're comfortable with sub-agent automation handling implementation

**Don't use finish-epic when:**
- Stories need significant clarification or architectural decisions
- Epic has only 1-2 stories (just use dev-story + review-story directly)
- You want fine-grained control over each story's implementation approach
- Stories have complex dependencies requiring manual coordination

## Usage

### Basic Usage (Auto-Discovery)

```bash
/bmad:bmm:workflows:finish-epic
```

Automatically finds the first epic with non-done stories and starts processing.

### Specify Epic

```bash
/bmad:bmm:workflows:finish-epic epic_key=epic-3
```

Process all pending stories in epic-3.

### Resume from Specific Story

```bash
/bmad:bmm:workflows:finish-epic epic_key=epic-3 story_key=e3-5-execute-package-installation
```

Start processing from story e3-5 in epic-3 (useful after resolving impediments).

## Configuration

The workflow can be customized via variables in `workflow.yaml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `epic_key` | Auto-discovered | Target epic to process |
| `story_key` | First non-done | Starting story in epic |
| `max_review_retry_cycles` | 3 | Max dev-review cycles before halting for user |
| `auto_advance_on_success` | true | Move to next story when current is done |
| `pause_between_stories` | false | Wait for user confirmation between stories |

## Workflow Steps

1. **Epic Discovery**: Loads sprint-status.yaml and identifies target epic
2. **Story Queue Building**: Extracts all non-done stories from the epic in order
3. **Story Processing Loop**: For each story:
   - Execute `dev-story` workflow via sub-agent
   - Execute `review-story` workflow via sub-agent
   - If review requests changes:
     - Re-execute `dev-story` with feedback
     - Re-execute `review-story`
     - Repeat up to `max_review_retry_cycles`
   - If approved: mark story as done and advance
   - If impediment: halt and provide resume command
4. **Epic Completion**: Display summary and suggest retrospective

## Impediment Handling

The workflow halts and provides guidance for:

- **Test Failures**: Suggests reviewing test output and fixing manually
- **Missing Dependencies**: Recommends installing deps and updating architecture
- **Unclear Acceptance Criteria**: Points to `correct-course` workflow
- **Max Retry Cycles Exceeded**: Suggests story may be too large or complex
- **Review-Story Errors**: Directs to story review notes for details

When halted, the workflow provides an exact resume command:

```bash
/bmad:bmm:workflows:finish-epic epic_key=epic-3 story_key=e3-5-execute-package-installation
```

## Sub-Agent Orchestration

This workflow coordinates three sub-agents:

1. **Developer Agent**: Executes `dev-story` workflow for implementation
2. **Senior Developer Reviewer**: Executes `review-story` workflow for quality checks
3. **Status Manager**: Executes `story-done` workflow to update sprint status

Each sub-agent runs autonomously according to its workflow instructions.

## Output

The workflow provides:

- Real-time progress updates for each story
- Clear impediment descriptions with actionable guidance
- Resume commands for halted workflows
- Epic completion summary with retrospective suggestion

## Related Workflows

- **dev-story**: Single story implementation (executed by finish-epic)
- **review-story**: Single story review (executed by finish-epic)
- **story-done**: Mark story complete (executed by finish-epic)
- **retrospective**: Post-epic review (suggested after completion)
- **correct-course**: Handle significant changes during sprint

## Example Session

```
🎯 Target Epic: epic-3
📊 Stories to process: 5

═══════════════════════════════════════════════════════════
🚀 Processing Story 1 of 5
📌 Story: e3-1-integrate-droptarget
📊 Current Status: ready-for-dev
═══════════════════════════════════════════════════════════

🔧 Executing dev-story workflow...
[Dev Agent implements story...]
✅ Development phase complete

🔍 Executing review-story workflow...
[Review Agent reviews code...]
🔄 Review requires changes - initiating retry cycle 1...

🔧 Re-executing dev-story workflow...
[Dev Agent addresses feedback...]
✅ Development phase complete

🔍 Re-executing review-story workflow...
[Review Agent reviews again...]
✅ Review PASSED - Story approved

📋 Marking story as done...
✅ Story e3-1-integrate-droptarget marked as DONE

➡️  Auto-advancing to next story...

[Process continues for remaining stories...]

═══════════════════════════════════════════════════════════
🎉 EPIC epic-3 COMPLETE! 🎉
═══════════════════════════════════════════════════════════

Stories Processed: 5
All Acceptance Criteria Met: ✅
All Reviews Passed: ✅

Next Steps:
1. Run retrospective workflow for epic-3
2. Review and update sprint-status.yaml
3. Consider starting next epic

Retrospective Command:
Run: retrospective epic=epic-3
```

## Notes

- The workflow is **sequential only** - stories are processed one at a time
- Story order is preserved from sprint-status.yaml (top to bottom)
- Each story must pass review before advancing to the next
- The workflow maintains full audit trail in story Dev Agent Records and Review sections
