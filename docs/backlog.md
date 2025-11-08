# Engineering Backlog

This backlog collects cross-cutting or future action items that emerge from reviews and planning.

Routing guidance:

- Use this file for non-urgent optimizations, refactors, or follow-ups that span multiple stories/epics.
- Must-fix items to ship a story belong in that story’s `Tasks / Subtasks`.
- Same-epic improvements may also be captured under the epic Tech Spec `Post-Review Follow-ups` section.

| Date | Story | Epic | Type | Severity | Owner | Status | Notes |
| ---- | ----- | ---- | ---- | -------- | ----- | ------ | ----- |
| 2025-11-07 | 4.4 | 4 | Bug | High | TBD | Open | Implement mapping update logic in _applyDiff() - AC #6-8, lib/mcp/tools/disting_tools.dart:2598-2622 |
| 2025-11-07 | 4.4 | 4 | Bug | High | TBD | Open | Implement algorithm reordering logic in _applyDiff() - AC #10, needs moveAlgorithmUp/Down calls |
| 2025-11-07 | 4.4 | 4 | TechDebt | High | TBD | Open | Add diff operation tests (reorder, mappings, combined) - AC #18, test/mcp/tools/edit_preset_tool_test.dart |
| 2025-11-07 | 4.4 | 4 | Bug | High | TBD | Open | Add connection mode validation (must be Synchronized) - AC #16, editPreset() method |
| 2025-11-07 | 4.4 | 4 | TechDebt | Med | TBD | Open | Fix DesiredSlot.mapping field usage or remove - lines 2259, 2648 in disting_tools.dart |
| 2025-11-07 | 4.4 | 4 | Performance | Med | TBD | Open | Optimize AlgorithmMetadataService access (singleton) - lines 2559, 2578 in disting_tools.dart |
| 2025-11-07 | 4.4 | 4 | Bug | Med | TBD | Open | Implement atomic change handling (rollback on error) - AC #15, lines 2614-2618 |
| 2025-11-08 | 4.5 | 4 | TechDebt | Med | TBD | Open | Implement mapping application logic for slot-level edits - AC #6, #9, lib/mcp/tools/disting_tools.dart:2648-2654 |
| 2025-11-08 | 4.5 | 4 | TechDebt | Low | TBD | Open | Consolidate duplicate AlgorithmMetadataService instantiation - lib/mcp/tools/disting_tools.dart:2471, 2487 |
| 2025-11-08 | 4.5 | 4 | TechDebt | Low | TBD | Open | Add comment explaining parameter validation sequence requirement - lib/mcp/tools/disting_tools.dart:2543 |
