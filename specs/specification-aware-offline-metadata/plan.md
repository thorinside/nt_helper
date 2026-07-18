# Specification-aware offline algorithm metadata implementation plan

Total steps: 8

Each step is independently committable. Execute exactly one numbered step per
fresh-context session. Before every step, read these files completely:

- `specs/conventions.md`
- `specs/specification-aware-offline-metadata/spec.md`
- this plan

This program intentionally differs from the poly-samples verification defaults
in `specs/conventions.md`. Use only the format and test paths named by each step,
then run `flutter analyze` as stated.

Recovery override for every step: do not run the conventions file's broad
`git checkout -- lib test` command. After a second failure, preserve the
worktree, report `FAILED` with the command/output, and stop. Never discard files
outside the current step.

Program-level verification after STEP 8:

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Do not start STEP 8 without a connected physical disting NT and an intentionally
saved/dispensable device preset. The metadata scan clears the device preset.

## Program-wide constants and contracts

Use these values exactly wherever the implementation needs them:

```dart
const int algorithmOfflineModelFormatVersion = 1;
const int fullMetadataExportVersion = 3;
const int maxExhaustiveAxisCardinality = 24;
const int maxCartesianProfiles = 128;
```

Do not add a symbolic repeat-rule AST, name-generated parameters, a background
scanner, plugin-model bundling, success snackbars, or debug logging in any step.

If a requirement is unclear, the architecture and JSON contracts in `spec.md`
are authoritative. Do not substitute a different persistence model.

## STEP 1 of 8 — Define canonical snapshots and exact profile models

### Files to edit

- Create `lib/models/algorithm_offline_model.dart`
- Create `test/models/algorithm_offline_model_test.dart`

### Required implementation

Create these public declarations in
`lib/models/algorithm_offline_model.dart`:

```dart
const int algorithmOfflineModelFormatVersion = 1;

enum OfflineModelCoverage { verified, partial, unsupported, legacy }

final class AlgorithmShapeParameter { ... }
final class AlgorithmShapePage { ... }
final class AlgorithmShapeSnapshot { ... }
final class AlgorithmShapeProfile { ... }
final class AlgorithmShapeCaptureFailure { ... }
final class AlgorithmOfflineModel { ... }
final class ResolvedAlgorithmShape { ... }
```

Use `package:crypto/crypto.dart` for SHA-256 and `dart:convert` for JSON.

`AlgorithmShapeParameter` has these final fields and required constructor
parameters:

- `String name`
- `int min`
- `int max`
- `int defaultValue`
- `int unit`
- `int powerOfTen`
- `int ioFlags`
- `List<String> enumStrings`, copied to an unmodifiable list

It exposes:

- `Map<String, Object> toJson()` using the field names from the payload example
  in `spec.md`;
- `factory AlgorithmShapeParameter.fromJson(Map<String, dynamic> json)`;
- `String get entityHash`, computed from canonical compact JSON.

`AlgorithmShapePage` has `String name` and unmodifiable
`List<int> parameterNumbers`, with `toJson`/`fromJson`.

`AlgorithmShapeSnapshot` has:

- `String algorithmGuid`
- unmodifiable `List<int> specificationValues`
- unmodifiable `List<AlgorithmShapeParameter> parameters`
- unmodifiable `List<AlgorithmShapePage> pages`
- unmodifiable `Map<int, List<int>> outputModeUsage`
- `String sourceFirmwareVersion`

It exposes `Map<String, Object> toShapeJson()` and `String get fingerprint`.
`toShapeJson` contains only ordered parameters, pages, and output-mode usage; it
excludes GUID, specification values, firmware version, and fingerprint. Sort
each affected-output list while constructing the snapshot. Encode
output-mode-map integer keys as base-10 strings. Add a private recursive
canonicalizer that sorts map keys but never sorts lists. `fromJson` rejects a
negative or non-integer output-mode key.

`AlgorithmShapeProfile` has:

- unmodifiable `List<int> specificationValues`
- `String profileKey`
- unmodifiable `List<String> parameterRefs`
- unmodifiable `List<AlgorithmShapePage> pages`
- unmodifiable `Map<int, List<int>> outputModeUsage`
- `String fingerprint`

It has `toJson`/`fromJson`.

`AlgorithmShapeCaptureFailure` has unmodifiable
`List<int> specificationValues` and `String error`, with `toJson`/`fromJson`.

`AlgorithmOfflineModel` has:

- `int formatVersion`
- `String algorithmGuid`
- `OfflineModelCoverage coverage`, excluding `legacy` in persisted payloads
- unmodifiable `List<int> baselineSpecificationValues`
- unmodifiable `List<int> structuralSpecificationIndexes`
- unmodifiable `List<int> largeSpecificationIndexes`
- unmodifiable `Map<String, AlgorithmShapeParameter> parameterPool`
- unmodifiable `List<AlgorithmShapeProfile> profiles`
- unmodifiable `List<AlgorithmShapeCaptureFailure> failedVectors`

It has `toJson`, `toJsonString`, `fromJson`, and `fromJsonString`. `fromJson`
throws `FormatException` when `formatVersion != 1`, when a profile references a
missing parameter-pool hash, or when persisted coverage is `legacy`.
`toJson` includes `algorithmGuid` and the lowercase enum name in `coverage`, as
shown in `spec.md`; those duplicate the searchable table columns deliberately.

Add this method:

```dart
String profileKeyFor(
  List<int> specificationValues,
  List<int> structuralSpecificationIndexes,
)
```

It returns ascending `specIndex=value` pairs joined with commas and returns the
empty string when no structural indexes exist.

`ResolvedAlgorithmShape` has:

- unmodifiable `List<AlgorithmShapeParameter> parameters`
- unmodifiable `List<AlgorithmShapePage> pages`
- unmodifiable `Map<int, List<int>> outputModeUsage`
- `OfflineModelCoverage coverage`

Do not store an algorithm index in it. The offline manager supplies its current
slot index when constructing SysEx-domain response objects.

### Required tests

In `test/models/algorithm_offline_model_test.dart`, add exactly these test
names:

1. `shape fingerprint is stable across map insertion order`
2. `shape fingerprint ignores specification vector and provenance`
3. `shape fingerprint changes when pages change at equal parameter count`
4. `parameter entity hash includes enum strings and io flags`
5. `profile key uses structural indexes in ascending order`
6. `offline model JSON round trip preserves exact profiles`
7. `offline model rejects an unknown format version`
8. `offline model rejects a missing parameter pool reference`
9. `offline model rejects a non-integer output mode key`
10. `persisted model rejects legacy coverage`

