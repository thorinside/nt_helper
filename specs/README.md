# nt_helper decision-free spec programs

> The dated `.md` files in this folder are one-off design specs (a different,
> older convention). Decision-free executor programs live in named subfolders,
> each containing a `spec.md` (architecture — already decided) and a `plan.md`
> (ordered mechanical steps). To extend a program or add one, use the
> `decision-free-specs` skill.

The executing model makes **zero architectural decisions**: every file path,
widget tree, cubit method signature, label string, test name, and commit message
is specified. Where something unexpected appears, plans give a mechanical
recovery rule instead of asking for judgment.

## Programs

| Folder | Purpose | Steps | Difficulty |
|---|---|---|---|
| `poly-samples-ui/` | Rebuild the multisample (Samples) editor UI as a standalone pushed screen with feature parity to the fork implementation | 14 | steps 1–8 easy/medium, 9–14 medium/hard |
| `poly-sample-upload/` | Add Samples editor upload through SysEx with verification/correction and mounted SD-card filesystem copy with remembered destination | 4 | steps 1–2 medium, 3–4 medium/hard |
| `split-stepper-control/` | Add a reusable compact split stepper and apply it to poly multisample sidebar jog controls | 3 | steps 1–3 easy/medium |
| `sample-row-steppers/` | Add compact inline Root/Low/High/Vel/RR steppers to poly multisample sample rows with focus sync and auto-preview | 2 | step 1 medium, step 2 medium/hard |
| `sample-sidebar-layout-stability/` | Stabilize poly multisample sample editor side-panel row geometry across mapping, loop/trim, fade, gain, and peak value changes | 2 | step 1 medium, step 2 medium |
| `keyboard-note-render-preview/` | Add rendered pitched WAV playback when tapping piano keys in the poly multisample sample editor | 5 | steps 1–2 medium, step 3 hard, steps 4–5 medium |
| `routing-bus-picker-selected-center/` | Center the current bus in the routing bus picker and show used buses in the bus-lanes picker | 2 | step 1 medium, step 2 medium |
| `improve-the-nt-helper-sample-editor-ux-based-on/` | Improve poly multisample sample editor UX with stable edit ordering, selection-scoped mapping/discard, bulk root/list controls, and loop/fade preview | 3 | steps 1–2 medium, step 3 hard |

## Target executor

Local ~27B instruct model (Qwen3.6-27B class). Temperature 0.2, top_p 0.9.
One step per fresh-context session. Context per step stays under ~16K tokens —
read only the files the step names.

### Prompt template (per step)

```text
SYSTEM:
You are a code-implementation executor working in the target repository.
You follow written plans exactly. You never redesign, rename, reorder, or
"improve" anything. When a plan and your instinct disagree, the plan wins.
When verification fails, you follow the plan's recovery rule; if still
failing after two attempts, you run `git checkout -- lib test` and report
FAILED with the error text.

USER:
Repository root: /Users/nealsanche/nosuch/nt_helper
Spec folder: specs/<SPEC_FOLDER>
Read these two files completely before doing anything:
  specs/conventions.md
  specs/<SPEC_FOLDER>/plan.md
That plan has <TOTAL_STEPS> steps. Execute STEP <N> of <TOTAL_STEPS>, alone.
Do not start any other step, and do not touch code that a different step names.
Completing this step does NOT complete the plan unless <N> = <TOTAL_STEPS>.
When done, run the verification commands from the step, then commit with the
exact message given in the step. Report: PASS or FAILED + output.
```

## Completion audit (run by the planning model, not the executor)

```bash
grep -A2 "Commit message" specs/<SPEC_FOLDER>/plan.md      # expected — one commit each
git log --format=%s <baseline>..HEAD                       # actual
```

Every expected message must appear exactly once. A missing message is a skipped
step; two steps' work under one message means the squashed step's verification
gates never ran — re-run them by hand. Finish with the program-level verification
command named by that spec's `plan.md`.
