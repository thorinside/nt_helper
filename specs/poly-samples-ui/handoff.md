# Poly Samples UI inventory and handoff

Audit date: 2026-07-05

This document sits beside `spec.md` and `plan.md` because those files are no
longer just proposed instructions. The 14-step program has been executed and
committed on `main`; this file records what is complete, what has drifted, and
what a follow-up executor should do next.

## Current status

The original decision-free program is complete as a historical execution plan.
The expected step commits are present in order:

| Step | Commit message |
|---|---|
| 1 | `feat(poly): add fade curve and strength to PolyWaveformDraft` |
| 2 | `feat(poly): remember sample folders via PolySamplePreferencesService` |
| 3 | `feat(poly): adopt and merge staged imports in builder cubit` |
| 4 | `refactor(poly): extract shared region math helpers` |
| 5 | `feat(poly): expose full Decent Sampler options in import cubit` |
| 6 | `feat(poly): add PolyKeyMap keyboard map widget` |
| 7 | `feat(poly): add PolySampleList widget` |
| 8 | `feat(poly): add PolySampleInspector with mapping and loop sections` |
| 9 | `feat(poly): add waveform editor and destructive edit section` |
| 10 | `feat(poly): add loose WAV import dialog` |
| 11 | `feat(poly): add Decent Sampler import dialog` |
| 12 | `feat(poly): add samples landing and editor views` |
| 13 | `feat(poly): add standalone PolySamplesScreen` |
| 14 | `feat(poly)!: move Samples to a standalone screen and drop EditMode.samples` |

Do not rerun `plan.md` mechanically against the current tree. It was written
for a clean baseline before these commits existed.

## Inventory

Program files:

- `specs/poly-samples-ui/spec.md`: architecture, target UI, widget/cubit
  contracts, negative decisions, compatibility notes, acceptance criteria.
- `specs/poly-samples-ui/plan.md`: 14 one-commit steps with named files,
  named tests, and commit messages.
- `specs/README.md`: executor prompt, completion audit, program table.
- `specs/conventions.md`: repo-wide executor rules, formatting/analyze/test
  gates, import table, recovery rules.

Implemented UI surface:

- `lib/ui/poly_multisample/poly_samples_screen.dart`
- `lib/ui/poly_multisample/poly_samples_landing_view.dart`
- `lib/ui/poly_multisample/poly_samples_editor_view.dart`
- `lib/ui/poly_multisample/widgets/poly_key_map.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_list.dart`
- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart`
- `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart`
- `lib/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart`
- `lib/ui/poly_multisample/dialogs/poly_decent_import_dialog.dart`

Implemented state/support surface:

- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`
- `lib/ui/poly_multisample/poly_decent_import_cubit.dart`
- `lib/ui/poly_multisample/poly_loose_wav_import_cubit.dart`
- `lib/ui/poly_multisample/poly_region_math.dart`
- `lib/poly_multisample/decent_sampler_converter.dart`

Primary tests:

- `test/poly_multisample/poly_multisample_builder_cubit_test.dart`
- `test/poly_multisample/poly_decent_import_cubit_test.dart`
- `test/poly_multisample/poly_region_math_test.dart`
- `test/poly_multisample/poly_samples_screen_test.dart`
- `test/poly_multisample/poly_samples_editor_view_test.dart`
- `test/poly_multisample/widgets/poly_key_map_test.dart`
- `test/poly_multisample/widgets/poly_sample_list_test.dart`
- `test/poly_multisample/widgets/poly_sample_inspector_test.dart`
- `test/poly_multisample/widgets/poly_waveform_editor_test.dart`
- `test/poly_multisample/dialogs/poly_loose_wav_import_dialog_test.dart`
- `test/poly_multisample/dialogs/poly_decent_import_dialog_test.dart`
- `test/ui/synchronized_screen_bottom_bar_test.dart`

## What is validated

The plan is complete for the original standalone Samples-screen conversion:

- It fixed the broken `EditMode.samples` navigation model by moving Samples
  to a pushed desktop-only screen.