The equal-count test must keep the same parameter list and change only page
membership. The round-trip test must include duplicate `parameterRefs`, a page,
output-mode usage, and one failed vector.

### Leftover checks

```bash
grep -n "enum OfflineModelCoverage" lib/models/algorithm_offline_model.dart
grep -n "class AlgorithmShapeSnapshot" lib/models/algorithm_offline_model.dart
grep -n "String profileKeyFor" lib/models/algorithm_offline_model.dart
grep -n "shape fingerprint changes when pages change" test/models/algorithm_offline_model_test.dart
```

Every command must print one line.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/models/algorithm_offline_model.dart test/models/algorithm_offline_model_test.dart
flutter analyze
flutter test test/models/algorithm_offline_model_test.dart
git add lib/models/algorithm_offline_model.dart test/models/algorithm_offline_model_test.dart
git status --short
git commit -m "feat(metadata): define specification-aware shape models"
```

Only the two files named by this step may appear in `git status --short` before
the commit.

### Commit message

`feat(metadata): define specification-aware shape models`

## STEP 2 of 8 — Persist models and publish shapes atomically

### Prerequisites

- STEP 1 committed with message
  `feat(metadata): define specification-aware shape models`.

### Files to edit

- `lib/db/tables.dart`
- `lib/db/database.dart`
- `lib/db/database.g.dart` (regenerated only; never hand-edit)
- `lib/db/daos/metadata_dao.dart`
- `lib/db/daos/metadata_dao.g.dart` (regenerated only; never hand-edit)
- Create `test/db/migrations/v13_to_v14_algorithm_offline_models_test.dart`
- Create `test/db/algorithm_offline_models_dao_test.dart`
- `test/db/io_flags_migration_test.dart`
- `test/db/migrations/v11_to_v12_template_metadata_test.dart`

### Required implementation

Add `AlgorithmOfflineModels` to `lib/db/tables.dart` with data class name
`AlgorithmOfflineModelEntry` and exactly these columns:

- `algorithmGuid`: text primary key referencing `Algorithms.guid`, cascade on
  delete;
- `modelVersion`: integer;
- `sourceFirmwareVersion`: nullable text;
- `specificationDefinitionHash`: text;
- `coverage`: text;
- `origin`: text;
- `payloadJson`: text;
- `capturedAt`: date/time.

Register the table in `AppDatabase` and `MetadataDao`. Set `schemaVersion` to 14.
For `from <= 13`, create `algorithmOfflineModels`. Do not modify older migration
conditions.

Add these `MetadataDao` methods with the exact signatures:

```dart
Future<void> replaceAlgorithmOfflineModel(
  AlgorithmOfflineModelEntry entry,
)

Future<AlgorithmOfflineModelEntry?> getAlgorithmOfflineModel(String guid)

Future<List<AlgorithmOfflineModelEntry>> getAllAlgorithmOfflineModels()

Future<void> deleteAlgorithmOfflineModel(String guid)

Future<String?> getBundledOfflineModelDigest()

Future<void> saveBundledOfflineModelDigest(String digest)

Future<void> replaceAlgorithmShapeMetadata({
  required AlgorithmEntry algorithmEntry,
  required List<SpecificationEntry> specificationEntries,
  required List<ParameterEntry> parameterEntries,
  required List<ParameterEnumEntry> enumEntries,
  required List<ParameterPageEntry> pageEntries,
  required List<ParameterPageItemEntry> pageItemEntries,
  required List<ParameterOutputModeUsageEntry> outputModeUsageEntries,
  AlgorithmOfflineModelEntry? offlineModel,
})
```

`replaceAlgorithmOfflineModel` is one
`into(algorithmOfflineModels).insertOnConflictUpdate(entry)` statement. The
single SQL statement is atomic. `replaceAlgorithmShapeMetadata` opens the one
publication transaction. It first validates that every supplied entry uses
`algorithmEntry.guid` and that specification indexes are contiguous from zero.
It conflict-updates `algorithmEntry`, then deletes existing child rows in this
order:

1. `parameterOutputModeUsage`
2. `parameterPageItems`
3. `parameterPages`
4. `parameterEnums`
5. `parameters`
6. `specifications`

It then inserts in dependency order: specifications, parameters, enums, pages,
page items, output-mode usage, and finally the optional model with
`insertOnConflictUpdate`. Always delete the GUID's old model inside the
transaction before the optional insert. When `offlineModel` is null, the result
is a representative flat shape with no potentially stale model. When it is
non-null, require its GUID to equal `algorithmEntry.guid` or throw
`ArgumentError` before opening the transaction.

Use metadata-cache key `bundled_offline_model_digest` for the digest methods.
Blank cache values return `null`.

Change `upsertAlgorithms` from SQLite `INSERT OR REPLACE` to per-row
`insertOnConflictUpdate`. A parent algorithm update must not delete/cascade its
offline model.

Update both `clearAlgorithmMetadata` and `clearAllMetadata` to delete
`parameterOutputModeUsage` and `algorithmOfflineModels` before deleting
parameters/algorithms. `clearAllMetadata` also deletes the
`bundled_offline_model_digest` cache row. This is required cleanup, not optional
refactoring.

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

and commit the generated Drift files. Update both existing schema-version tests
named by this step to expect 14; do not change their other assertions.

### Required tests

`test/db/migrations/v13_to_v14_algorithm_offline_models_test.dart`:

1. `v13 to v14 creates algorithm offline models table`
2. `v13 metadata remains readable after model migration`

`test/db/algorithm_offline_models_dao_test.dart`:

1. `algorithm upsert preserves an existing offline model`
2. `shape publication replaces flat rows and model atomically`
3. `shape publication rolls back flat rows when model insert fails`
4. `representative-only publication removes a stale prior model`
5. `model clear methods remove output usage and offline models`
6. `bundled model digest round trips through metadata cache`

Use `NativeDatabase.memory()`. The rollback test supplies a model whose GUID
violates the algorithm FK and asserts the prior flat rows and model remain.

### Leftover checks

```bash
grep -n "class AlgorithmOfflineModels" lib/db/tables.dart
grep -n "schemaVersion => 14" lib/db/database.dart
grep -n "replaceAlgorithmShapeMetadata" lib/db/daos/metadata_dao.dart
grep -n "bundled_offline_model_digest" lib/db/daos/metadata_dao.dart
grep -n "algorithmOfflineModels" lib/db/database.g.dart | head
```

Every command must print at least one line.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart run build_runner build --delete-conflicting-outputs
dart format lib/db/tables.dart lib/db/database.dart lib/db/daos/metadata_dao.dart test/db/migrations/v13_to_v14_algorithm_offline_models_test.dart test/db/algorithm_offline_models_dao_test.dart test/db/io_flags_migration_test.dart test/db/migrations/v11_to_v12_template_metadata_test.dart
flutter analyze
flutter test test/db/migrations/v13_to_v14_algorithm_offline_models_test.dart test/db/algorithm_offline_models_dao_test.dart test/db/io_flags_migration_test.dart test/db/migrations/v11_to_v12_template_metadata_test.dart
git add lib/db/tables.dart lib/db/database.dart lib/db/database.g.dart lib/db/daos/metadata_dao.dart lib/db/daos/metadata_dao.g.dart test/db/migrations/v13_to_v14_algorithm_offline_models_test.dart test/db/algorithm_offline_models_dao_test.dart test/db/io_flags_migration_test.dart test/db/migrations/v11_to_v12_template_metadata_test.dart
git status --short
git commit -m "feat(metadata): persist offline shape profiles"
```

