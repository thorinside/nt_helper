# Forge split-run experiment

These files split `../plan.md` into one verbatim file per step:

- `step-01.md`
- `step-02.md`
- `step-03.md`
- `step-04.md`
- `step-05.md`
- `step-06.md`
- `step-07.md`
- `step-08.md`
- `step-09.md`
- `step-10.md`
- `step-11.md`
- `step-12.md`
- `step-13.md`
- `step-14.md`

The step files are intentionally verbatim slices from `../plan.md`. Do not edit
their bodies when comparing execution quality. Put orchestration changes in
this README or in the Forge workflow definition instead.

## Experiment shape

Use one clean experiment worktree rooted at the original pre-plan baseline:

```bash
git worktree add ../nt_helper-poly-forge-qwen36 d5c6ad03
cd ../nt_helper-poly-forge-qwen36
git switch -c forge/poly-samples-ui-qwen36
```

Then make the specs available in that worktree before launching Forge. The
baseline commit predates the `specs/` directory, so bring in only docs/spec
files, not the implementation commits:

```bash
git checkout main -- specs/conventions.md specs/poly-samples-ui/spec.md specs/poly-samples-ui/forge-steps
git add specs
git commit -m "docs(poly): add split Forge step specs"
```

Run the 14 Forge jobs sequentially in that worktree. Job `N + 1` starts only
after job `N` finishes, passes verification, and creates the exact commit named
inside `step-NN.md`.

Each Forge job should use:

- Model: `qwen3.6`
- Worktree: `/Users/nealsanche/nosuch/nt_helper-poly-forge-qwen36`
- One step file only: `specs/poly-samples-ui/forge-steps/step-NN.md`
- Shared architecture file: `specs/poly-samples-ui/spec.md`
- Shared conventions file: `specs/conventions.md`

## Per-job prompt template

```text
Repository root: /Users/nealsanche/nosuch/nt_helper-poly-forge-qwen36
Model: qwen3.6

Read these files completely before doing anything:
  specs/conventions.md
  specs/poly-samples-ui/spec.md
  specs/poly-samples-ui/forge-steps/step-NN.md

Execute only the step described in step-NN.md.

Do not read or execute the other step files.
Do not start the next step.
Do not touch files outside the step's named file list.
Follow the labels, signatures, widget trees, tests, verification commands, and
commit message exactly.

When done, run the verification commands required by the step and
specs/conventions.md, then commit with the exact commit message named in
step-NN.md.

Report PASS or FAILED plus the relevant verification output.
```

## Final comparison

After all 14 jobs pass, compare the experiment branch with the Codex branch:

```bash
git log --format=%s d5c6ad03..forge/poly-samples-ui-qwen36
git diff --stat main..forge/poly-samples-ui-qwen36
git diff main..forge/poly-samples-ui-qwen36 -- lib/poly_multisample lib/ui/poly_multisample test/poly_multisample test/ui/synchronized_screen_bottom_bar_test.dart
flutter analyze
flutter test test/poly_multisample test/ui/synchronized_screen_bottom_bar_test.dart
```

The useful signal is not only whether Forge reaches green. The useful signal is
whether the split-step qwen3.6 run stays closer to the written plan, produces
less UI invention, and leaves fewer follow-up bug-fix patches than the large
single-context execution.
