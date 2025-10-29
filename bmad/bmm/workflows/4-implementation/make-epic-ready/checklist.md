# Make Epic Ready - Validation Checklist

This checklist validates that the make-epic-ready workflow executed successfully.

## Pre-Execution Validation

- [ ] Sprint status file exists and is readable
- [ ] Target epic identified (either provided or auto-discovered)
- [ ] At least one drafted story exists in the epic
- [ ] All drafted story files exist and are readable

## Parallel Context Generation Validation

- [ ] All story-context sub-agents launched in PARALLEL (single message, multiple tool calls)
- [ ] Sub-agents received "think hard" instruction for thorough context gathering
- [ ] All sub-agents completed execution
- [ ] Results collected from all sub-agents
- [ ] No context generation failures occurred

If context generation was skipped:
- [ ] skip_context_generation=true was set
- [ ] All context files already exist for all stories

## Per-Story Context Validation

For each drafted story:

- [ ] Story file loaded successfully
- [ ] Story status verified as "drafted"
- [ ] Context file generated at correct path: {story_dir}/{story_key}.context.xml
- [ ] Context file contains valid XML structure
- [ ] Context file includes acceptance_criteria section
- [ ] Context file includes story_tasks section
- [ ] Context file includes technical_context section
- [ ] Context file includes relevant documentation references
- [ ] Context file includes relevant code pattern references

## Optional Context Validation (if validate_context=true)

- [ ] All context files exist
- [ ] All context files have valid XML structure
- [ ] All context files contain required sections
- [ ] No validation failures occurred

## Sprint Status Update Validation

- [ ] Sprint status file loaded successfully
- [ ] All drafted story keys found in development_status section
- [ ] All story statuses updated from "drafted" to "ready-for-dev"
- [ ] Sprint status file written back successfully
- [ ] File formatting and order preserved

## Epic Readiness Validation

- [ ] All drafted stories processed
- [ ] All context files generated (or skipped with valid reason)
- [ ] All stories marked as "ready-for-dev" in sprint-status.yaml
- [ ] No stories left in "drafted" state
- [ ] Summary displayed with correct counts

## Parallel Execution Validation

CRITICAL - Verify parallel execution occurred:
- [ ] Sub-agent launch used SINGLE message with MULTIPLE tool calls
- [ ] Sub-agents did NOT execute sequentially
- [ ] Execution time was significantly faster than sequential processing would be
- [ ] All sub-agents ran concurrently

## Output Quality Validation

- [ ] Each story has complete context file
- [ ] Context files reflect "think hard" thoroughness
- [ ] Documentation references are accurate and relevant
- [ ] Code pattern references are current and applicable
- [ ] Architectural decisions are captured
- [ ] Integration points are identified

## Final Validation

- [ ] Sprint status file reflects accurate final state
- [ ] All context files are in correct location
- [ ] All stories ready for `finish-epic` or `dev-story` workflows
- [ ] User provided clear next steps
- [ ] No orphaned or incomplete workflow state

---

**Workflow Status:** [PASS / FAIL / PARTIAL]

**Stories Processed:** _____ / _____

**Context Files Generated:** _____ / _____

**Stories Marked Ready:** _____ / _____

**Parallel Execution:** [YES / NO / PARTIAL]

**Notes:**