Only the files named by this step may appear before the commit.

### Commit message

`feat(metadata): persist offline shape profiles`

## STEP 3 of 8 — Add offline models to bundled metadata version 3

### Prerequisites

- STEP 2 committed with message `feat(metadata): persist offline shape profiles`.

### Files to edit

- Create `lib/services/full_metadata_format.dart`
- `lib/services/algorithm_json_exporter.dart`
- `lib/services/metadata_import_service.dart`
- `lib/services/algorithm_metadata_service.dart`
- Create `test/services/algorithm_offline_model_import_export_test.dart`
- `test/services/io_flags_import_export_test.dart`

### Required implementation

In `lib/services/full_metadata_format.dart`, add:

```dart
const int fullMetadataExportVersion = 3;

String offlineModelBundleDigest(List<Map<String, Object?>> modelRows)
```

The digest helper sorts rows by `algorithmGuid`, recursively sorts JSON map keys
without sorting lists, compact-encodes the row list, and returns lowercase
SHA-256 hex. Reject a row without a string `algorithmGuid`.

In `AlgorithmJsonExporter`:

- emit `fullMetadataExportVersion` as `exportVersion`;
- export factory-GUID model rows as `algorithmOfflineModels`;
- include all eight columns, including `origin`, and encode `capturedAt` as
  ISO-8601;
- add top-level `offlineModelBundleDigest`, computed from the exact exported row
  maps;
- add `totalAlgorithmOfflineModels` to summary and preview counts.

In `MetadataImportService.importFromJson`:

- require integer `exportVersion` in the inclusive range 1-3;
- return `false` for a missing, zero, negative, or greater version;
- keep version-1 and version-2 imports backward compatible when the model table
  and digest are absent;
- for version 3, require `algorithmOfflineModels` and
  `offlineModelBundleDigest`, recompute the digest, and reject a mismatch;
- decode every payload with `AlgorithmOfflineModel.fromJsonString` and reject a
  row whose GUID, model version, or coverage column disagrees with the payload;
- accept only row origins `hardware` or `bundled`;
- import the full document inside one database transaction so invalid model data
  leaves no partial flat or model rows.

Implement `importFromAsset` by loading the string and calling a private
`_importFromJson(String, {String? modelOriginOverride})` with
`modelOriginOverride: 'bundled'`. Public `importFromJson` calls the same private
method with no override. When an override is present, store that origin instead
of the row's exported origin and, after a successful version-3 import, save the
validated bundle digest.

Add these public methods:

```dart
Future<bool> importOfflineModelsFromAsset(String assetPath)
Future<bool> importOfflineModelsFromJson(String jsonString)
```

The asset method loads the string and delegates to the JSON method. The JSON
method accepts only a valid version-3 `full_metadata` document, then processes
each model row mechanically:

1. Skip it if its algorithm GUID is absent from the local `Algorithms` table.
2. Skip it if the existing row has origin `hardware`.
3. Otherwise insert/update it with origin forced to `bundled`.
4. Never change flat metadata tables.
5. Save the validated `offlineModelBundleDigest` only after every eligible row
   succeeds.

Tests call the JSON method; do not add a filesystem fallback to `rootBundle`.

In `AlgorithmMetadataService._checkAndImportBundledMetadata`:

- preserve the existing full-asset import when no algorithms exist;
- ensure model rows imported through the empty-database asset path have origin
  `bundled` and save the asset digest;
- when algorithms already exist, read the asset's
  `offlineModelBundleDigest` and compare it with
  `getBundledOfflineModelDigest()`;
- call `importOfflineModelsFromAsset` only when the digest differs;
- never overwrite flat metadata or hardware-origin models in this selective
  path.

Update current-export assertions in
`test/services/io_flags_import_export_test.dart` from 2 to 3 and include a valid
digest/model array in every version-3 fixture. Keep version-1/version-2 import
fixtures unchanged.

### Required tests

In `test/services/algorithm_offline_model_import_export_test.dart`, add:

1. `version 3 export includes factory offline models and bundle digest`
2. `version 3 full import round trips an offline model`
3. `version 2 import succeeds without offline models`
4. `unknown export version is rejected transactionally`
5. `bundle digest mismatch is rejected transactionally`
6. `selective bundle import replaces bundled model without changing flat parameters`
7. `selective bundle import preserves hardware model`
8. `selective bundle import skips a model whose algorithm is absent`
9. `changed version 3 bundle digest triggers another selective import`

Use temporary directories for exporter tests and `NativeDatabase.memory()` for
database tests. The transactional rejection test includes one valid flat
algorithm row followed by an invalid model and asserts neither was imported.

### Leftover checks

```bash
grep -n "fullMetadataExportVersion = 3" lib/services/full_metadata_format.dart
grep -n "offlineModelBundleDigest" lib/services/algorithm_json_exporter.dart
grep -n "importOfflineModelsFromAsset" lib/services/metadata_import_service.dart
grep -n "getBundledOfflineModelDigest" lib/services/algorithm_metadata_service.dart
grep -n "selective bundle import preserves hardware model" test/services/algorithm_offline_model_import_export_test.dart
```

