# Improve the nt_helper sample editor UX based on colleague feedback

Baseline ref: `HEAD` (`5cd35577` at spec authoring time)

Hardening policy: realistic-only

Verification command hint: `flutter analyze && flutter test`

## Inventory summary

Inventory was generated with:

```bash
python3 /Users/nealsanche/nosuch/nt_helper/.pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/poly_multisample/poly_multisample_builder_cubit.dart \
  lib/ui/poly_multisample/poly_samples_editor_view.dart \
  lib/ui/poly_multisample/widgets/poly_sample_inspector.dart \
  lib/ui/poly_multisample/widgets/poly_sample_list.dart \
  lib/ui/poly_multisample/widgets/poly_waveform_editor.dart \
  lib/ui/poly_multisample/poly_region_math.dart \
  lib/poly_multisample/poly_multisample_models.dart \
  lib/poly_multisample/poly_audio_preview_service.dart \
  > /tmp/improve_sample_editor_inventory.md
```

Hand check completed for `lib/ui/poly_multisample/widgets/poly_sample_list.dart` and `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`: the inventory declaration tables match the current file structure around selection, row ordering, preview, and waveform preview helpers.

| File | Lines | Relevant declarations | Imported by |
|---|---:|---|---|
| `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | 2485 | `PolyMultisampleBuilderState`, `PolyMultisampleBuilderCubit`, mapping/preview helpers | multisample UI, dialogs, and tests |
| `lib/ui/poly_multisample/poly_samples_editor_view.dart` | 316 | `PolySamplesEditorView`, `_Toolbar`, `_EditorBody`, `_WarningPanel` | `poly_samples_screen.dart`, editor tests |
| `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | 1020 | `PolySampleInspector`, `_HeaderRow`, `_PreviewControls`, `_MappingSection`, `_WaveformSection`, `_FadeRow`, `_StepRow` | editor view and inspector tests |
| `lib/ui/poly_multisample/widgets/poly_sample_list.dart` | 448 | `PolySampleList`, `_PolySampleListState`, `_InlineSampleStepper` | editor view and sample-list tests |
| `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | 611 | `PolyWaveformEditor`, `_PolyWaveformPainter` | inspector and waveform-editor tests |
| `lib/ui/poly_multisample/poly_region_math.dart` | 105 | `effectiveLow`, `effectiveHigh`, `velocityLanes`, `selectedRegionFor`, `sampleDisplayLabel` | key map, sample list, inspector, tests |
| `lib/poly_multisample/poly_multisample_models.dart` | 324 | `PolySampleRegion`, `PolyWaveformDraft`, `PolyStagedImport` | parser, services, UI, tests |
| `lib/poly_multisample/poly_audio_preview_service.dart` | 211 | `PolyAudioPreviewService`, `PolyAudioPreviewState`, `PolyAudioPreviewSourcePlayback` | cubit, inspector, waveform editor, tests |

## Architecture

### Decided behavior

1. **Keep editor row order stable.** `editedRegions` preserves the existing row order during in-place edits. Source loaders may still sort imported input, but edit-time replacement never sorts again.
2. **Keep one cubit.** `PolyMultisampleBuilderCubit` remains the single source of truth for sample mapping, selection, warnings, and preview state. No new cubits, no strategy registry, no routing change.
3. **Selection-first destructive behavior.** When `state.selectedPaths` is non-empty, the primary destructive toolbar action operates only on the current selection. When no selection exists, the same control becomes an explicit bulk discard action with confirmation. `Clear all` remains a separate explicit action.
4. **Bulk mapping edits operate on the current selection.** The inspector mapping controls apply to all selected samples in one cubit emit when selection exists. Single-row steppers in the list still edit one row and focus that row.
5. **Root assignment uses a note menu.** Root note assignment in the inspector uses a fixed MIDI note list UI, not only +/- stepping. When selected values differ, the UI shows `Mixed`.
6. **Warnings are textual and visible.** Impossible ranges and overlapping mappings add visible warning strings to the existing warning panel. The list never resorts itself to hide the conflict.
7. **Waveform preview uses a cached rendered file.** Loop/fade preview renders the current trim/fade/loop draft into a temp WAV cache keyed by path, file stat, and preview draft fingerprint. Stale render completions are ignored.
8. **Fade curves are previewed visually and audibly.** `PolyWaveformEditor` draws fade overlays from the current draft values, and the cached preview render uses the same trim/fade/loop data.
9. **No search, no zoom, no new screen.** The root note picker is fixed to the MIDI note list; waveform zoom stays out of scope; the sample editor remains in its current navigation flow.

### Decision inventory

| Decision | Rationale | Files affected | Status |
|---|---|---|---|
| Preserve `editedRegions` order on edit | Prevents the active row from jumping during mapping changes | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`, editor/view tests | required |
| Append overlap/impossible mapping warnings instead of resorting | Colleagues need a clear warning when a mapping becomes confusing or impossible | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`, `poly_samples_editor_view.dart`, cubit/editor tests | required |
| Keep destructive behavior selection-first | Users should unmap only the current selection unless they intentionally use the bulk wipe action | `lib/ui/poly_multisample/poly_samples_editor_view.dart`, cubit tests, editor tests | required |
| Add a selection-wide mapping update path in the cubit | Bulk root/velocity/RR edits must apply in one emit and keep focus stable | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`, `poly_sample_inspector.dart`, inspector tests | required |
| Put root assignment in the inspector mapping panel | A note menu is the requested list/UI path and keeps rows compact | `lib/ui/poly_multisample/poly_sample_inspector.dart`, inspector tests | required |
| Show `Mixed` for non-uniform multi-selection values | Avoids lying about the active root/value when multiple samples differ | `lib/ui/poly_multisample/poly_sample_inspector.dart`, inspector tests | required |
| Cache waveform preview renders by path + draft fingerprint | Rapid loop/fade edits are an async file-system race path; cache reuse keeps preview stable | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart`, waveform/inspector tests | required |
| Draw fade overlays in `PolyWaveformEditor` | The waveform preview must show the fade shape the user is editing | `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart`, waveform-editor tests | required |
| Reuse existing warning panel and snackbar behavior | The app already has a warning disclosure and error snackbars; no success snackbars are added | `lib/ui/poly_multisample/poly_samples_editor_view.dart`, existing listener code | required |
| No new files or new cubit layers | The request fits the existing sample-editor topology and should stay in-place | all touched sample-editor files | required |
| No waveform zoom | The current editor intentionally stays fixed-scale | `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | out-of-scope |
| No navigation or screen rewrite | The request is UX refinement, not a route re-architecture | `lib/ui/poly_multisample/poly_samples_screen.dart`, `poly_samples_editor_view.dart` | out-of-scope |

