# Implementation plan: repeat-aware offline algorithm metadata

Implement [spec.md](./spec.md) in six commits. Keep the implementation limited
to adjacent count-axis inference and a compact section grammar.

```bash
flutter analyze && flutter test
```

## Fixed decisions

- Reuse the current count-name/type selector; do not probe delay/sample-time
  axes.
- The canonical flat capture uses `min + 1` for selected count axes and safe
  defaults for all other axes.
- Each count axis gets one `n` capture. Interacting axes get one joint `n`
  capture per overlap group.
- The canonical rows are the grammar's source; there is no witness-to-canonical
  rebinding phase.
- Grammar sections reference canonical row runs and contain no copied metadata.
- No partial grammar is saved. Any failure retains the flat fallback.
- Bundle format becomes `full_metadata` version 3; versions 1 and 2 still import.
- Preset/template behavior is untouched.

## Symbol map

| Symbol | File | Responsibility |
|---|---|---|
| `AlgorithmShapeSnapshot` | `lib/models/algorithm_shape_snapshot.dart` | Immutable normalized metadata capture |
| `AlgorithmRepeatGrammar` | `lib/models/algorithm_repeat_grammar.dart` | Section grammar, compact codec, expansion |
| `AlgorithmRepeatInferenceService` | `lib/services/algorithm_repeat_inference_service.dart` | Candidate selection, probes, adjacent proof |
| `AlgorithmRepeatGrammars` | `lib/db/tables.dart` | One grammar row per modeled algorithm |
| `OfflineAlgorithmShapeResolver` | `lib/services/offline_algorithm_shape_resolver.dart` | Load, expand, validate, and fall back |

## STEP 1 — Add the section grammar and expander

Commit: `feat(metadata): add compact repeat grammar`

### Files

- Add `lib/models/algorithm_shape_snapshot.dart`.
- Add `lib/models/algorithm_repeat_grammar.dart`.
- Add `test/models/algorithm_repeat_grammar_test.dart`.

### Snapshot types

Add immutable, collection-equal types:

```dart
final class AlgorithmShapeSnapshot {
  final List<int> specificationValues;
  final List<ShapeParameterAtom> parameters;
  final List<ShapePageAtom> pages;
  final List<ShapePageMembershipAtom> pageMemberships;
  final List<ShapeOutputUsageAtom> outputUsage;
}

final class ShapeParameterAtom {
  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final int rawUnitIndex;
  final int powerOfTen;
  final int ioFlags;
  final List<String> enumStrings;
}

final class ShapePageAtom { final String name; }
final class ShapePageMembershipAtom {
  final int pageIndex;
  final int parameterNumber;
}
final class ShapeOutputUsageAtom {
  final int parameterNumber;
  final int affectedParameterNumber;
}
```

Sort membership atoms by `(pageIndex, parameterNumber)` and output atoms by
`(parameterNumber, affectedParameterNumber)`. Exclude GUID, firmware, current
values, mappings, and database unit IDs.

### Grammar types and codec

Implement:

```dart
final class AlgorithmRepeatGrammar {
  static const currentVersion = 1;
  final List<int> baselineSpecifications;
  final List<RepeatSection> sections;

  AlgorithmShapeSnapshot expand(
    AlgorithmShapeSnapshot canonical,
    List<int> specificationValues,
  );
  Object toCompactJson();
  static AlgorithmRepeatGrammar fromCompactJson(Object json);
}

final class RepeatSection {
  final int specificationIndex;
  final int countBias;
  final int sourceOrdinal;
  final List<ShapeStreamRun> runs;
  final List<OrdinalSubstitution> substitutions;
  final List<RepeatSection> children;
}

final class ShapeStreamRun {
  final ShapeStream stream;
  final int firstStart;
  final int itemCount;
}
```

`ShapeStream` codes are `0 parameters`, `1 pages`, `2 memberships`, and
`3 outputUsage`. Child run offsets are relative to the selected parent
occurrence; top-level offsets are relative to the canonical stream.

Add only `OrdinalTextSubstitution` and `AffineIntegerSubstitution`. Version-1
field codes are:

```text
0 parameterName   1 parameterEnumString   2 pageName
3 parameterMin    4 parameterMax          5 parameterDefault
```

Enum substitutions carry an element index; other scalar fields use `-1`.
References are not patched. They are remapped through generated logical
addresses.

Use this exact tagged-array codec:

```text
[1, baselineSpecifications, sections]
["r", specIndex, countBias, sourceOrdinal, runs, substitutions, children]
[streamCode, firstStart, itemCount]
["t", streamCode, rowOffset, fieldCode, elementIndex, parts]
["i", streamCode, rowOffset, fieldCode, elementIndex,
      constant, [[specIndex, coefficient]...]]
```

