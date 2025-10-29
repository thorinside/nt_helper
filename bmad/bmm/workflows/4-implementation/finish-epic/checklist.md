# Finish Epic - Validation Checklist

This checklist validates that the finish-epic workflow executed successfully.

## Pre-Execution Validation

- [ ] Sprint status file exists and is readable
- [ ] Target epic identified (either provided or auto-discovered)
- [ ] At least one non-done story exists in the epic
- [ ] Story files exist for all pending stories in the queue

## Per-Story Validation

For each story processed:

- [ ] Story file loaded successfully
- [ ] dev-story workflow completed without HALT conditions
- [ ] All story tasks/subtasks checked as complete
- [ ] All acceptance criteria satisfied
- [ ] Tests passing (if applicable)
- [ ] review-story workflow executed
- [ ] Review outcome captured in story file
- [ ] If changes needed: retry cycle initiated (within max_review_retry_cycles)
- [ ] If approved: story marked as done in sprint-status.yaml
- [ ] Story status updated correctly in sprint-status.yaml

## Epic Completion Validation

- [ ] All stories in epic processed sequentially
- [ ] All stories marked as "done" in sprint-status.yaml
- [ ] No stories left in pending state
- [ ] No impediments or blockers remain
- [ ] Epic completion summary displayed
- [ ] Retrospective workflow suggested to user

## Impediment Handling Validation

If workflow halted:

- [ ] Clear impediment description provided
- [ ] Specific recommended actions listed
- [ ] Resume command provided with correct epic_key and story_key
- [ ] User notified of halt condition

## Retry Cycle Validation

For stories requiring changes:

- [ ] Retry count incremented correctly
- [ ] Max retry cycles enforced (default: 3)
- [ ] Dev-story re-executed with review feedback context
- [ ] Review-story re-executed after dev changes
- [ ] Cycle continues until approval or max retries reached

## Final Validation

- [ ] Sprint status file reflects accurate final state
- [ ] All story files contain complete Dev Agent Records
- [ ] All story files contain Review sections
- [ ] No orphaned or incomplete workflow state
- [ ] User provided clear next steps (retrospective)

---

**Workflow Status:** [PASS / FAIL / PAUSED]

**Notes:**