Every command prints at least one line.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/services/full_metadata_format.dart lib/services/algorithm_json_exporter.dart lib/services/metadata_import_service.dart lib/services/algorithm_metadata_service.dart test/services/algorithm_offline_model_import_export_test.dart test/services/io_flags_import_export_test.dart
flutter analyze
flutter test test/services/algorithm_offline_model_import_export_test.dart test/services/io_flags_import_export_test.dart
git add lib/services/full_metadata_format.dart lib/services/algorithm_json_exporter.dart lib/services/metadata_import_service.dart lib/services/algorithm_metadata_service.dart test/services/algorithm_offline_model_import_export_test.dart test/services/io_flags_import_export_test.dart
git status --short
git commit -m "feat(metadata): bundle specification-aware profiles"
```

Only the six files named by this step may appear before the commit.

### Commit message

`feat(metadata): bundle specification-aware profiles`

## STEP 4 of 8 — Capture complete shapes in memory

### Prerequisites

- STEP 3 committed with message
  `feat(metadata): bundle specification-aware profiles`.

### Files to edit

- Create `lib/services/algorithm_shape_capture_service.dart`
- `lib/services/metadata_sync_service.dart`
- Create `test/services/algorithm_shape_capture_service_test.dart`
- `test/services/metadata_sync_service_output_mode_test.dart`
- `test/services/metadata_sync_service_test.dart`

### Required implementation

Create:

```dart
final class AlgorithmShapeCaptureException implements Exception { ... }

final class AlgorithmShapeCaptureService {
  AlgorithmShapeCaptureService(this._distingManager);

  Future<AlgorithmShapeSnapshot> capture({
    required AlgorithmInfo algorithm,
    required List<int> specificationValues,
    required String sourceFirmwareVersion,
    int algorithmIndex = 0,
  });
}
```

`capture` performs no database writes. It queries, in this order:

1. number of parameters;
2. parameter pages;
3. every parameter info in numeric order;
4. enum strings for every parameter with raw unit index 1;
5. output-mode usage for every parameter whose `isOutputMode` is true.

Throw `AlgorithmShapeCaptureException` when:

- number-of-parameters is absent or zero;
- pages response is absent;
- any parameter info is absent or reports a number different from the requested
  number;
- an enum response is absent, except for firmware `1.12.0`, GUID `maco`,
  parameter 1, which preserves the existing known skip;
- output-mode usage is absent for an output-mode parameter.

An empty enum list or empty affected-output list is valid when the response
itself exists. Copy all collections before creating the immutable snapshot.

Refactor `MetadataSyncService._syncInstantiatedAlgorithmParams` into two paths:

```dart
Future<AlgorithmShapeSnapshot> _captureInstantiatedAlgorithmShape(...)
Future<void> _persistRepresentativeShape(...)
```

The first delegates to `AlgorithmShapeCaptureService.capture`. The second takes
an already captured snapshot, resolves unit IDs using the existing unit map, and
replaces flat parameters, enums, pages, page items, and output-mode usage for the
GUID. It also converts the current `AlgorithmInfo` and its ordered
specifications to `AlgorithmEntry`/`SpecificationEntry`, then calls
`MetadataDao.replaceAlgorithmShapeMetadata` with `offlineModel: null`. STEP 6
passes the compiled model through the same DAO method so algorithm info,
specifications, flat shape, and model publish atomically. Do not use
`insertOrIgnore`; stale rows from a previous representative shape must be
removed.

Keep `_tryScanAlgorithm` behavior at one representative vector in this step.
After add/poll and before capture, call `requestAlgorithmGuid(0)` and require the
returned GUID and specification vector to equal the requested vector exactly.
Throw `AlgorithmShapeCaptureException` on a mismatch. Then capture once,
persist once, remove the algorithm in `finally`, and poll for an empty preset.
Multi-vector sampling belongs only to STEP 6.

### Required tests

In `test/services/algorithm_shape_capture_service_test.dart`, add:

1. `capture returns parameters enums pages and output mode usage`
2. `capture preserves numeric prefixes and concrete order`
3. `capture detects page-only shape differences at equal count`
4. `capture fails when parameter info is missing`
5. `capture fails when enum response is missing`
6. `capture preserves firmware 1.12 maco enum exception`
7. `capture fails when output mode usage response is missing`

Update existing sync tests to prove:

- the representative scan still sends the current useful count vector;
- flat persistence replaces stale parameters/pages/output usage rather than
  merging them;
- a clamped or stale returned specification vector is rejected before capture;
- removal is attempted when capture throws.

Do not weaken or remove existing timeout/reboot tests.

### Leftover checks

```bash
grep -n "class AlgorithmShapeCaptureService" lib/services/algorithm_shape_capture_service.dart
grep -n "_persistRepresentativeShape" lib/services/metadata_sync_service.dart
grep -n "insertOrIgnore" lib/services/metadata_sync_service.dart || true
grep -n "removal is attempted when capture throws" test/services/metadata_sync_service_test.dart
```

Expected: the first, second, and fourth commands print lines. The third prints
no lines in representative shape persistence.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/services/algorithm_shape_capture_service.dart lib/services/metadata_sync_service.dart test/services/algorithm_shape_capture_service_test.dart test/services/metadata_sync_service_output_mode_test.dart test/services/metadata_sync_service_test.dart
flutter analyze
flutter test test/services/algorithm_shape_capture_service_test.dart test/services/metadata_sync_service_output_mode_test.dart test/services/metadata_sync_service_test.dart
git add lib/services/algorithm_shape_capture_service.dart lib/services/metadata_sync_service.dart test/services/algorithm_shape_capture_service_test.dart test/services/metadata_sync_service_output_mode_test.dart test/services/metadata_sync_service_test.dart
git status --short
git commit -m "refactor(metadata): capture algorithm shapes in memory"
```

Only the files named by this step may appear before the commit.

### Commit message

`refactor(metadata): capture algorithm shapes in memory`

## STEP 5 of 8 — Plan probes and compile exact profiles

### Prerequisites

- STEP 4 committed with message
  `refactor(metadata): capture algorithm shapes in memory`.

### Files to edit

- Create `lib/services/algorithm_offline_model_compiler.dart`
- `lib/services/metadata_sync_service.dart`
- Create `test/services/algorithm_offline_model_compiler_test.dart`
- `test/services/metadata_sync_service_test.dart`

### Required implementation

Create these declarations:

```dart
const int maxExhaustiveAxisCardinality = 24;
const int maxCartesianProfiles = 128;

final class AlgorithmShapeScanReport { ... }
final class AlgorithmShapeEdgeDelta { ... }
final class AlgorithmOfflineModelCompilation { ... }

final class AlgorithmOfflineModelCompiler {
  List<List<int>> discoveryVectors(AlgorithmInfo algorithm);

  List<List<int>> completionVectors({
    required AlgorithmInfo algorithm,
    required List<AlgorithmShapeSnapshot> observations,
  });

  AlgorithmOfflineModelCompilation compile({
    required AlgorithmInfo algorithm,
    required String sourceFirmwareVersion,
    required List<AlgorithmShapeSnapshot> observations,
    required List<AlgorithmShapeCaptureFailure> failures,
  });
}
```

`AlgorithmShapeScanReport` has final, unmodifiable fields:

- `String algorithmGuid`
- `String sourceFirmwareVersion`
- `List<List<int>> successfulVectors`
- `List<AlgorithmShapeCaptureFailure> failures`
- `Map<String, String> fingerprintsByVector`
- `List<AlgorithmShapeEdgeDelta> edgeDeltas`
- `List<int> structuralSpecificationIndexes`
- `int cartesianProfileCount`
- `OfflineModelCoverage coverage`
- `int payloadBytes`

The key in `fingerprintsByVector` is the full vector encoded as compact JSON,
for example `[1,2]`. Add `toJson` for the debug/export report.

`AlgorithmShapeEdgeDelta` has unmodifiable `fromSpecificationValues`,
`toSpecificationValues`, `addedParameterEntityHashes`, and
`removedParameterEntityHashes`, plus `int specificationIndex`,
`bool pagesChanged`, `bool outputModeUsageChanged`, `String fromFingerprint`,
and `String toFingerprint`. Build added/removed lists by multiset occurrence
count and sort the resulting hash lists. Add `toJson`. Edge deltas are
diagnostic only and never drive profile resolution.

`AlgorithmOfflineModelCompilation` has exactly three fields:

- `AlgorithmOfflineModel model`
- `String specificationDefinitionHash`
- `AlgorithmShapeScanReport report`

Add this public pure helper beside `representativeSpecificationValues`:

```dart
String specificationDefinitionHashFor(List<Specification> specifications)
```

`discoveryVectors`:

1. Builds the safe-default baseline using `Specification.safeDefaultValue`.
2. Adds the current representative vector supplied by the same pure helper used
   by `MetadataSyncService._scanSpecValues`.
3. For each axis with cardinality <=24, adds every value with other axes at
   baseline.
4. For larger axes, adds unique in-range min, min+1, default, midpoint, max-1,
   and max values with other axes at baseline.
5. Adds every unique min/max corner across small axes only, with every large
   axis at baseline. It never combines large-axis maxima.
6. Deduplicates while preserving first occurrence.

Move the count-name representative-vector logic into a public pure helper in
this file:

```dart
List<int> representativeSpecificationValues(AlgorithmInfo algorithm)
```

In this same step, replace `MetadataSyncService._scanSpecValues` with a direct
call to `representativeSpecificationValues`. Delete the old private regex and
logic; do not leave duplicate implementations.

Structural-axis detection compares observations connected by an edge that
differs in exactly one specification index. An axis is structural when at least
one such edge has different fingerprints. This includes one-axis sweeps and
min/max-corner edges.

`completionVectors` computes the Cartesian product of every axis whose
cardinality is at most 24, holds every larger axis at baseline, and returns only
missing vectors. Return an empty list when that complete small-axis product
exceeds 128. Do not use detected structural axes to reduce this proof set.

`compile` is deterministic:

- deduplicate observations by full vector; conflicting fingerprints for the
  same vector throw `StateError`;
- derive structural indexes using the edge rule;
- pool `AlgorithmShapeParameter` values by `entityHash`;
- create an exact profile for every observation;
- mark `verified` only when `failures` is empty, there are no large axes, the
  complete axis product is at most 128, and every vector in that product is
  present;
- otherwise mark `partial`; use `unsupported` only when observations are empty;
- decode the produced JSON and expand every profile, then require its
  fingerprint to equal the source observation before returning;
- compute the specification-definition hash from ordered name/min/max/default/
  type data using canonical JSON and SHA-256;
- produce `AlgorithmShapeScanReport` containing GUID, firmware version,
  successful/failed vectors, fingerprints, structural indexes,
  Cartesian size, coverage, payload byte count, and error strings.

Do not infer parameter-name templates or repeat nodes. Profile pages retain
concrete parameter numbers. Profile output-mode usage retains concrete
parameter-number keys.

### Required tests

Use synthetic snapshot builders; do not require MIDI hardware. Add exactly:

1. `discovery includes all values for a small axis`
2. `discovery samples six bounded values for a large axis`
3. `discovery corners never combine large axis maxima`
4. `representative vector preserves useful count heuristic`
5. `compiler marks Quantizer 1 through 12 verified`
6. `compiler captures Mixer channel send interactions exactly`
7. `same count enum or page change marks an axis structural`
8. `completion stops when Cartesian product exceeds 128`
9. `failed vector produces partial coverage`
10. `partial model retains exact full-vector profiles`
11. `compiler rejects conflicting observations for one vector`
12. `compiled profile replay matches every source fingerprint`
13. `interior-only interaction is captured by the small-axis Cartesian product`
14. `scan spec values delegates to representative helper`
15. `edge deltas identify repeated parameter entities by specification axis`
16. `large axis remains partial even when every probe succeeds`

The Mixer fixture uses Channels 1-3 and Sends 0-2 and must produce nine distinct
profiles. At least one parameter appears only when both channel and send are
above their minima.

### Leftover checks

```bash
grep -n "maxExhaustiveAxisCardinality = 24" lib/services/algorithm_offline_model_compiler.dart
grep -n "maxCartesianProfiles = 128" lib/services/algorithm_offline_model_compiler.dart
grep -n "representativeSpecificationValues" lib/services/algorithm_offline_model_compiler.dart
grep -n "compiler captures Mixer channel send interactions exactly" test/services/algorithm_offline_model_compiler_test.dart
grep -n "repeat" lib/services/algorithm_offline_model_compiler.dart || true
```