### Hardening matrix

| Risk | Plausible path | Chosen handling | Tests required |
|---|---|---|---|
| Row order jumps while the user edits a root or velocity field | A selected row changes enough to move under the current sort order | Stop sorting in edit-time replacement; keep the existing order and warn on overlaps/impossible spans | `poly_multisample_builder_cubit_test.dart` order test; editor warning-panel test |
| A user unmaps more than intended | The destructive button is pressed while multiple rows are selected | Primary action operates only on the selection; bulk discard stays behind explicit confirmation and `Clear all` stays separate | `poly_samples_editor_view_test.dart` destructive-action tests |
| Multi-select mapping updates only change one row or lose focus | The root menu or stepper is used with several rows selected | The cubit applies the change to every selected path in one emit and preserves the focused path when it remains selected | `poly_multisample_builder_cubit_test.dart` bulk-update test; `poly_sample_inspector_test.dart` multi-select test |
| A slower preview render completes after a newer fade or loop change | User drags loop/fade controls quickly and async file IO finishes out of order | Preview renders are keyed by a fingerprint and guarded by a request token; stale outputs are discarded | `poly_multisample_builder_cubit_test.dart` preview-cache race test |
| Fade controls update the UI but not the heard audio | A waveform fade curve changes while the preview file stays stale | The cached preview render uses the same trim/fade/loop draft values passed to save and the waveform overlay | `poly_waveform_editor_test.dart`; `poly_sample_inspector_test.dart` preview test |

## Target file tree