Text `parts` are strings or `[specIndex, displayBias]`. Unknown versions, tags,
stream codes, or field codes throw `FormatException`.

Iteration ordinals are zero-based. The source occurrence begins at
`firstStart + sourceOrdinal * itemCount`; text placeholders render
`iterationOrdinal + displayBias`; affine integers render `constant +` the sum
of each coefficient times its active iteration ordinal. Do not substitute raw
specification values. Both values in an output-usage edge are logical parameter
references and are remapped through generated addresses; neither is an affine
integer field.

### Expansion algorithm

For each stream, sort sibling runs by `firstStart` and walk the canonical rows
once:

1. Copy gaps once as fixed rows.
2. At a section run, skip its `canonicalRepeatCount * itemCount` covered range,
   where `canonicalRepeatCount = baselineSpec + countBias`.
3. Clone the source occurrence `requestedSpec + countBias` times.
4. Recursively expand children within each cloned source occurrence.
5. Apply text/integer substitutions from the active specification ordinals.
6. Give generated parameter/page rows logical addresses of
   `(sourceRow, activeSpecOrdinals)`.
7. Remap membership and both output-usage parameter references through those
   addresses, assigning an edge to its deepest repeated endpoint. Group usage
   edges only when building `OutputModeUsage` for callers.

Reject negative counts, invalid/overlapping runs, a child outside its parent,
same-axis self-nesting, duplicate addresses, ambiguous edge ownership, dangling
references, or invalid substitutions. Throw before returning any snapshot.

### Tests

- Compact JSON round-trips every type.
- A fixed-only grammar reproduces the canonical snapshot.
- A Quantizer-style section expands from 2 canonical channels to 1, 4, and 12,
  including names, pages, enums, memberships, and output usage.
- Two disjoint sections can use one specification.
- Nested Channels/Sends expands 4 x 2 in deterministic order.
- A fixed page can reference generated parameters through remapped memberships.
- Every invalid condition above throws without a partial result.

### Verify

```bash
dart format lib/models/algorithm_shape_snapshot.dart lib/models/algorithm_repeat_grammar.dart test/models/algorithm_repeat_grammar_test.dart
flutter test test/models/algorithm_repeat_grammar_test.dart
flutter analyze
```

## STEP 2 — Infer adjacent repeat sections

Commit: `feat(metadata): infer adjacent repeat sections`

### Files

- Add `lib/services/algorithm_repeat_inference_service.dart`.
- Add `test/services/algorithm_repeat_inference_service_test.dart`.

### Public API

Implement:

```dart
final class SpecificationVector { final List<int> values; }

final class AlgorithmRepeatProbePlan {
  final SpecificationVector canonical;
  final Map<int, SpecificationVector> lowerWitnessByAxis;
}

final class AlgorithmRepeatInferenceService {
  static bool isRepeatCandidate(Specification specification);
  AlgorithmRepeatProbePlan buildInitialPlan(List<Specification> specs);
  AdjacentRepeatAnalysis analyzeInitial({
    required List<Specification> specifications,
    required AlgorithmRepeatProbePlan plan,
    required Map<SpecificationVector, AlgorithmShapeSnapshot> snapshots,
  });
  List<SpecificationVector> interactionWitnesses(
    AdjacentRepeatAnalysis analysis,
  );
  AlgorithmRepeatInferenceResult compile({
    required AdjacentRepeatAnalysis analysis,
    required Map<SpecificationVector, AlgorithmShapeSnapshot> snapshots,
  });
}
```

Use result variants `ProvenAlgorithmRepeatGrammar`, `NoAlgorithmRepeats`, and
`UnprovenAlgorithmRepeats(reason)`. Analysis data stays in memory.

### Candidate and probe rules

- Implement `isRepeatCandidate` with the existing type check and regex unchanged.
  In STEP 4, replace `MetadataSyncService._isUsefulOfflineCountSpec`'s private
  copy with delegation to this method.
- Canonical selected axes use `min + 1`; unselected axes use
  `safeDefaultValue`.
- Each lower witness changes exactly one selected axis to `min`.
- Skip fixed axes and every unselected axis. No Delay/Sample witness may be
  returned by the plan.

### Deterministic diff

Infer parameters and pages first, then translate relationship references
through those alignments.

1. Build a dynamic-programming longest-common-subsequence table for each stream.
   Exact topology-token matches score `2`; ordinal-compatible matches score `1`;
   insertion/deletion scores `0`.