The first four commands print lines. The final command may contain explanatory
comments but must not show a repeat-rule model declaration.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/services/algorithm_offline_model_compiler.dart lib/services/metadata_sync_service.dart test/services/algorithm_offline_model_compiler_test.dart test/services/metadata_sync_service_test.dart
flutter analyze
flutter test test/models/algorithm_offline_model_test.dart test/services/algorithm_offline_model_compiler_test.dart test/services/metadata_sync_service_test.dart
git add lib/services/algorithm_offline_model_compiler.dart lib/services/metadata_sync_service.dart test/services/algorithm_offline_model_compiler_test.dart test/services/metadata_sync_service_test.dart
git status --short
git commit -m "feat(metadata): compile exact specification profiles"
```

Only the four files named by this step may appear before the commit.

### Commit message

`feat(metadata): compile exact specification profiles`

## STEP 6 of 8 — Integrate multi-vector sampling into metadata sync

### Prerequisites

- STEP 5 committed with message
  `feat(metadata): compile exact specification profiles`.

### Files to edit

- `lib/services/metadata_sync_service.dart`
- `test/services/metadata_sync_service_test.dart`
- Create `test/services/metadata_sync_service_offline_models_test.dart`

### Required implementation

Add these private methods to `MetadataSyncService`:

```dart
Future<AlgorithmShapeSnapshot> _captureSpecificationVector({
  required AlgorithmInfo algorithm,
  required List<int> specificationValues,
  required FirmwareVersion firmwareVersion,
  bool Function()? checkCancel,
})

Future<_AlgorithmModelScanResult?> _scanAlgorithmModel({
  required AlgorithmInfo algorithm,
  required FirmwareVersion firmwareVersion,
  bool Function()? checkCancel,
  void Function(String message)? onStatus,
})
```

`_captureSpecificationVector` follows add, poll-for-one, capture, and
remove-in-`finally`, followed by poll-for-zero. It passes a copied vector to the
MIDI manager. After poll-for-one, call `requestAlgorithmGuid(0)` and require the
returned GUID and specification vector to equal the request before capture. If
they differ, record/throw a capture failure for the requested vector. If cleanup
cannot confirm zero algorithms, throw and do not continue the algorithm scan.

Extend `syncAllAlgorithmMetadata` with this optional named parameter:

```dart
void Function(AlgorithmShapeScanReport report)? onShapeReport
```

Add a private report list, clear it at the beginning of each full sync, append
only after a model publishes, invoke `onShapeReport` with the same report, and
expose `List<AlgorithmShapeScanReport> get lastShapeScanReports` as an
unmodifiable copy. This is the supported report delivery path used by tooling
and tests.

`_scanAlgorithmModel`:

1. Captures every discovery vector sequentially.
2. Records optional-vector failures without deleting prior flat/model data.
3. Requires the representative vector to succeed. If it fails, rethrow through
   the existing algorithm retry/cleanup path.
4. Calls `completionVectors` after discovery and captures the returned vectors.
5. Checks cancellation before every add and after every cleanup.
6. On cancellation, returns `null` after cleanup.
7. Compiles the observations and failures.
8. Returns the representative snapshot, model, specification-definition hash,
   and scan report without writing the database.

Keep the current timeout behavior for the required representative vector:
reboot and retry once, then use the existing deferred retry. For optional probe
timeouts, run the same single reboot/reconnect retry; after the second failure,
record a failed vector, restore an empty preset, mark the model partial, and
continue with the next vector.

`_AlgorithmModelScanResult` has exactly two fields:

- `AlgorithmShapeSnapshot representativeSnapshot`
- `AlgorithmOfflineModelCompilation compilation`

After a complete non-cancelled algorithm scan, construct an
`AlgorithmOfflineModelEntry` with origin `hardware` and pass it with the
representative row lists to the one
`MetadataDao.replaceAlgorithmShapeMetadata` call:

- representative flat metadata;
- one `AlgorithmOfflineModelEntry` containing compiler JSON and coverage;
- captured time and firmware version.

`_persistRepresentativeShape` accepts the optional model entry and delegates the
entire replacement to that DAO operation. If compilation, validation,
cancellation, or publication fails, the previously stored flat shape and model
remain unchanged.

Make full sync non-destructive to the database:

- remove the initial `metadataDao.clearAllMetadata()` call;
- continue clearing only the device preset before scanning;
- keep discovered factory `AlgorithmInfo` objects in memory and do not upsert
  their algorithm/specification rows ahead of shape capture; publish those rows
  only through the per-algorithm atomic DAO operation;
- keep unit-string persistence and the algorithm-info cache on their existing
  non-shape paths;
- change `_cleanupFailedAlgorithm` so scan failure cleans the device preset but
  never deletes previously published flat/model rows;
- only after a non-cancelled full scan completes, find previously cached factory
  GUIDs absent from the device's current factory GUID set;
- preserve every absent GUID referenced by any `PresetSlots` row, including its
  prior flat metadata and model;
- for each absent, unreferenced GUID, call `clearAlgorithmMetadata` and then
  delete its `Algorithms` parent row.

Existing algorithm-level resume checkpoints
remain at algorithm granularity; resuming may repeat the current algorithm but
must not publish half of it.

Progress submessages use these exact forms:

```text
Sampling <algorithm name> [<comma-separated values>] (<current>/<total>)
Compiling offline profiles for <algorithm name>
```

Do not add UI controls or a success snackbar.

### Required tests

Keep all existing tests. Add to `metadata_sync_service_test.dart`:

1. `vector cleanup runs before the next vector is added`
2. `returned specification mismatch is rejected before capture`
3. `full sync does not clear previously published metadata up front`
4. `required representative failure preserves prior algorithm metadata`
5. `cancellation preserves prior algorithm metadata and leaves preset empty`
6. `successful full sync prunes unreferenced absent factory GUIDs`
7. `successful full sync preserves absent factory GUIDs used by presets`

In `metadata_sync_service_offline_models_test.dart`, add:

1. `Quantizer sync publishes twelve exact channel profiles`
2. `Mixer sync publishes complete channel send Cartesian profiles`
3. `page-only differences are persisted as distinct profiles`
4. `optional probe failure publishes a partial model`
5. `compiler validation failure publishes neither flat shape nor model`
6. `progress identifies the active specification vector`
7. `published reports are returned through callback and last report list`

Use a programmable fake MIDI manager keyed by specification vector. It must
return different complete snapshots for Quantizer and Mixer; do not mock the
compiler itself.

### Leftover checks

```bash
grep -n "representativeSpecificationValues" lib/services/metadata_sync_service.dart
grep -n "_captureSpecificationVector" lib/services/metadata_sync_service.dart
grep -n "_scanAlgorithmModel" lib/services/metadata_sync_service.dart
grep -n "removeAlgorithm" lib/services/metadata_sync_service.dart | head
grep -n "Quantizer sync publishes twelve exact channel profiles" test/services/metadata_sync_service_offline_models_test.dart
```

Every command prints at least one line.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/services/metadata_sync_service.dart test/services/metadata_sync_service_test.dart test/services/metadata_sync_service_offline_models_test.dart
flutter analyze
flutter test test/services/metadata_sync_service_test.dart test/services/metadata_sync_service_output_mode_test.dart test/services/metadata_sync_service_offline_models_test.dart
git add lib/services/metadata_sync_service.dart test/services/metadata_sync_service_test.dart test/services/metadata_sync_service_offline_models_test.dart
git status --short
git commit -m "feat(metadata): sample specification-aware metadata"
```