```
lib/ui/poly_multisample/
  poly_multisample_builder_cubit.dart      (edit)
  poly_samples_editor_view.dart            (edit)
  widgets/poly_sample_inspector.dart       (edit)
  widgets/poly_waveform_editor.dart        (edit)

lib/ui/poly_multisample/
  poly_region_math.dart                    (edit)

test/poly_multisample/
  poly_multisample_builder_cubit_test.dart (edit)
  poly_samples_editor_view_test.dart       (edit)
  widgets/poly_sample_inspector_test.dart  (edit)
  widgets/poly_waveform_editor_test.dart   (edit)

specs/
  README.md                                (edit)
  improve-the-nt-helper-sample-editor-ux-based-on/
    spec.md                                (new)
    plan.md                                (new)
```

## Symbol map

| Symbol | Destination | Exported | Notes |
|---|---|---|---|
| `PolyMultisampleBuilderCubit.updateSelectedMappings` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | yes | New selection-wide mapping path for root/low/high/velocity/RR edits |
| `mappingWarnings` | `lib/ui/poly_multisample/poly_region_math.dart` | yes | Public pure helper reused by the cubit and warning tests |
| `PolyMultisampleBuilderCubit._scheduleWaveformEditPreview` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Debounced preview entry point for loop/fade edits |
| `PolyMultisampleBuilderCubit._playWaveformEditPreview` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Cached temp-file renderer for waveform preview |
| `PolyMultisampleBuilderCubit._cachedWaveformPreviewPath` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Cache lookup keyed by path, stat, and preview draft fingerprint |
| `PolyMultisampleBuilderCubit._waveformPreviewCache` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Temp-file cache for loop/fade preview renders |
| `PolyMultisampleBuilderCubit._waveformPreviewRenderInFlight` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Collapses concurrent renders for the same preview fingerprint |
| `PolyMultisampleBuilderCubit._waveformPreviewRoots` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Tracks waveform preview temp roots for cleanup |
| `PolyMultisampleBuilderCubit._cleanupWaveformPreviewRoots` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Deletes cached preview temp roots on discard/close |
| `PolyMultisampleBuilderCubit._replaceEditedRegions` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Preserves edit order, keeps selection/focus, prunes preview cache state |
| `PolyMultisampleBuilderCubit._setInstrument` | `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` | no | Combines source warnings with mapping warnings on load |
| `PolySampleInspector._MappingSection.build` | `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` | no | Root menu plus selection-wide mapping controls |
| `PolySamplesEditorView._Toolbar.build` | `lib/ui/poly_multisample/poly_samples_editor_view.dart` | no | Selection-first destructive button and explicit bulk confirmation |
| `PolyWaveformEditor` | `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | yes | Constructor gains optional fade overlay inputs |
| `_PolyWaveformPainter.paint` | `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` | no | Paints fade envelopes on the preview waveform |

## Dependency notes

- `lib/ui/poly_multisample/widgets/poly_sample_inspector.dart` keeps package imports for `package:nt_helper/ui/poly_multisample/poly_multisample_builder_cubit.dart`, `package:nt_helper/ui/poly_multisample/poly_region_math.dart`, `package:nt_helper/ui/poly_multisample/widgets/poly_waveform_editor.dart`, and `package:nt_helper/poly_multisample/poly_multisample_parser.dart`.
- `lib/ui/poly_multisample/widgets/poly_waveform_editor.dart` keeps `package:nt_helper/poly_multisample/poly_audio_preview_service.dart` and `package:nt_helper/poly_multisample/wav_metadata.dart`.
- `lib/ui/poly_multisample/poly_multisample_builder_cubit.dart` keeps `package:nt_helper/poly_multisample/poly_audio_preview_service.dart`, `package:nt_helper/poly_multisample/wav_metadata.dart`, `package:nt_helper/ui/poly_multisample/poly_region_math.dart`, and `package:path/path.dart` as p.
- No compatibility re-export is needed because no public symbol moves to a different file.

## Acceptance criteria

1. Editing any sample’s root, low, high, velocity, or RR does not reorder the visible sample list.
2. Creating an overlapping or impossible mapping shows a visible warning and keeps the row order stable.
3. Root note can be assigned from a note list UI for one sample or a multi-selection.
4. Mapping controls apply to all selected samples together when a selection exists.
5. The primary destructive toolbar action only unmaps the current selection when rows are selected; full discard/clear remains explicit.
6. The waveform editor shows fade curves, and preview audio follows the same trim/fade/loop draft used for save.
7. `flutter analyze` passes and `flutter test` passes after the plan completes.