2. Parameter topology tokens contain exact name, raw unit, power, `ioFlags`, and
   enum count. Page tokens contain exact name. Fixed scalar min/max/default is
   excluded from the token.
3. Backtrack the highest score. When two paths remain equally scored after
   preferring exact over ordinal-compatible matches, mark the decomposition
   ambiguous and reject it; do not choose by index.
4. Canonical-only runs are the proposed added occurrences. Compare each with
   the immediately preceding occurrence, then the following occurrence if no
   predecessor exists.
5. Text is ordinal-compatible only when its non-digit segments are identical
   and every differing digit run advances by the same section-ordinal delta.
   Equal digit runs remain literal.
6. Min/max/default values are compatible only when their differences produce
   one affine coefficient for the same ordinal delta.
7. Raw unit, power, and `ioFlags` must match literally.

For each accepted added run, scan backward and forward in the canonical stream
to find a uniform run. Set:

```text
countBias = canonicalOccurrenceCount - canonicalSpecificationValue
firstStart = first canonical occurrence
itemCount = one occurrence length; occurrences must be contiguous
sourceOrdinal = ordinal of the canonical-only occurrence
```

Require `specValue + countBias >= 0` over the declared range. Group unmatched
page/membership/output rows with the parameter run whose logical references they
touch. A page-only or relationship-only insertion becomes a separate section.
Reject an edge that could belong to two sections.

### Interaction proof

Two candidate sections interact when their canonical runs overlap or one lies
inside the other's source occurrence. Build connected overlap groups. For each
group with two or more specification indexes, request one vector with every
group axis lowered to `min`; other axes stay canonical.

Reject an interaction group containing more than two specification indexes in
version 1. This keeps the one-joint-witness proof sufficient without adding
more corners.

To nest an inner section, require the interaction witness to show the inner
insertion at the same relative stream offsets in every outer occurrence. Hoist
that section into the outer `children` once, then expand and exactly reconstruct
the canonical, every lower witness, and every interaction witness.

Any tied diff, unsupported change, missing witness, failed reconstruction, or
invalid reference returns `UnprovenAlgorithmRepeats`. Never emit a partial
grammar.

### Tests

- The selector accepts Channels/Inputs/Outputs/Sends/Stereo/Voices of types 0/2
  and rejects Max delay time, Record time, unrelated names, and other types.
- Quantizer 1/2 infers one section and expands at 4/12.
- One axis can add two disjoint sections.
- Mixer `(2,1), (1,1), (2,0), (1,0)` infers nested Sends under Channels.
- A scalar-only fixed-row change yields `NoAlgorithmRepeats`.
- Tied LCS, non-affine rows, ambiguous relationships, and missing interaction
  witnesses yield `UnprovenAlgorithmRepeats`.
- Three interacting axes yield `UnprovenAlgorithmRepeats`; three disjoint axes
  remain independently representable.

### Verify

```bash
dart format lib/services/algorithm_repeat_inference_service.dart test/services/algorithm_repeat_inference_service_test.dart
flutter test test/services/algorithm_repeat_inference_service_test.dart test/models/algorithm_repeat_grammar_test.dart
flutter analyze
```

## STEP 3 — Persist and bundle grammar rows

Commit: `feat(metadata): persist repeat grammars in bundles`

### Files

- Edit `lib/db/tables.dart`, `lib/db/database.dart`, and
  `lib/db/daos/metadata_dao.dart`.
- Edit `lib/services/algorithm_json_exporter.dart` and
  `lib/services/metadata_import_service.dart`.
- Update schema-version tests in `test/db/io_flags_migration_test.dart` and
  `test/db/migrations/v11_to_v12_template_metadata_test.dart`.
- Add `test/db/migrations/v13_to_v14_repeat_grammar_test.dart`.
- Update export-version assertions in
  `test/services/io_flags_import_export_test.dart`.
- Add `test/services/algorithm_repeat_grammar_import_export_test.dart`.

### Schema and DAO

Add `AlgorithmRepeatGrammars` from the spec, register it in the database and
DAO, raise schema version 13 to 14, and create the table for `from <= 13`.

Add:

```dart
Future<AlgorithmRepeatGrammarEntry?> getAlgorithmRepeatGrammar(String guid);
Future<List<AlgorithmRepeatGrammarEntry>> getAllAlgorithmRepeatGrammars();
Future<void> replaceAlgorithmShapeAndGrammar({
  required String guid,
  required List<ParameterEntry> parameters,
  required List<ParameterEnumEntry> enums,
  required List<ParameterPageEntry> pages,
  required List<ParameterPageItemEntry> pageItems,
  required List<ParameterOutputModeUsageEntry> outputUsage,
  required AlgorithmRepeatGrammar? grammar,
});
```

