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
| 2025-11-08 | 4.10 | 4 | Testing | High | TBD | Open | Conduct actual LLM testing with Ollama or redefine story scope - AC #3, #7, #8, test_harness_llm_usability.py |
| 2025-11-08 | 4.10 | 4 | TechDebt | High | TBD | Open | Clarify expected vs measured results in Testing section - AC #9, docs/mcp-api-guide.md:1435-1440 |
| 2025-11-08 | 4.10 | 4 | Enhancement | Med | TBD | Open | Enhance error message examples (CV input, MIDI channel, mapping) - AC #10, lib/mcp/tools/disting_tools.dart |
| 2025-11-08 | 4.10 | 4 | Testing | Med | TBD | Open | Validate test harness integration with localhost:3000 - AC #1, test_harness_llm_usability.py |
| 2025-11-08 | 4.10 | 4 | TechDebt | Low | TBD | Open | Relocate test harness to test/integration/ or test/tools/ - test_harness_llm_usability.py |
| 2025-11-08 | 4.10 | 4 | Testing | Low | TBD | Open | Add error recovery test scenarios to test plan - AC #2, docs/llm-usability-test-plan.md |
| 2025-11-14 | 7.1 | 7 | Bug | High | TBD | Open | Mask disabled flag bits before decoding parameter values so flagged parameters keep their real values (lib/domain/sysex/sysex_utils.dart:17-34) |
| 2025-11-14 | 7.1 | 7 | Enhancement | Med | TBD | Open | Add tooltip/help text explaining why disabled parameters are grayed out/read-only (lib/ui/widgets/parameter_view_row.dart:141-210) |
| 2025-11-14 | 7.1 | 7 | Testing | Med | TBD | Open | Implement AC-9..AC-11 coverage (Clock integration toggling, widget opacity/read-only assertions, offline default enabled) |
| 2025-11-15 | 7.1 | 7 | Bug | Med | TBD | Open | Expose `is_disabled` via MCP `get_parameter_value`, `get_multiple_parameters`, and parameter search results so AC-7 clients see disabled state (`lib/mcp/tools/disting_tools.dart:556-588`, `lib/mcp/tools/disting_tools.dart:1413-1494`, `lib/mcp/tools/disting_tools.dart:3878-4012`, `lib/services/disting_controller_impl.dart:203-214`) |
| 2025-11-15 | 7.1 | 7 | Bug | Med | TBD | Open | Preserve `ParameterValue.isDisabled` when `_fixAlgorithmIndex` or similar helpers rebuild slots so reordering/removal does not re-enable controls (`lib/cubit/disting_cubit.dart:1885-1948`) |
| 2025-11-15 | 7.1 | 7 | Doc | Low | TBD | Open | Update parameter flag references to describe the implemented behavior instead of saying the flag is ignored (`docs/parameter-flag-analysis-report.md:117-160`, `docs/parameter-flag-findings.md:66-112`) |
| 2025-11-15 | 7.1 | 7 | Testing | Med | TBD | Open | Add AC-9..AC-11 coverage (Clock Internal↔External integration assertions, widget opacity/read-only tests, offline default-enabled verification; see `test/domain/sysex/responses/parameter_disabled_flag_test.dart`, `test/integration/parameter_flag_capture_test.dart`, `test/ui/widgets/parameter_editor_view_test.dart`) |
| 2025-11-15 | 7.1 | 7 | Bug | High | TBD | Open | Emit polling updates when only `isDisabled` toggles so UI/MCP reflect disabled-state changes (`lib/cubit/disting_cubit.dart:2119-2144`) |
| 2025-11-15 | 7.1 | 7 | Testing | Med | TBD | Open | Implement AC-9..AC-11 automation (Clock Internal↔External integration, widget opacity/read-only tests, offline default-enabled coverage) |
| 2025-11-15 | 7.1 | 7 | Doc | Low | TBD | Open | Point parameter-flag documentation/capture instructions to `tools/parameter_flag_analyzer.dart` instead of the missing `test/parameter_flag_test.dart` (`docs/parameter-flag-analysis-report.md:74-90`, `docs/parameter-flag-findings.md:162`, `tools/capture_parameter_flags.md:42-84`) |