Only the three files named by this step may appear before the commit.

### Commit message

`feat(metadata): sample specification-aware metadata`

## STEP 7 of 8 — Resolve offline metadata from slot specifications

### Prerequisites

- STEP 6 committed with message
  `feat(metadata): sample specification-aware metadata`.

### Files to edit

- Create `lib/services/algorithm_offline_model_resolver.dart`
- `lib/domain/offline_disting_midi_manager.dart`
- Create `test/services/algorithm_offline_model_resolver_test.dart`
- `test/domain/offline_disting_midi_manager_specifications_test.dart`
- `test/domain/offline_disting_midi_manager_test.dart`

### Required implementation

Create:

```dart
final class AlgorithmOfflineModelResolver {
  AlgorithmOfflineModelResolver(this._metadataDao);

  Future<ResolvedAlgorithmShape> resolve({
    required String algorithmGuid,
    required List<int> specificationValues,
  });

  void clear();
}
```

Cache by an immutable key containing GUID and the complete specification vector.
Cache the future so concurrent requests for one slot shape share one DAO load.
Remove a failed future from the cache before rethrowing.

Resolution follows the exact order in `spec.md`. Load
`MetadataDao.getFullAlgorithmDetails` first so its ordered specifications can be
hashed with `specificationDefinitionHashFor` and it is already available for
fallback:

1. Decode a compatible model row.
2. For either persisted coverage, select a profile whose complete
   `specificationValues` equals the request.
3. Otherwise use the already loaded `MetadataDao.getFullAlgorithmDetails` plus
   output-mode usage
   and build a `legacy` shape.

Also fall back to legacy when model version, JSON, parameter reference,
specification-vector length, or specification-definition hash validation fails.
The resolver must not throw for corrupt cached model data when valid flat
metadata exists.

Expanding a profile:

- converts each ordered parameter ref to one `AlgorithmShapeParameter`;
- verifies the expanded snapshot fingerprint before returning;
- retains concrete list positions as parameter numbers;
- returns profile pages and output-mode usage unchanged.

In `OfflineDistingMidiManager`:

- create one resolver from `_metadataDao` in the constructor;
- add `_resolvedShape(int algorithmIndex)` that validates the index and calls
  resolver with `_presetAlgorithmGuids[index]` and
  `_presetSpecificationValues[index]`;
- route `requestNumberOfParameters`, `requestParameterInfo`,
  `requestParameterEnumStrings`, `requestParameterPages`, and
  `requestOutputModeUsage` through that one resolved shape;
- supply the caller's `algorithmIndex` and requested parameter number when
  constructing `ParameterInfo`, `ParameterEnumStrings`, `ParameterPages`, and
  `OutputModeUsage`;
- return the same filler/null conventions each method currently uses for invalid
  indexes or missing parameters;
- call resolver `clear()` in `initializeFromDb`, after successful algorithm add,
  remove, move, preset load, and new-preset operations. Do not change the stored
  specification vectors themselves.

Add this read-only public diagnostic method to
`OfflineDistingMidiManager` only; do not add it to `IDistingMidiManager`:

```dart
Future<OfflineModelCoverage?> offlineMetadataCoverageForSlot(
  int algorithmIndex,
)
```

It returns `null` for an invalid slot and otherwise returns the coverage of the
same resolved shape used by the five metadata methods.

Do not leave direct reads of `parameters`, `parameterEnums`, `parameterPages`,
`parameterPageItems`, or `parameterOutputModeUsage` inside those five request
methods.

### Required tests

`test/services/algorithm_offline_model_resolver_test.dart`:

1. `verified model resolves an exact specification vector`
2. `verified model does not synthesize an unmeasured vector`
3. `partial profile requires an exact full vector`
4. `corrupt model falls back to legacy flat metadata`
5. `profile fingerprint mismatch falls back to legacy`
6. `repeated resolutions use cached model until clear`
7. `clear reloads an updated model`

Update offline manager tests with:

1. `four channel Quantizer uses four channel profile`
2. `Mixer channel send profile drives count info enums pages and output usage`
3. `all five metadata methods agree on one resolved shape`
4. `unmeasured vector uses legacy metadata`
5. `algorithm mutations clear resolved shape cache`
6. `coverage query exposes verified partial and legacy resolution`

The Quantizer fixture must have one-, four-, and twelve-channel profiles. Assert
that Channels 4 returns the exact expected count and includes `Channel 4` page
membership. The Mixer fixture must prove an output-mode parameter and its page
shift together when Sends changes.

### Leftover checks

```bash
grep -n "class AlgorithmOfflineModelResolver" lib/services/algorithm_offline_model_resolver.dart
grep -n "Future<ResolvedAlgorithmShape.*_resolvedShape" lib/domain/offline_disting_midi_manager.dart
grep -n "_metadataDao.parameters" lib/domain/offline_disting_midi_manager.dart || true
grep -n "four channel Quantizer uses four channel profile" test/domain/offline_disting_midi_manager_specifications_test.dart
```