Validate/encode the grammar before opening the transaction. Inside, delete old
grammar, output usage, page items, pages, enums, and parameters in dependency
order; insert the supplied flat rows; then insert the grammar last. Do not
delete specifications or the algorithm parent. A null grammar deliberately
removes a stale row.

Change algorithm upserts in the DAO and metadata importer from SQLite
`INSERT OR REPLACE` to conflict-update semantics so replacing an algorithm
parent cannot cascade-delete its grammar. Delete grammar and output-usage rows
in both `clearAlgorithmMetadata` and `clearAllMetadata`; output usage is
currently missing from those clear paths.

### Version-3 bundle

- Export `tables.algorithmRepeatGrammars` for factory GUIDs as
  `{algorithmGuid, grammarVersion, grammar}`; `grammar` is the decoded array.
- Accept v1/v2 with the table absent.
- Validate every v3 grammar before beginning import; malformed input fails the
  import without writes.
- Insert algorithm parents before grammars.
- Wrap all v3 table writes in one `database.transaction` so matching flat rows
  and grammars cannot be separated by an import failure.

Keep the existing empty-database import boundary. Full v3 import writes matching
flat rows and grammar rows together. Do not add a selective grammar-only upgrade
for populated v1/v2 databases, because their representative flat shape may not
match the new grammar's canonical baseline. Those databases use flat fallback
until hardware metadata sync writes a matching pair.

### Tests and verification

- v13-to-v14 migration preserves flat rows.
- Atomic shape/grammar replacement round-trips a grammar, preserves
  specifications, and removes a stale grammar when passed null.
- v1/v2 imports leave the table empty; v3 round-trips.
- Malformed v3 import is atomic.
- Importing v3 into an empty database yields matching flat rows and grammars;
  populated v1/v2 databases are not selectively modified.
- Clear paths remove output usage and grammar rows for the target scope.

```bash
dart run build_runner build --delete-conflicting-outputs
dart format lib/db lib/services test/db test/services
flutter test test/db test/services/io_flags_import_export_test.dart test/services/algorithm_repeat_grammar_import_export_test.dart
flutter analyze
```

Generated Drift files are gitignored; do not force-add them.

## STEP 4 — Compile grammars during hardware sync

Commit: `feat(metadata): compile repeat grammars during sync`

### Files

- Edit `lib/services/metadata_sync_service.dart`.
- Edit `test/services/metadata_sync_service_test.dart` and
  `test/services/metadata_sync_service_output_mode_test.dart`.

### Refactor capture from persistence

Replace `_syncInstantiatedAlgorithmParams` with:

```dart
Future<AlgorithmShapeSnapshot> _captureInstantiatedAlgorithmShape(
  AlgorithmInfo algorithm,
  List<int> requestedSpecifications,
  FirmwareVersion firmwareVersion,
);

Future<void> _persistCanonicalAlgorithmShape(
  MetadataDao dao,
  AlgorithmInfo algorithm,
  AlgorithmShapeSnapshot snapshot,
  Map<String, int> unitIdMap,
  List<String> unitStrings,
);
```

Capture parameters, enums, pages, memberships, and one output-usage edge per
affected parameter entirely in memory. Preserve the existing Macro Oscillator
workaround.
After add/poll, require `requestAlgorithmGuid(0)` to return the requested GUID
and exact vector. Remove every probe in `finally`.

Canonical persistence converts the snapshot to Drift rows and calls
`replaceAlgorithmShapeAndGrammar`, so the flat shape and grammar become visible
in one transaction. It performs no grammar inference itself.

### Scan order

For algorithms with selected count axes:

1. Build and capture the canonical probe plan.
2. Capture each lower witness.
3. Analyze and capture required interaction witnesses.
4. Compile.
5. If proven, persist the canonical snapshot and grammar atomically.
6. If no repeats or unproven, capture today's `_scanSpecValues` vector when it
   differs from canonical, then atomically persist it with a null grammar.

Algorithms without selected axes take the existing one-scan path and store no
grammar. Keep current plugin loading, retry/reboot, cancellation, and progress
behavior. Report only `repeat grammar: proven`, `no repeats`, or `unproven`
through the existing status callback.

Use this path for full sync and `rescanSingleAlgorithm`.

### Tests and verification

- Delay/Sample axes cause no extra `requestAddAlgorithm` call.
- Quantizer requests canonical Channels 2 and witness Channels 1 and stores one
  flat shape plus one grammar.