- It accounts for the fork UI features through progressive disclosure:
  landing, keyboard map, sample list, inspector, loop metadata, destructive WAV
  editing, loose WAV import, Decent Sampler import, and hardware/local sources.
- It specifies exact file paths, signatures, UI labels, tests, verification
  commands, and commit messages.
- It keeps cubit/model work before widget work, so the tree could stay green
  between steps.
- It includes accessibility requirements for headers, live regions, tooltips,
  semantic labels, selected list rows, and progress states.

## Drift from the original spec

The current implementation has intentionally moved beyond `spec.md` and
`plan.md` in several places:

- The old `PolyMultisampleBuilderScreen` and its test are already deleted.
  Any plan step that says to copy from them is stale.
- `synchronized_screen.dart` has already removed `EditMode.samples`; the
  Samples quick action now pushes `PolySamplesScreen`.
- `poly_region_math.dart` has grown beyond the original five-helper shape.
  The current `sampleDisplayLabel` helper supports clearer duplicate sample
  labels and should be kept.
- `selectedRegionFor` no longer falls back to the first sample when there is no
  selected/focused path. Current tests expect `null`.
- Waveform editing now combines trim and loop interaction in one chart,
  including modifier/secondary-click loop-point editing.
- Save As handling now includes folder creation behavior.
- Async source loading has stale-operation guards for local and hardware loads.
- Preview behavior has been hardened for removal, clearing, non-WAV samples,
  same-path apply, and hardware preview caching.
- Decent import tag mapping now distinguishes edited tag ranges from default
  ranges, so default tag ranges are not accidentally forwarded.
- Explicit singleton velocity/round-robin markers can be preserved in exported
  Decent-derived filenames.
- Some user-visible labels differ from the original text, notably
  `Save as...` in the inspector versus `Save As...` in the editor toolbar.

## Open handoff items

These are the remaining items a follow-up executor should consider before
calling the current UI done:

1. Decent import staging controls are still the most concrete open issue.
   `Cancel` and `Import` are disabled during staging, but presets, group
   handling, switches, tag rows, and steppers can still mutate visible state
   while the staged conversion is already using the pre-click options.
2. Add a Decent dialog test that starts delayed staging, taps Import, attempts
   to mutate options, and proves those controls are disabled or ignored until
   staging completes.
3. Add Decent dialog tests for successful staging pop/return value, blocked
   route dismissal while staging, and disabled preview for non-WAV or missing
   preview source paths.
4. Add callback-level landing tests for NT Hardware, Local Folder, Import
   Files, Recent, and Start empty draft. Current coverage is mostly render
   coverage.
5. Add direct inspector widget coverage for the preview button, auto-preview
   switch, and preview gain control. Cubit behavior is covered, but the
   inspector wiring should be explicit.
6. Add a small systematic semantics checklist per major widget, especially for
   icon-only controls, section headers, selected state, live progress/error
   regions, and disabled-state text.
7. Run manual macOS validation with real local samples and, when available,
   hardware-origin samples. The automated tests cover many regressions, but
   hardware preview and mounted-folder behavior need real-device proof.

## Verification commands

For a continuation patch, use the repo gates, not the original 14-step audit:

```bash
dart format lib/ui/poly_multisample lib/poly_multisample test/poly_multisample test/ui
flutter analyze
flutter test test/poly_multisample test/ui/synchronized_screen_bottom_bar_test.dart
```

For a Decent-staging-only fix, the tight loop is:

```bash
flutter test test/poly_multisample/dialogs/poly_decent_import_dialog_test.dart
flutter test test/poly_multisample/poly_decent_import_cubit_test.dart
flutter analyze
```

## Executor guidance

Use `spec.md` as architecture history and `plan.md` as proof of how the
standalone screen was built. Do not use them as current step-by-step
instructions without first amending the drift above.

The safest next handoff is a small bug-fix spec or direct patch for Decent
staging immutability, followed by the focused dialog tests and the full Poly
Multisample test gate.