Expected: the first, second, and fourth commands print lines. The third prints no
lines in the five migrated request paths; other non-shape uses must also be
rewritten through DAO helpers if the grep would otherwise fail this check.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/services/algorithm_offline_model_resolver.dart lib/domain/offline_disting_midi_manager.dart test/services/algorithm_offline_model_resolver_test.dart test/domain/offline_disting_midi_manager_specifications_test.dart test/domain/offline_disting_midi_manager_test.dart
flutter analyze
flutter test test/services/algorithm_offline_model_resolver_test.dart test/domain/offline_disting_midi_manager_specifications_test.dart test/domain/offline_disting_midi_manager_test.dart test/domain/offline_lfo_routing_test.dart
git add lib/services/algorithm_offline_model_resolver.dart lib/domain/offline_disting_midi_manager.dart test/services/algorithm_offline_model_resolver_test.dart test/domain/offline_disting_midi_manager_specifications_test.dart test/domain/offline_disting_midi_manager_test.dart
git status --short
git commit -m "fix(offline): resolve metadata by specifications"
```

Only the five files named by this step may appear before the commit.

### Commit message

`fix(offline): resolve metadata by specifications`

## STEP 8 of 8 — Produce and validate the hardware-derived bundle

### Prerequisites

- STEP 7 committed with message
  `fix(offline): resolve metadata by specifications`.
- A physical disting NT is connected through the app's normal MIDI path.
- The device is on the firmware version intended for the bundle.
- Any wanted device preset has been saved elsewhere; this scan clears it.
- The app is already running in debug mode if a debug session is active. Do not
  restart an already-running app solely for this step.

If any hardware prerequisite is false, do not fabricate or hand-edit model
payloads. Report `BLOCKED: physical metadata scan prerequisite missing` and stop
without a commit.

### Files to edit

- `assets/metadata/full_metadata.json` (generated by real sync/export only)
- `docs/metadata-collection-process.md`
- Create `test/domain/offline_bundled_specification_profiles_test.dart`

### Required procedure

1. In the existing Offline Data metadata-sync UI, run **Sync All Algorithms**.
2. Confirm the scan begins from an empty device preset.
3. Let the scan finish without disconnecting MIDI.
4. If any algorithm reports a failed required representative vector, stop and
   repair the implementation; do not export.
5. Optional probe failures may remain only when the affected model is `partial`
   and the report names every failed vector.
6. Use the existing debug metadata export dialog to export
   `full_metadata.json`.
7. Copy that generated export to `assets/metadata/full_metadata.json` using the
   normal file copy operation. Do not modify JSON by hand.
8. Update `docs/metadata-collection-process.md`:
   - change format references from version 2 to version 3;
   - document `algorithmOfflineModels` and coverage statuses;
   - document `offlineModelBundleDigest` and hardware/bundled origins;
   - document the scan report fields and the two sampling caps;
   - replace obsolete expected file-size text with the actual byte count;
   - add Quantizer Channels 1, 4, and 12 and Mixer `Channels x Sends` to the
     spot-check list;
   - state that unknown export versions are rejected;
   - state that version-3 model rows selectively upgrade existing databases;
   - keep the existing explicit device-preset warning.

### Required asset validation

Run these commands exactly:

```bash
cd /Users/nealsanche/nosuch/nt_helper
jq -e '.exportType == "full_metadata" and .exportVersion == 3' assets/metadata/full_metadata.json
jq -e '.offlineModelBundleDigest | type == "string" and test("^[0-9a-f]{64}$")' assets/metadata/full_metadata.json
jq -e '.tables.algorithmOfflineModels | type == "array" and length > 0' assets/metadata/full_metadata.json
jq -e '[.tables.algorithmOfflineModels[] | select(.coverage == "verified" or .coverage == "partial" or .coverage == "unsupported")] | length == (.tables.algorithmOfflineModels | length)' assets/metadata/full_metadata.json
jq -e '[.tables.algorithmOfflineModels[] | select(.algorithmGuid == "quan")] | length == 1' assets/metadata/full_metadata.json
jq -r '.tables.algorithmOfflineModels[] | select(.algorithmGuid == "quan") | .payloadJson' assets/metadata/full_metadata.json | jq -e '([.profiles[].specificationValues[0]] | unique | index(4)) != null'
jq -e '[.tables.algorithmOfflineModels[] | select(.algorithmGuid == "mix1" or .algorithmGuid == "mix2")] | length == 2' assets/metadata/full_metadata.json
```

Every `jq -e` command must exit 0. Then run the program-level verification.

Create
`test/domain/offline_bundled_specification_profiles_test.dart`. It imports the
actual `assets/metadata/full_metadata.json` into `NativeDatabase.memory()` using
the production `MetadataImportService`, constructs
`AlgorithmOfflineModelResolver`, and adds exactly these tests:

1. `fresh bundled import resolves Quantizer channels 1 4 and 12`
2. `fresh bundled import resolves Mixer channel send profiles`
3. `fresh bundled import marks imported models bundled origin`
4. `fresh bundled import validates the model bundle digest`

The Quantizer test asserts the Channels 4 resolved pages include `Channel 4`
and omit `Channel 5`. The Mixer test resolves `mix1` at Channels 3/Sends 2 and
Channels 8/Sends 4 and asserts different expected fingerprints. Do not seed
model rows manually; the asset is the only model source in this test.

### Manual hardware/offline checks

Using the real app and generated bundle:

1. Create or load an offline Quantizer with Channels 4.
2. Confirm pages include Channel 1 through Channel 4 and do not include Channel
   5.
3. Compare its parameter count with a connected hardware Quantizer Channels 4.
4. Repeat parameter-count/page checks at Channels 1 and 12.
5. In offline mode, test Mixer Mono with Channels 3/Sends 2 and Channels 8/Sends
   4; confirm counts, page membership, enum strings, and output-mode usage match
   the corresponding connected shapes.
6. Select one deliberately partial/unmeasured vector from the scan report and
   confirm the manager uses legacy fallback rather than a fabricated profile.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart run build_runner build --delete-conflicting-outputs
dart format test/domain/offline_bundled_specification_profiles_test.dart
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
git add assets/metadata/full_metadata.json docs/metadata-collection-process.md test/domain/offline_bundled_specification_profiles_test.dart
git status --short
git commit -m "chore(metadata): refresh specification-aware metadata bundle"
```

Only the three files named by this step may appear before the commit. Generated
Dart files must be unchanged at this point; if `build_runner`
changes one, return to the step that failed to commit its generated output.

### Commit message

`chore(metadata): refresh specification-aware metadata bundle`

## Completion audit

Run after STEP 8:

```bash
cd /Users/nealsanche/nosuch/nt_helper
grep -A2 "Commit message" specs/specification-aware-offline-metadata/plan.md
spec_program_start=$(git log -1 --format=%H -- specs/specification-aware-offline-metadata/plan.md)
git log --format=%s "${spec_program_start}..HEAD"
git status --short --branch
```

Expected implementation commits, exactly once and in this order:

1. `feat(metadata): define specification-aware shape models`
2. `feat(metadata): persist offline shape profiles`
3. `feat(metadata): bundle specification-aware profiles`
4. `refactor(metadata): capture algorithm shapes in memory`
5. `feat(metadata): compile exact specification profiles`
6. `feat(metadata): sample specification-aware metadata`
7. `fix(offline): resolve metadata by specifications`
8. `chore(metadata): refresh specification-aware metadata bundle`

The final worktree must be clean and `main` must be pushed through the repo's
normal release workflow only after all program-level verification passes.