- Mixer requests exactly `(2,1), (1,1), (2,0), (1,0)` for its count axes.
- Probe captures perform no database writes.
- A mismatched vector, timeout, missing metadata, or unproven delta stores no
  grammar and uses the existing representative fallback.
- Rescan removes a stale grammar; output-mode edges persist once.

```bash
dart format lib/services/metadata_sync_service.dart test/services/metadata_sync_service_test.dart test/services/metadata_sync_service_output_mode_test.dart
flutter test test/services/metadata_sync_service_test.dart test/services/metadata_sync_service_output_mode_test.dart
flutter analyze
```

## STEP 5 — Resolve repeated sections offline

Commit: `feat(offline): expand specification repeat grammars`

### Files

- Add `lib/services/offline_algorithm_shape_resolver.dart`.
- Edit `lib/domain/offline_disting_midi_manager.dart`.
- Edit `test/domain/offline_disting_midi_manager_specifications_test.dart`.
- Add `test/domain/offline_disting_midi_manager_repeat_grammar_test.dart`.

### Resolver and integration

Implement:

```dart
final class OfflineAlgorithmShapeResolver {
  OfflineAlgorithmShapeResolver(MetadataDao dao);
  Future<ResolvedAlgorithmShape> resolve(
    String algorithmGuid,
    List<int> specificationValues,
  );
}
```

Load canonical rows into `AlgorithmShapeSnapshot`, validate the requested vector
against stored specifications, then expand the grammar. Wrong vector length,
out-of-range values, absent/malformed grammar, or any expansion error returns
the complete canonical shape with `usedGrammar == false`.

Cache by GUID plus immutable vector in `OfflineDistingMidiManager`; clear the
cache in `initializeFromDb`. Route these methods through the resolved shape:

- `requestNumberOfParameters`;
- `requestParameterInfo`;
- `requestParameterEnumStrings`;
- `requestParameterPages`;
- `requestOutputModeUsage`.

Do not change parameter values, mappings, save/load, add/remove/move, templates,
or `_presetSpecificationValues`.

### Tests and verification

- Quantizer slots at 1 and 4 channels resolve differently from the same rows.
- Mixer 4/2 has nested sections and valid page/output references.
- Delay values return the same flat shape.
- Missing/invalid grammar and v1/v2 data fall back atomically.
- `requestNewPreset` still clears specs; add preserves only supplied specs.

```bash
dart format lib/services/offline_algorithm_shape_resolver.dart lib/domain/offline_disting_midi_manager.dart test/domain
flutter test test/domain/offline_disting_midi_manager_specifications_test.dart test/domain/offline_disting_midi_manager_repeat_grammar_test.dart test/domain/offline_disting_midi_manager_test.dart test/domain/offline_lfo_routing_test.dart
flutter analyze
```

## STEP 6 — Refresh and verify the bundled data

Commit: `chore(metadata): refresh bundled repeat grammars`

Requires the physical disting NT and the existing debug export flow.

### Files and procedure

- Replace `assets/metadata/full_metadata.json` with the version-3 export.
- Add `test/services/bundled_repeat_grammar_test.dart`.
- Start from an empty preset without restarting an already running app.
- Run full factory metadata sync and export through
  `AlgorithmJsonExporter.exportFullMetadata`.
- Keep the existing `assets/metadata/` entry in `pubspec.yaml`; add no duplicate.

### Fixed asset checks

```bash
jq -e '
  .exportType == "full_metadata" and
  .exportVersion == 3 and
  ([.tables.algorithmRepeatGrammars[].algorithmGuid] | index("quan") != null) and
  ([.tables.algorithmRepeatGrammars[].algorithmGuid] | index("mix1") != null)
' assets/metadata/full_metadata.json
```

The asset test imports the checked-in JSON and verifies only these named cases:

- `quan` expands Channels 1, 4, and 12;
- `mix1` expands Channels 4/Sends 2 without dangling relationships;
- `delm` has no grammar and values 1/30 use the same flat topology;
- every bundled grammar decodes and its baseline vector reconstructs the flat
  canonical rows;
- grammar arrays contain no copied snapshots or per-value profiles.

```bash
dart format test/services/bundled_repeat_grammar_test.dart
flutter test test/services/bundled_repeat_grammar_test.dart
flutter analyze
flutter test
git status --short
```

Commit the asset and test together.

## Final audit

- Check every acceptance criterion in `spec.md`.
- Confirm no profile table, raw proof snapshot, ignored-axis list, max sweep, or
  non-count probe was added.
- Confirm `git status --short` is clean after the six commits.
- Push through the repository's normal flow.
