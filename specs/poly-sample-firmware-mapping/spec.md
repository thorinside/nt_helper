# Poly sample firmware mapping parity

## Request

Make the Samples editor model and display the Disting NT's documented sample
mapping behavior instead of treating every filename without an explicit natural
note as unmapped and deriving ranges by simply extending each root to the next
root.

The completed feature must cover all of these surfaces with one mapping result:

- automatic natural notes for rootless sample families;
- contextual automatic switch (Low) calculation;
- derived High calculation;
- keyboard-map geometry, selection, and accessibility;
- local and mounted WAV keyboard preview pitch selection;
- list, inspector, toolbar counts, warnings, and build reports;
- persistable editing semantics (`_SW` is Low; High is derived);
- import, apply, and upload terminology and filename behavior.

## Official authority and exact interpretation

Primary authority:

- [Disting NT User Manual v1.17, pages 26-27](https://www.expert-sleepers.co.uk/downloads/manuals/disting_NT_user_manual_1.17.pdf)
  - PDF SHA-256 at planning time:
    `3eb574635a1105e5b8e4fc0352e2bf02e83e870b5cca086cd35a65e94e2ca875`.
  - Page 26 defines filename naturals, `_SW`, `_V`, `_RR`, automatic naturals
    from MIDI 48, and the contextual switch rule.
  - Page 27 gives the switch allocation table for gaps 1-6.
- [Disting NT firmware/manual index](https://www.expert-sleepers.co.uk/distingNTfirmwareupdates.html)
  identifies v1.17.0, released 1 July 2026, as the current firmware/manual used
  by this spec.

Endpoint/order evidence used only where the NT manual is silent:

- [Disting mk4 User Manual v4.28](https://www.expert-sleepers.co.uk/downloads/manuals/disting_user_manual_4.28.pdf)
  documents alphabetical file order without playlists, inclusive switch
  points, and the final sample continuing upward. This spec records the
  endpoint/order choices below explicitly; the executor must not reinterpret
  them as additional verbatim claims from the NT v1.17 manual.

### Vocabulary

- **Raw natural**: `PolySampleRegion.rootMidi`, parsed from a filename note
  token. Null means the firmware will assign a natural; it does not mean the
  sample is unmapped.
- **Resolved natural**: the raw natural or the automatic natural assigned by
  the resolver.
- **Explicit Low**: `PolySampleRegion.switchPoint`, parsed from `_SW<number>`.
- **Automatic Low**: the contextual switch calculated from neighbouring
  resolved naturals.
- **Resolved High**: one less than the next higher natural group's minimum
  resolved Low, or MIDI 127 for the final group.
- **Rootless family**: files linked as variants after `_V<number>` and
  `_RR<number>` are removed from the relative filename stem.

### Contextual switch formula

For adjacent distinct resolved naturals `L < H`, define:

```text
gap = H - L - 1
```

`gap` is the number of MIDI pitches strictly between the two recorded natural
notes. The manual's allocation table is interpreted using this value; this is
the only interpretation that preserves both samples' natural notes without an
overlap.

The automatic Low for the higher natural is:

```dart
final gap = higherNatural - lowerNatural - 1;
return lowerNatural + math.max(1, gap ~/ 2);
```

The adjacent-note case (`gap == 0`) therefore returns `higherNatural`.

| Intervening gap | Example higher natural for L=60 | Higher Low | Lower High | Manual allocation |
|---:|---:|---:|---:|---|
| 0 | 61 | 61 | 60 | adjacent notes |
| 1 | 62 | 61 | 60 | higher down 1 |
| 2 | 63 | 61 | 60 | higher down 2 |
| 3 | 64 | 61 | 60 | higher down 3 |
| 4 | 65 | 62 | 61 | higher down 3, lower up 1 |
| 5 | 66 | 62 | 61 | higher down 4, lower up 1 |
| 6 | 67 | 63 | 62 | higher down 4, lower up 2 |

Endpoint decisions, made here because the NT v1.17 text documents only
neighbouring switches:

- The first natural group has automatic Low `0`.
- An explicit `_SW` on the first group overrides `0` and leaves lower pitches
  uncovered.
- The final natural group has High `127`.
- Explicit `_SW` always wins, even when malformed data creates a gap, overlap,
  or a natural outside its resolved range. Parsed `_SW` values are preserved
  exactly, including values outside 0-127, so apply/upload can round-trip the
  raw filename. The resolver reports an out-of-range switch and never clamps
  or silently repairs it. Editor-created switch values are still clamped to
  0-127 at the Cubit boundary.

### EVOS regression fixture

For EVOS naturals `12, 19, 26, 33, 40, 47, 54, 61, 68, 75`, every adjacent
pair has six intervening pitches. The required resolved values are:

```text
Lows:  0, 15, 22, 29, 36, 43, 50, 57, 64, 71
Highs: 14, 21, 28, 35, 42, 49, 56, 63, 70, 127
```

The A1 sample (`33`) therefore displays Root `A1`, Low `F1` (`29`), High `B1`
(`35`). The following E2 sample starts at C2 (`36`). This exact vector is an
acceptance test; the old A1/D#2 range must never return.

## Inventory-first evidence

The Dart inventory was generated before reading implementation blocks:

```bash
python3 .agents/skills/decision-free-specs/languages/dart/inventory.py \
  lib/poly_multisample/poly_multisample_models.dart \
  lib/poly_multisample/poly_multisample_parser.dart \
  lib/poly_multisample/poly_sample_import_service.dart \
  lib/poly_multisample/poly_sample_apply_service.dart \
  lib/poly_multisample/poly_sample_upload_service.dart \
  lib/ui/poly_multisample/poly_multisample_builder_cubit.dart \
  lib/ui/poly_multisample/poly_region_math.dart \
  lib/ui/poly_multisample/poly_samples_editor_view.dart \
  lib/ui/poly_multisample/widgets/poly_key_map.dart \
  lib/ui/poly_multisample/widgets/poly_sample_list.dart \
  lib/ui/poly_multisample/widgets/poly_sample_inspector.dart \
  lib/ui/poly_multisample/dialogs/poly_loose_wav_import_dialog.dart \
  lib/debug_poly_sample_upload_command.dart
```

Tests were inventoried with the same tool for every file named in the target
tree below.

| File | Lines at planning time | Relevant declarations/consumers |
|---|---:|---|
| `poly_multisample_models.dart` | 324 | `PolySampleIssue`, `PolySampleRegion`, `PolySampleInstrument`, loose mapping enum/options; imported across every sample service/widget/test |
| `poly_multisample_parser.dart` | 160 | `PolyMultisampleParser`, raw filename parsing and `sortRegions`; imported by services, widgets, and tests |
| `poly_sample_import_service.dart` | 178 | loose-file/folder staging and `_applyLooseMapping` |
| `poly_sample_apply_service.dart` | 287 | filename serialization in `buildTargetFileName` |
| `poly_sample_upload_service.dart` | 746 | delegates target naming to apply service |
| `poly_multisample_builder_cubit.dart` | 2860 | state, mapping mutations, warnings, note preview, build report |
| `poly_region_math.dart` | 187 | three UI helpers plus duplicated mapping math/warnings |
| `poly_samples_editor_view.dart` | 484 | toolbar counts/actions and widget composition |
| `poly_key_map.dart` | 845 | geometry, hit testing, painter, semantic targets |
| `poly_sample_list.dart` | 448 | row values, steppers, warnings, row semantics |
| `poly_sample_inspector.dart` | 1257 | bulk/single mapping display and controls |
| loose WAV import dialog | 231 | false `Leave unmapped` label |
| debug upload command | 332 | false context-free mapping warning count |

Hand spot-check: the inventory scanner omitted the record-return function
`midiExtents` from `poly_region_math.dart` and rendered generic
`_selectionValue` as `Function`. Both symbols are included explicitly in this
spec. There are no `part`, code-generation, or barrel-export traps in the
target files.

### Proven duplicate/serialization traps

1. `poly_region_math.dart` has `effectiveLow`/`effectiveHigh`, and
   `mappingWarnings` contains a second `lowFor`/`highFor` implementation with
   different RR filtering.
2. The Cubit has a third copy in `_notePreviewEffectiveLow` and
   `_notePreviewEffectiveHigh`, plus raw-root filters and pitch calculations.
3. `rangeLow` and `rangeHigh` are written only by the editor/Cubit. The parser
   never reads them and apply/upload filename serialization never writes them.
4. Firmware filenames support `_SW` (Low), but no independent High tag.
   Retaining editable `rangeHigh` would leave a display-only edit that vanishes
   after apply/rescan. This program removes that false contract.

## Architectural decisions

| Decision | Rationale | Status |
|---|---|---|
| Add a pure domain resolver in `lib/poly_multisample/poly_sample_mapping_resolver.dart`. | Firmware mapping needs the whole sample set; context-free region getters cannot be correct. | required |
| Store one immutable `PolySampleMappingResolution` in `PolyMultisampleBuilderState`. | UI displays state, Cubit decides/coordinates, services do work, state remembers results. It also avoids O(n^2) recomputation in rows and paint paths. | required |
| Resolve once in `_setInstrument` and `_replaceEditedRegions`; explicitly clear the resolution wherever edited regions are cleared. | These are the normal state choke points and prevent stale mapping state. | required |
| Keep raw regions raw. Never copy automatic natural/Low/High values into `PolySampleRegion`. | Writing derived C3 into a rootless filename changes firmware behavior and destroys automatic mapping. | required |
| Pitch-neighbour calculation is global across distinct naturals; V/RR variants do not create separate neighbour sequences. | `_V` and `_RR` choose variants after pitch-group selection. This makes incomplete variant matrices share the same keyboard boundaries. | required |
| Rootless variants share a family after only `_Vn` and `_RRn` tokens are stripped. `_SWn` remains in the family stem. | V/RR link variants; SW controls a boundary and must not silently link otherwise different files. | required |
| Rootless families are sorted by case-folded normalized relative family path, then exact normalized path, independent of resolver input order. | The NT manual does not specify filesystem enumeration order; this deterministic rule follows Expert Sleepers' inherited alphabetical behavior. | required |
| Explicit-root families do not consume automatic ordinals. Rootless ordinals start at MIDI 48 even when an explicit sample already uses 48. | Mixed folders are undocumented. Literal automatic numbering is preserved and collisions are reported rather than skipped. | required |
| Automatic family ordinals above MIDI 127 remain unresolved and produce an issue. They are never clamped together at 127. | The manual allows far more files than available MIDI notes but does not define overflow; saturation would create silent false mappings. | required |
| Low edits write `switchPoint`; High is read-only and derived. Remove `rangeLow`/`rangeHigh`. | This is the only mapping contract that apply/upload can persist as firmware filenames. | required |
| `resetSelectedToAutomaticNotes` clears raw root and switch only, preserving velocity and RR. | Resetting pitch defaults must not destroy variant relationships. | required |
| Mapping problems are structured domain issues; UI code turns them into user strings. | The debug command and Cubit need consistent counts without importing UI formatting into domain code. | required |
| No Strategy registry. | There is one firmware mapping algorithm, not behavioural variance. | out-of-scope |
| Do not merge Decent Sampler XML range analysis into this resolver. | Decent conversion translates explicit source ranges into Disting filenames; it is not firmware fallback calculation. | out-of-scope |
| Do not change SysEx transport, upload chunking, waveform editing, or Decent selection policy. | Those are separate concerns and existing protocols remain authoritative. | out-of-scope |

## Deterministic resolver contract

### Rootless family key

For every supported region whose raw `rootMidi` is null:

1. Replace `\` with `/` in `displayName`.
2. Keep the normalized relative parent directory.
3. Remove the extension from the basename.
4. Remove every underscore-delimited token matching
   `_(?:V|RR)\d+(?=_|$)`, case-insensitively.
5. Trim trailing `_`, `-`, and whitespace. When stripping leaves an empty
   stem, use the original stem.
6. Join parent and stripped stem with POSIX `/`.
7. Use the lowercased result for family equality/primary ordering and the
   exact normalized result as the tie-breaker.

Examples:

| Input relative name | Family key before case fold |
|---|---|
| `Drums/Snare_V1_RR1.wav` | `Drums/Snare` |
| `Drums/Snare_V2_RR2.wav` | `Drums/Snare` |
| `Drums/Snare_SW40_V1_RR1.wav` | `Drums/Snare_SW40` |
| `Other/Snare_V1.wav` | `Other/Snare` |

`_SW40` is intentionally preserved. Distinct parent paths are intentionally
distinct families.

### Resolution procedure

The executor implements these phases in this exact order:

1. Reject duplicate region paths with
   `ArgumentError('Duplicate poly sample path: <path>')`. Paths are the
   repository's region identity; never silently overwrite a by-path entry.
2. Ignore unsupported audio regions; their existing unsupported-file issue
   remains a raw-file issue.
3. Build and sort unique rootless family keys. Assign each family
   `naturalMidi = 48 + ordinal`; do not skip explicit occupied notes.
4. Use raw `rootMidi` for explicit regions and the family value for rootless
   regions. Naturals outside 0-127 receive no Low/High and are not playable.
5. Across all in-range mappings, sort distinct natural values globally.
6. Compute the automatic Low for each distinct natural: first Low 0; later
   Low from `automaticSwitchPoint(lowerNatural, higherNatural)`.
7. Each region's resolved Low is raw `switchPoint` when present, otherwise
   the natural group's automatic Low. Preserve a parsed explicit value
   exactly; do not clamp it in the resolver.
8. For each natural except the final natural, take the minimum resolved Low
   among mappings at the next higher natural. Current mappings get
   `highMidi = nextMinimumLow - 1`. The final natural gets High 127.
9. Do not raise a derived High to the current Low. Preserve `low > high` so an
   impossible mapping becomes an issue instead of being hidden.
10. Build structured issues in the complete stable order defined below.

### Issue rules

`PolySampleMappingResolution.issues` contains:

- `naturalOutOfMidiRange` for explicit or automatic naturals outside 0-127;
- `switchOutOfMidiRange` for an explicit `switchPoint` outside 0-127;
- `impossibleRange` when resolved Low is above resolved High;
- `naturalOutsideRange` when an in-range natural is outside its Low/High;
- `variantSwitchMismatch` when two mappings at the same natural have different
  resolved Low values;
- `overlappingRange` when two playable mappings overlap and have the same
  effective velocity (`velocityLayer ?? 1`) and RR (`roundRobin ?? 1`).

Different RRs and different velocity layers may intentionally cover the same
pitch range and do not create `overlappingRange` issues.

Issue ordering is exact:

1. Walk mappings in source-list order. For each mapping append applicable
   single-mapping issues in this order:
   `naturalOutOfMidiRange`, `switchOutOfMidiRange`, `impossibleRange`, then
   `naturalOutsideRange`.
2. Append `variantSwitchMismatch` issues for source-index pairs `(i, j)` in
   lexicographic order with `i < j`.
3. Append `overlappingRange` issues for source-index pairs `(i, j)` in
   lexicographic order with `i < j`.

Each pair produces one issue whose `mapping` is index `i` and `other` is
index `j`. `issuesForPath(path)` returns pair issues for either participant,
so both rows show their warning state without duplicating the global message.

`mappingWarningMessages` formats issues exactly:

| Kind | Message |
|---|---|
| `naturalOutOfMidiRange` | `Mapping impossible: <displayName> natural MIDI <n> is outside 0-127.` |
| `switchOutOfMidiRange` | `Mapping impossible: <displayName> Low MIDI <n> is outside 0-127.` |
| `impossibleRange` | `Mapping impossible: <displayName> has low <note> above high <note>.` |
| `naturalOutsideRange` | `Mapping impossible: <displayName> natural <note> is outside <low> to <high>.` |
| `variantSwitchMismatch` | `Mapping mismatch: <displayName> and <otherDisplayName> share natural <note> but use different Low values.` |
| `overlappingRange` | `Mapping overlap: <displayName> overlaps <otherDisplayName> on velocity <v>, RR <rr>.` |

For every `<note>` placeholder, `_noteLabel` returns
`PolyMultisampleParser.midiToNoteName(value)` for 0-127 and `MIDI <value>`
outside that range. This keeps malformed derived High values such as -1
readable without passing them to the note-name formatter.

`mappingWarningMessages(regions, resolution)` prepends raw-region messages in
source-list order, then appends the resolver issues in the order above. The
only remaining raw issue is `unsupportedFileType`, formatted exactly as
`Unsupported sample: <displayName> has an unsupported file type.` The toolbar
and debug command use the resulting list length, so unsupported files are not
lost when context-free instrument warning getters are removed.

## Target file tree

```text
lib/poly_multisample/
  poly_sample_mapping_resolver.dart          (NEW)
  poly_multisample_models.dart               (remove false range/missing-root contract)
  poly_multisample_parser.dart               (raw parse remains; resolved sort)
  poly_sample_import_service.dart            (automatic mode semantics)

lib/ui/poly_multisample/
  poly_multisample_builder_cubit.dart         (store resolution; preview/edit/report)
  poly_region_math.dart                       (selection/display + issue formatting only)
  poly_samples_editor_view.dart               (resolved counts/actions/composition)
  widgets/poly_key_map.dart                   (resolved geometry/a11y)
  widgets/poly_sample_list.dart               (resolved row/a11y; High read-only)
  widgets/poly_sample_inspector.dart          (resolved bulk UI; High read-only)
  dialogs/poly_loose_wav_import_dialog.dart   (automatic terminology)

lib/
  debug_poly_sample_upload_command.dart       (resolved issue count)

test/poly_multisample/
  poly_sample_mapping_resolver_test.dart      (NEW)
  poly_multisample_parser_test.dart
  poly_sample_import_service_test.dart
  poly_multisample_builder_cubit_test.dart
  poly_region_math_test.dart
  poly_sample_apply_service_test.dart
  poly_sample_upload_service_test.dart
  poly_samples_editor_view_test.dart
  poly_samples_screen_test.dart
  dialogs/poly_loose_wav_import_dialog_test.dart
  widgets/poly_key_map_test.dart
  widgets/poly_sample_list_test.dart
  widgets/poly_sample_inspector_test.dart
```

## Exhaustive mapping symbol map

| Symbol | Kind | Destination | Exported | Final disposition |
|---|---|---|---|---|
| `PolySampleMappingIssueKind` | enum | NEW resolver file | yes | six values from Issue rules |
| `PolySampleMappingIssue` | immutable class | NEW resolver file | yes | structured issue with `kind`, `mapping`, optional `other` |
| `PolySampleResolvedMapping` | immutable class | NEW resolver file | yes | raw region plus resolved natural/Low/High and automatic flags |
| `PolySampleMappingResolution` | immutable class | NEW resolver file | yes | mappings/byPath/issues plus lookups/count/extents/lanes |
| `PolySampleMappingResolver` | pure class | NEW resolver file | yes | `const` constructor, `resolve`, static switch formula |
| `PolySampleIssue.missingRootNote` | enum value | models | yes | remove; supported rootless audio is valid |
| `PolySampleRegion.rangeLow` | field/copy contract | models | yes | remove |
| `PolySampleRegion.rangeHigh` | field/copy contract | models | yes | remove |
| `PolySampleRegion.isMapped` | context-free getter | models | yes | remove |
| `PolySampleInstrument.mappedCount` | context-free getter | models | yes | remove |
| `PolySampleInstrument.warningCount` | context-free getter | models | yes | remove; total warning messages live in Cubit state |
| `PolyLooseWavMappingMode.unmapped` | enum value | models/import/dialog | yes | rename to `automaticNotes` |
| `PolyMultisampleBuilderState.mappingResolution` | state field | builder Cubit file | yes | add, default `PolySampleMappingResolution.empty` |
| `PolyMultisampleBuilderCubit.updateSwitchPoint` | method | builder Cubit file | yes | replaces `updateRangeLow` |
| `PolyMultisampleBuilderCubit.updateSelectedSwitchPoint` | method | builder Cubit file | yes | replaces selected Low method |
| `PolyMultisampleBuilderCubit.resetSelectedToAutomaticNotes` | method | builder Cubit file | yes | replaces `unmapSelectedRegions`; preserves V/RR |
| `updateRangeLow` / `updateSelectedRangeLow` | Cubit methods | builder Cubit file | yes | remove |
| `updateRangeHigh` / `updateSelectedRangeHigh` | Cubit methods | builder Cubit file | yes | remove; High is read-only |
| `_notePreviewEffectiveLow` / `_notePreviewEffectiveHigh` | private Cubit methods | builder Cubit file | no | remove |
| `_KeyboardNotePreviewMatch` | private class | builder Cubit file | no | retain; add required `resolvedMapping` |
| `effectiveLow` / `effectiveHigh` | functions | `poly_region_math.dart` | yes | remove, not compatibility-wrapped |
| `midiExtents` / `velocityLanes` | functions | `poly_region_math.dart` | yes | remove; resolution getters replace them |
| `mappingWarnings` | function | `poly_region_math.dart` | yes | replace with `mappingWarningMessages(regions, resolution)` |
| `selectedRegionFor` | function | `poly_region_math.dart` | yes | retain unchanged |
| `sampleDisplayLabel` | function | `poly_region_math.dart` | yes | retain unchanged |
| `_noteLabel` / `_commonDirectory` | private functions | `poly_region_math.dart` | no | retain; `_noteLabel` formats issue messages only |
| `PolySampleList.onUpdateRangeLow` | constructor field | sample list | yes | rename `onUpdateSwitchPoint` |
| `PolySampleList.onUpdateRangeHigh` | constructor field | sample list | yes | remove |
| `_InlineSampleValue` | private stateless widget | sample list | no | add for read-only High |
| `_MappingReadOnlyRow` | private stateless widget | inspector | no | add for read-only High with semantic hint |

The five removed `poly_region_math.dart` exports are internal only. Inventory
found importers in the builder Cubit, editor view, key map, inspector, list,
and region-math test. Every importer is named in the plan; no compatibility
re-export can preserve a context-free API accurately, so none is allowed.

## New domain interfaces

```dart
enum PolySampleMappingIssueKind {
  naturalOutOfMidiRange,
  switchOutOfMidiRange,
  impossibleRange,
  naturalOutsideRange,
  variantSwitchMismatch,
  overlappingRange,
}

class PolySampleMappingIssue {
  const PolySampleMappingIssue({
    required this.kind,
    required this.mapping,
    this.other,
  });

  final PolySampleMappingIssueKind kind;
  final PolySampleResolvedMapping mapping;
  final PolySampleResolvedMapping? other;
}

class PolySampleResolvedMapping {
  const PolySampleResolvedMapping({
    required this.region,
    required this.naturalMidi,
    required this.lowMidi,
    required this.highMidi,
    required this.naturalIsAutomatic,
    required this.switchIsAutomatic,
  });

  final PolySampleRegion region;
  final int naturalMidi;
  final int? lowMidi;
  final int? highMidi;
  final bool naturalIsAutomatic;
  final bool switchIsAutomatic;

  bool get isPlayable;
}

class PolySampleMappingResolution {
  const PolySampleMappingResolution({
    required this.mappings,
    required this.byPath,
    required this.issues,
  });

  const PolySampleMappingResolution.empty()
      : mappings = const [],
        byPath = const {},
        issues = const [];

  final List<PolySampleResolvedMapping> mappings;
  final Map<String, PolySampleResolvedMapping> byPath;
  final List<PolySampleMappingIssue> issues;

  PolySampleResolvedMapping? mappingForPath(String path);
  PolySampleResolvedMapping? mappingForRegion(PolySampleRegion region);
  List<PolySampleMappingIssue> issuesForPath(String path);
  List<PolySampleResolvedMapping> get playableMappings;
  int get mappedCount;
  int get warningCount;
  List<int> get velocityLanes;
  (int, int)? get midiExtents;
}

class PolySampleMappingResolver {
  const PolySampleMappingResolver();

  PolySampleMappingResolution resolve(List<PolySampleRegion> regions);

  static int automaticSwitchPoint({
    required int lowerNatural,
    required int higherNatural,
  });
}
```

`automaticSwitchPoint` throws `ArgumentError` when
`higherNatural <= lowerNatural`. `resolve` never calls it for duplicate
naturals.

`PolySampleResolvedMapping.isPlayable` is true exactly when natural, Low, and
High are present/in MIDI range and `lowMidi! <= highMidi!`. A natural outside
0-127 has null Low/High and is not playable.

## Cubit/state integration

Add to `PolyMultisampleBuilderState` immediately after `editedRegions`:

```dart
final PolySampleMappingResolution mappingResolution;
```

Constructor default and `copyWith` default:

```dart
this.mappingResolution = const PolySampleMappingResolution.empty(),
PolySampleMappingResolution? mappingResolution,
```

Add optional Cubit constructor dependency and field:

```dart
PolySampleMappingResolver? mappingResolver,

final PolySampleMappingResolver _mappingResolver;

_mappingResolver = mappingResolver ?? const PolySampleMappingResolver(),
```

At `_setInstrument` and `_replaceEditedRegions`:

1. Resolve the final copied region list exactly once.
2. Set both `mappingResolution` and
   `mappingWarnings: mappingWarningMessages(regions, mappingResolution)` in
   the same emit.

Set `mappingResolution: const PolySampleMappingResolution.empty()` anywhere
that explicitly sets `editedRegions: const []` or clears the current
instrument, including hardware-folder listing, large-folder state, and
`returnToSources`.

### Preview integration

- `_resolveKeyboardNotePreviewRegion` resolves candidates from
  `state.mappingResolution.playableMappings`; no `rootMidi != null` filter
  remains.
- Note containment uses `lowMidi! <= midi && midi <= highMidi!`.
- Candidate grouping/sorting retains the existing velocity-lane preference
  and RR rotation policy, but reads ranges/naturals from resolved mappings.
- `_KeyboardNotePreviewMatch` stores the chosen
  `PolySampleResolvedMapping resolvedMapping` and exposes its raw region only
  through `resolvedMapping.region`.
- `_hasDirectHardwareWavPreviewCandidate` uses the same resolution.
- `_keyboardPreviewSourcePlayback` and `_renderedKeyboardNotePreviewPath`
  take `required int naturalMidi`; pitch ratios and render-cache keys use it.
- Delete both private effective-range helpers.

### Build/debug reports

Each build-report line is exactly:

```text
<displayName> natural=<note or MIDI n> (<automatic|explicit>) low=<note|unresolved> (<automatic|explicit>) high=<note|unresolved> velocity=<n|-> rr=<n|->
```

The debug upload command creates one resolver resolution after scanning,
calls `mappingWarningMessages(instrument.regions, resolution)` once, and
prints that list's length instead of `instrument.warningCount`.

## Persistable editing contract

Final Cubit signatures:

```dart
void updateSwitchPoint(
  String path,
  int midi, {
  IDistingMidiManager? manager,
  bool focusRegion = false,
});

void updateSelectedMappings({
  int? rootMidi,
  int? switchPoint,
  int? velocityLayer,
  int? roundRobin,
  bool clearRoot = false,
  bool clearSwitchPoint = false,
  bool clearVelocityLayer = false,
  bool clearRoundRobin = false,
  IDistingMidiManager? manager,
});

void updateSelectedSwitchPoint(int midi, {IDistingMidiManager? manager});

void resetSelectedToAutomaticNotes();
```

- MIDI values clamp to 0-127 exactly as current root/range mutators do.
- `updateSwitchPoint` writes `region.copyWith(switchPoint: clampedMidi)`.
- `resetSelectedToAutomaticNotes` calls `updateSelectedMappings` with only
  `clearRoot: true` and `clearSwitchPoint: true`; it does not clear V/RR.
- `rangeLow`, `rangeHigh`, their copy/clear flags, old Cubit APIs, and their
  fingerprint entries are deleted.
- Low controls call switch-point APIs.
- High controls have no callbacks, popup, dropdown, or +/- buttons.

Apply/upload continue to serialize only raw filename tags. Required tests
prove an edited Low becomes `_SW<n>` and a rootless automatic sample remains
rootless instead of receiving a derived `_C3` token.

## UI and accessibility contract

### Shared formatting

- Compact visible automatic natural: `Auto C3`.
- Explicit natural: `C3`.
- Compact visible automatic Low: `Auto F1`.
- Explicit Low: `F1`.
- Automatic semantic phrase: `root C3, automatic`.
- Automatic Low semantic phrase: `low F1, automatic`.
- Invalid/unresolved compact value: `Unresolved`.
- Rootless supported audio uses the mapped waveform icon/semantic state; it
  never uses a missing-root warning icon.

### `PolyKeyMap`

Add required constructor field:

```dart
final PolySampleMappingResolution mappingResolution;
```

The editor passes `state.mappingResolution`. Every geometry/filter/semantic
path uses playable resolved mappings, including:

- `_scheduleSelectedScroll`;
- `_regionSemanticTargets`;
- summary mapped count, extents, and velocity lanes;
- `_regionRect`;
- `_regionSemanticLabel`;
- `_regionAtPosition`;
- `_PolyKeyMapPainter.paint`.

The painter and helpers receive the already-resolved object; none calls the
resolver. A rootless zone is focusable/selectable. Example exact semantic
label:

```text
Kick.wav, root C3, automatic, range C-1 to C3, velocity 1
```

### `PolySampleList`

Add required `mappingResolution`; rename callback to
`onUpdateSwitchPoint`; remove `onUpdateRangeHigh`.

- Root stepper starts from resolved natural, never hardcoded MIDI 60.
- Low stepper starts from resolved Low and writes explicit switch. It displays
  `Auto <note>` while `switchIsAutomatic` is true and `<note>` after a switch
  edit.
- High uses `_InlineSampleValue` with no buttons.
- Exact High semantics:
  `High <note> for <sample>, calculated from the next sample switch point`.
- Exact rootless row semantics begin
  `<label>, root C3, automatic, low ...`.
- Row warning state uses
  `mappingResolution.issuesForPath(region.path)`, so either participant in a
  pairwise mismatch/overlap is marked. Raw `currentIssues` still mark an
  unsupported row.

`_InlineSampleValue` is exactly a fixed-height compact value cell matching the
existing `_InlineSampleStepper` width and typography: centered `Column` with
the label above the value, wrapped in one `Semantics(container: true)` node.
It has no `IconButton`, `GestureDetector`, callback, focus action, or button
semantic.

### `PolySampleInspector`

Use `state.mappingResolution` for selected aggregation and focused display.

- A single automatic sample shows `Auto <note>`, never `Unset` or `Mixed`.
- A multi-selection is `Mixed` when resolved naturals differ or when equal
  naturals mix explicit and automatic sources.
- Root popup `initialValue` is the MIDI value only for an all-explicit
  selection; an automatic selection displays `Auto <note>` without selecting
  a popup item. Choosing any note writes an explicit root.
- Low aggregation compares `(lowMidi, switchIsAutomatic)`. It is `Mixed` when
  values differ or equal Low values mix explicit/automatic sources.
- Low dropdown/stepper writes switch points. An automatic Low uses null
  dropdown value with hint `Auto <note>`; choosing any note writes an explicit
  `_SW`.
- High is one `_MappingReadOnlyRow` with semantic hint
  `Calculated from the next sample switch point.`
- The High row's outer `SizedBox` has
  `ValueKey('poly-mapping-high-value')` for focused widget tests.
- High aggregation first maps every selected path to
  `mapping?.isPlayable == true ? mapping!.highMidi : null`. A single non-null
  value displays its note; a single null displays `Unresolved`. For multiple
  selections, all equal non-null values display that note, all null values
  display `Unresolved`, and any other combination displays `Mixed`. The
  `_MappingReadOnlyRow` semantic value is exactly the visible value.
- Single selection reset label: `Use automatic note`.
- Multi-selection reset label: `Use automatic notes`.
- Reset button uses `Icons.auto_fix_high` and calls
  `resetSelectedToAutomaticNotes`.

`_MappingReadOnlyRow` is exactly (the key is supplied for the High instance):

```text
SizedBox(key: key, height: PolySampleSidebarLayout.rowHeight)
  Row
    SizedBox(width: PolySampleSidebarLayout.mappingLabelWidth)
      Text(label)
    Expanded
      Semantics(label: '<label> value', value: value, hint: hint)
        Align(alignment: Alignment.centerLeft)
          Text(value, overflow: TextOverflow.ellipsis)
```

It is not a button and has no tap action.

### Toolbar/import terminology

- Toolbar selected action label/tooltip/semantic label:
  `Use automatic notes`.
- The selected toolbar action uses `Icons.auto_fix_high`; the no-selection
  `Discard all` action uses `Icons.restore`.
- Toolbar action keeps rows and keeps them counted as mapped.
- Toolbar mapped count is `state.mappingResolution.mappedCount`; toolbar
  warning count is `state.mappingWarnings.length`, which includes raw-file
  and resolver warnings.
- Loose import enum: `PolyLooseWavMappingMode.automaticNotes`.
- Loose import label: `Use Disting automatic notes from C3`.
- Automatic loose mapping clears root and switch only; it preserves parsed
  V/RR tags.
- Internal Decent converter option `addUnmapped` remains unchanged because it
  describes source-selection assignment, not final firmware playability.

## Dependency and compatibility notes

- New resolver imports exactly:
  - `dart:math` as `math`;
  - `package:path/path.dart` as `p`;
  - `package:nt_helper/poly_multisample/poly_multisample_models.dart`.
- Parser imports the resolver only for final sort keys; the resolver never
  imports the parser, so there is no cycle.
- Cubit and UI imports use package-prefixed paths from `specs/conventions.md`.
- No generated files are touched.
- No compatibility wrapper remains for old context-free effective-range
  helpers or range mutation APIs.
- Test-only `setTestState` helpers must resolve their supplied
  `editedRegions` before emitting. Direct view-state fixtures must populate
  `mappingResolution` explicitly.

## Acceptance criteria

1. The official gap table vectors and EVOS A1 fixture pass in pure resolver
   tests.
2. Input order does not change automatic family naturals.
3. Rootless V/RR variants share a natural; `_SW`-different stems do not.
4. Mixed explicit C3 plus first rootless family produces two natural-48
   mappings and a deterministic collision/overlap issue.
5. Automatic families after MIDI 127 are unresolved with an issue, never
   saturated to 127.
6. Rootless WAV note preview selects the correct sample and pitches relative
   to the resolved natural.
7. The key map renders, focuses, selects, and announces rootless zones.
8. One selected EVOS A1 row/inspector shows A1, automatic F1, B1 and no
   `Mixed`.
9. Low edits survive apply/upload as `_SW`; High is visibly read-only.
10. Reset-to-automatic preserves velocity/RR, removes explicit root/SW, keeps
    the row mapped, and preserves a rootless target filename.
11. `missingRootNote`, `rangeLow`, `rangeHigh`, context-free `isMapped`/
    `mappedCount`, old range APIs, and all three duplicated mapping
    implementations have no declarations or call sites.
12. Accessibility tests cover the automatic qualifier, read-only High hint,
    mapped summary count, reset action, and rootless key-map target.
13. An unsupported file remains present in the total warning count, and an
    out-of-range parsed `_SW` remains raw while producing the exact switch
    warning.
14. `flutter analyze` prints `No issues found!` and full `flutter test` passes
    after every step and at program completion.
