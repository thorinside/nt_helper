# Specification-aware offline algorithm metadata

Status: design specification only; no production code is implemented by this
spec-authoring commit.

Baseline ref: `4ef03442` (`main` at spec authoring time)

Hardening policy: conservative measurement. Hardware observations are facts;
names and inferred repetition are only hints. An unmeasured shape is never
presented as verified.

Primary verification command after implementation:

```bash
flutter analyze && flutter test
```

## Summary

Offline algorithm metadata must be resolved as a function of both the algorithm
and the specification values used to instantiate it:

```text
shape = F(algorithm GUID, specification values)
```

The current database instead stores one parameter/page shape per algorithm GUID.
`MetadataSyncService` instantiates each algorithm once. It starts with each
specification's safe default and raises count-like specifications such as
Channels, Sends, Stereo, or Voices to a useful value, usually `2`. It then writes
that one observed shape into GUID-keyed tables. Offline slots remember their
actual specification values, but parameter count, parameter information, enums,
pages, and output-mode usage are still read from the GUID-only shape.

That behavior is a useful representative sample, not a specification-aware
model. The bundled Quantizer metadata demonstrates the mismatch:

- Quantizer (`quan`) declares `Channels`, range 1-12, default 1.
- The current scan selects 2.
- The bundle contains 164 parameters and only `Channel 1` and `Channel 2` pages.
- A four-channel offline Quantizer therefore cannot expose the hardware's
  four-channel parameter shape.

The proposed solution is deliberately smaller than a general repeat-rule
language. It stores exact measured shapes, deduplicates their parameter
definitions, and indexes them by the complete specification vector. The full
Cartesian product of small axes is enumerated when it fits the cap. Large or
ambiguous domains remain partial and fall back explicitly.

## Repository evidence

| Observation | Current source |
|---|---|
| One scan vector is chosen for each algorithm | `MetadataSyncService._scanSpecValues` in `lib/services/metadata_sync_service.dart` |
| One algorithm instance is queried and directly persisted | `MetadataSyncService._tryScanAlgorithm` and `_syncInstantiatedAlgorithmParams` |
| Parameter/page metadata keys omit specifications | `Parameters`, `ParameterEnums`, `ParameterPages`, `ParameterPageItems`, and `ParameterOutputModeUsage` in `lib/db/tables.dart` |
| Offline slots retain specification values | `_presetSpecificationValues` and `requestAlgorithmGuid` in `lib/domain/offline_disting_midi_manager.dart` |
| Offline shape requests still query GUID-only tables | `requestNumberOfParameters`, `requestParameterInfo`, `requestParameterEnumStrings`, `requestParameterPages`, and `requestOutputModeUsage` in `lib/domain/offline_disting_midi_manager.dart` |
| Bundled export is a flat version-2 format | `AlgorithmJsonExporter.exportFullMetadata` and `assets/metadata/full_metadata.json` |

At spec authoring time, the bundle is 10,636,093 bytes and contains 69 factory
algorithms with specifications, 88 specification axes, and at most three axes
on one algorithm. Seventy-four axes have 24 or fewer integer values. These
figures make bounded exhaustive sampling practical: at authoring time only two
factory algorithms have a small-axis Cartesian product above 128. Exhaustive
sampling of every raw specification remains impractical because large resource
ranges exist.

The [official disting NT manual](https://www.expert-sleepers.co.uk/downloads/manuals/disting_NT_user_manual_1.12.pdf)
also explicitly describes algorithms whose number of parameters varies with
their specifications and parameter names that receive channel prefixes. The
hardware response remains the source of truth; the manual is supporting
context, not input to the compiler.

## Goals

- Make a four-channel Quantizer expose the same offline parameter count,
  definitions, enums, pages, and output-mode relationships as hardware.
- Support multiple interacting structural axes, including Mixer
  `Channels x Sends`.
- Discover structural behavior from complete hardware snapshots rather than
  trusting English specification or parameter names.
- Store exact shapes compactly enough for the bundled metadata asset and local
  Drift database.
- Treat `assets/metadata/full_metadata.json` as the shipping artifact: a fresh
  offline installation must receive the same specification-aware models without
  performing its own hardware scan.
- Keep current flat metadata available as a backward-compatible representative
  shape for search, documentation, old exports, and unsupported algorithms.
- Publish a model only after every profile it claims to cover has been captured
  successfully and can be decoded back to the same canonical fingerprint.
- Make incomplete coverage visible to code and diagnostics instead of silently
  claiming correctness.

## Non-goals for version 1

- Do not build a general-purpose symbolic repeat grammar.
- Do not generate parameter names from templates such as `${channel}:Name`.
- Do not use an LLM, manual algorithm-name list, or regex as correctness logic.
- Do not enumerate large resource ranges such as long history or time ranges.
- Do not scan custom plug-ins into the bundled factory metadata asset.
- Do not capture shapes opportunistically during normal connected use.
- Do not change how a new preset chooses or forgets specification values.
- Do not add a user-facing editor for inferred metadata models.
- Do not delete or specification-dimension the existing flat metadata tables.

## Options considered

### One representative shape per GUID

This is the current design. It is cheap, but it cannot answer a request for a
shape other than the one scan vector. It remains only as the compatibility
fallback.

### Full snapshot for every raw specification tuple

This is exact and has a simple resolver. It is rejected as the universal model
because large ranges and Cartesian products can explode. Exact snapshots are
still the evidence and fallback unit.

### Automatically inferred repeat recipes

Minimum, maximum, and interior samples can often reveal a repeated block. This
is compact, but minimum/maximum alone cannot prove intermediate behavior, and
independent axis rules cannot prove `Channels x Sends` interactions. A symbolic
recipe compiler is deferred until storage measurements show it is needed.

### Exact profile catalog with shared entities (selected)

Capture complete shapes for the capped small-axis domain, store parameter
definitions once in a content-addressed pool, and let each exact profile refer
to an ordered list of those definitions. Pages and output-mode relationships
remain profile-specific because they use concrete parameter positions.

This design solves the actual offline lookup without guessing a formula. It
also leaves a clean future optimization point: a verified recipe can later be
compiled behind the same resolver without changing offline callers.

## Vocabulary

| Term | Meaning |
|---|---|
| Specification vector | Ordered integer values passed when adding an algorithm |
| Shape snapshot | Complete structural metadata observed from one successfully instantiated vector |
| Fingerprint | SHA-256 of the canonical JSON form of a shape snapshot |
| Structural axis | Specification index for which at least one successful probe changes the shape fingerprint |
| Profile | One exact, persisted shape selected by a specification key |
| Parameter entity | Parameter metadata plus enum strings, excluding algorithm index and concrete parameter number |
| Verified model | Every specification axis is small and the full Cartesian product was captured within the configured cap |
| Partial model | Some exact profiles exist, but one or more requested vectors are not proven |
| Legacy fallback | The existing GUID-only metadata shape |

## Complete shape snapshot contract

`AlgorithmShapeSnapshot` is immutable and contains:

- algorithm GUID;
- full specification vector used for instantiation;
- ordered parameters, each with name, min, max, default, raw unit index,
  power-of-ten, `ioFlags`, and ordered enum strings;
- ordered pages, each with its name and ordered concrete parameter numbers;
- output-mode usage keyed by concrete parameter number with ordered affected
  output numbers;
- source firmware version;
- a shape-only canonical fingerprint.

It does not contain current parameter values, mappings, routings, custom slot
names, or preset state.

Fingerprint canonicalization rules are fixed:

1. Preserve parameter order, enum order, page order, page-item order, and the
   order of each profile's parameter references.
2. Exclude algorithm GUID, specification values, firmware version, and the
   fingerprint itself. They are provenance/selectors, not shape.
3. Sort affected output-number lists when constructing the immutable snapshot.
   The recursive JSON canonicalizer then sorts map keys but never sorts lists.
4. Encode absent enum/output-mode data as empty collections, not `null`.
5. Exclude `algorithmIndex` because scan slot 0 and offline slot indexes differ.
6. Include concrete parameter numbers in the snapshot fingerprint because page
   and output-mode references use them.
7. Encode output-mode map keys as base-10 JSON strings and reject non-integer or
   negative keys while decoding.
8. Encode integers as JSON integers and strings without normalization.
9. Compute SHA-256 over UTF-8 bytes of the compact canonical JSON.

Two snapshots are the same shape only when their fingerprints match. Equal
parameter counts are insufficient.

## Sampling policy

Use these fixed limits in version 1:

```text
maxExhaustiveAxisCardinality = 24
maxCartesianProfiles = 128
```

The baseline vector uses `Specification.safeDefaultValue` for every axis. The
current count-name heuristic is retained only for the legacy representative
flat shape; it is not used by the shape-model sampler.

For each algorithm, sampling proceeds mechanically:

1. Capture the baseline vector.
2. For each axis with cardinality at most 24, capture every value for that axis
   while all other axes remain at baseline.
3. For each larger axis, capture the unique in-range values from:
   `min`, `min + 1`, `safe default`, integer midpoint, `max - 1`, and `max`.
4. Compute the Cartesian product of every axis whose cardinality is at most 24,
   holding every larger axis at baseline.
5. If that product is at most 128, capture it completely; this detects interior
   interactions. It produces `verified` coverage only when no large axis exists.
6. If the product exceeds 128, capture only unique min/max corners of the small
   axes, keep exact observed profiles, and mark the model partial. Never combine
   maximum values of large resource axes.
7. Mark an axis structural for diagnostics when any successful pair of probes
   that differs in exactly that axis has different shape fingerprints.
8. A failed or timed-out instantiation is recorded as failed evidence. It is
   never interpreted as an unchanged shape.
9. Cancellation stops after device cleanup and before model publication.

The scanner may use names such as Channels, Sends, Voices, or Stereo to order
likely high-value probes first. Names must not change which vectors are required
or whether a model is verified.

### What “this property repeats for this specification” means

The compiler reports evidence, not a semantic guess. For every pair of captured
vectors that differs in exactly one specification index, it records:

- the changed specification index and from/to vectors;
- added and removed parameter-entity hashes, preserving duplicate counts;
- whether pages changed;
- whether output-mode usage changed;
- the before/after shape fingerprints.

An entity whose occurrence count grows on edges of axis 0 is therefore observed
to repeat with axis 0. A metadata mutation appears as one removed entity hash
and one added entity hash. These edge deltas explain the model and identify
structural axes, but runtime correctness still comes only from exact profiles.

### Coverage classification

| Status | Required evidence | Runtime behavior |
|---|---|---|
| `verified` | Every axis has cardinality at most 24, the complete Cartesian product is at most 128 and captured, all captures succeeded, and encode/decode fingerprint validation passes | Resolve exact captured vectors; the complete specification domain is represented |
| `partial` | At least one exact snapshot exists, but a large axis, failed vector, cap, or unproven non-baseline axis prevents full coverage | Resolve only an exact full-vector profile; otherwise use legacy fallback |
| `unsupported` | No valid model payload can be built | Always use legacy fallback |

A model with any large axis is `partial`. A request with an unmeasured large-axis
value therefore falls back unless its exact full-vector profile was captured.

## Persisted model

Add one Drift table and keep the six existing flat shape tables unchanged:

### `AlgorithmOfflineModels`

| Column | Type | Contract |
|---|---|---|
| `algorithmGuid` | text primary key, FK to `Algorithms.guid` | One current model per algorithm |
| `modelVersion` | integer | `1` for this payload schema |
| `sourceFirmwareVersion` | nullable text | Firmware reported during capture |
| `specificationDefinitionHash` | text | Hash of ordered spec name/min/max/default/type definitions |
| `coverage` | text | `verified`, `partial`, or `unsupported` |
| `origin` | text | `hardware` for a local scan or `bundled` after asset import |
| `payloadJson` | text | Compact JSON payload below |
| `capturedAt` | datetime | Completion time of the published scan |

The table is intentionally a versioned document rather than six more
specification-dimensional relational tables. Offline resolution consumes one
shape at a time, and the JSON schema will be easier to evolve after real scans.

The version-1 payload has this exact top-level shape:

```json
{
  "formatVersion": 1,
  "algorithmGuid": "quan",
  "coverage": "verified",
  "baselineSpecificationValues": [1],
  "structuralSpecificationIndexes": [0],
  "largeSpecificationIndexes": [],
  "parameterPool": {
    "<sha256>": {
      "name": "1:Input",
      "min": 0,
      "max": 28,
      "defaultValue": 1,
      "unit": 0,
      "powerOfTen": 0,
      "ioFlags": 4,
      "enumStrings": []
    }
  },
  "profiles": [
    {
      "specificationValues": [1],
      "profileKey": "0=1",
      "parameterRefs": ["<sha256>"],
      "pages": [
        {"name": "Channel 1", "parameterNumbers": [0]}
      ],
      "outputModeUsage": {},
      "fingerprint": "<sha256>"
    }
  ],
  "failedVectors": []
}
```

Parameter-pool hashes are computed from the canonical parameter entity JSON.
`parameterRefs` may contain the same hash more than once; list position assigns
the concrete parameter number. `profileKey` contains structural
`specIndex=value` pairs in ascending index order, joined by commas. A model with
no structural axes uses the empty string.

For both `partial` and `verified` models, profile selection compares the entire
requested vector to `specificationValues`. `profileKey` and coverage are
diagnostic/indexing data and do not authorize the resolver to synthesize an
unobserved vector. This is the central version-1 simplification.

## Transaction and provenance rules

- Capture every probe into immutable memory first. Do not upsert a probe into
  the current flat tables.
- Continue writing one representative snapshot to the flat tables so old
  consumers remain functional.
- Compile and validate the model before opening the publication transaction.
- Replace the algorithm row, specification definitions, representative flat
  shape, and model together in one transaction. A cancelled or failed
  compilation leaves the complete prior algorithm metadata intact.
- Before multi-vector compilation exists, any successful representative-only
  rescan deletes that GUID's prior model in the same flat-shape transaction; an
  old profile model must not survive new flat/spec metadata.
- A hardware scan writes origin `hardware`. Asset import normalizes imported
  rows to origin `bundled`, regardless of the origin recorded in the exported
  JSON.
- Delete a model when its stored specification-definition hash differs from the
  current algorithm info.
- A changed firmware version marks the model stale. The bundled model remains
  usable as partial fallback until a new scan replaces it; it is not reported
  as verified against the connected firmware.
- Version 1 exports factory algorithms only, matching the existing bundled
  export filter. Connected plug-ins keep legacy flat metadata.

## Runtime resolution

Add `AlgorithmOfflineModelResolver` as the only component that understands the
payload. It returns a `ResolvedAlgorithmShape` and caches by algorithm GUID plus
the full specification vector.

Resolution order is fixed:

1. Load and decode the current model for the GUID.
2. Reject the model if its schema version or specification-definition hash is
   incompatible.
3. Resolve an exact full-vector profile, regardless of model coverage.
4. Otherwise construct `ResolvedAlgorithmShape.legacy` from the current flat
   metadata tables.

`ResolvedAlgorithmShape` contains ordered `ParameterInfo` data, enum strings,
`ParameterPages`, output-mode usage, and a coverage marker. It assigns the
caller's algorithm index and concrete parameter numbers during expansion.

`OfflineDistingMidiManager` must obtain the resolved shape for a slot before
answering any of these methods:

- `requestNumberOfParameters`
- `requestParameterInfo`
- `requestParameterEnumStrings`
- `requestParameterPages`
- `requestOutputModeUsage`

Parameter values continue to use concrete parameter numbers. Adding, removing,
moving, loading, or replacing offline algorithms must invalidate only affected
resolver cache entries.

No success snackbar is added. A partial/legacy result is exposed through the
resolved shape and scan report for diagnostics. `OfflineDistingMidiManager`
exposes a read-only per-slot coverage query so callers do not have to infer
fallback from parameter data; the first implementation does not add a new
warning to normal offline UI.

## Bundled metadata and compatibility

- Increment `full_metadata` export from version 2 to version 3.
- Add `algorithmOfflineModels` under `tables`.
- Add top-level `offlineModelBundleDigest`, validate it on import, and use it as
  the content revision for selective upgrades.
- Version-3 import inserts missing model rows and replaces older `bundled` rows
  for the factory GUIDs present in the asset. It never overwrites a local
  `hardware` row.
- Version-1 and version-2 imports remain accepted and produce no model rows.
- Unknown export versions are rejected instead of being imported permissively.
- Existing installed databases need a selective model upgrade even when
  `Algorithms` is nonempty; `AlgorithmMetadataService` cannot rely only on
  `hasCachedAlgorithms()`.
- Record a SHA-256 digest of the canonical bundled model-row array in
  `MetadataCache`. Import the version-3 model table when that digest differs,
  without replacing user-synced flat parameter metadata or hardware-origin
  models. Export format version alone is not a bundle revision.
- The bundled asset is not updated until a real hardware scan completes and the
  report contains no failed factory vectors claimed by a verified model.

## Hardware safety and recovery

The existing full metadata sync explicitly clears the device preset. Version 1
keeps that visible workflow and does not run shape sampling silently.

- The metadata sync warning must continue to tell the user to save device work.
- Each probe follows add, poll, capture, remove, poll.
- After add/poll, request slot 0's algorithm and require both its GUID and its
  returned specification vector to equal the requested values before capture.
  A clamped or stale vector is failed evidence, never a labeled profile.
- Removal is in `finally`, including cancellation and query failure.
- If removal cannot restore an empty preset, call the existing cleanup path and
  stop scanning that algorithm.
- A resource-heavy maximum that times out or reboots is failed evidence. Retry
  once through the existing reboot/reconnection policy, then mark the model
  partial and continue.
- Existing algorithm-level checkpoints remain unchanged. Resuming may repeat
  the interrupted algorithm's probes, but no half-built model is published.
- The report lists successful vectors, fingerprints, failed vectors/errors,
  structural axes, Cartesian size, coverage, firmware version, and payload size.
- `MetadataSyncService` delivers each published report through an optional
  callback and an immutable `lastShapeScanReports` list; reports are not left in
  a private local variable.
- No debug logging is added; existing progress and error callbacks carry scan
  status.

## Target file tree

| Path | Action |
|---|---|
| `lib/models/algorithm_offline_model.dart` | Add immutable snapshots, profiles, persisted model codec, coverage enum, and resolved shape |
| `lib/services/algorithm_shape_capture_service.dart` | Capture one complete in-memory shape from an already instantiated slot |
| `lib/services/algorithm_offline_model_compiler.dart` | Plan vectors, fingerprint snapshots, pool parameters, compile/validate exact profiles, and build scan report |
| `lib/services/algorithm_offline_model_resolver.dart` | Decode/cache models and fall back to flat metadata |
| `lib/services/full_metadata_format.dart` | Own export version 3 and deterministic bundled-model digest |
| `lib/services/metadata_sync_service.dart` | Drive multi-vector capture and publish one representative flat shape plus one compiled model |
| `lib/db/tables.dart` | Add `AlgorithmOfflineModels` |
| `lib/db/database.dart` | Register table and migrate schema 13 to 14 |
| `lib/db/daos/metadata_dao.dart` | Atomic algorithm/spec/flat/model publication, model queries, digest cache, and flat-shape fallback query |
| `lib/domain/offline_disting_midi_manager.dart` | Route shape requests through resolver and invalidate cache on slot mutations |
| `lib/services/algorithm_json_exporter.dart` | Export version 3 and factory model rows |
| `lib/services/metadata_import_service.dart` | Validate versions and import model rows |
| `lib/services/algorithm_metadata_service.dart` | Selectively upgrade bundled models in existing databases |
| `docs/metadata-collection-process.md` | Document the version-3 scan, report, validation, and replacement procedure |
| `assets/metadata/full_metadata.json` | Replace only after physical-hardware validation |

Generated Drift files are regenerated by `build_runner`; they are never edited
by hand.

## Symbol map

| Symbol | Current location | Destination/behavior after implementation |
|---|---|---|
| `MetadataSyncService._scanSpecValues` | `lib/services/metadata_sync_service.dart` | Remains the representative flat-shape selector only |
| `MetadataSyncService._tryScanAlgorithm` | same | Delegates vector planning/capture to `AlgorithmOfflineModelCompiler` and publishes after validation |
| `MetadataSyncService._syncInstantiatedAlgorithmParams` | same | Replaced by `AlgorithmShapeCaptureService.capture`; flat persistence consumes the returned snapshot |
| `AlgorithmShapeSnapshot` | new | `lib/models/algorithm_offline_model.dart`; immutable full observation and canonical fingerprint |
| `AlgorithmShapeProfile` | new | same; exact specification vector plus pooled parameter refs/pages/output usage |
| `AlgorithmOfflineModel` | new | same; versioned payload and coverage |
| `ResolvedAlgorithmShape` | new | same; runtime shape with caller-relative indexes |
| `OfflineModelCoverage` | new | same; `verified`, `partial`, `unsupported`, and runtime `legacy` |
| `AlgorithmShapeCaptureService.capture` | new | Captures slot metadata without database writes |
| `AlgorithmOfflineModelCompiler.discoveryVectors` | new | Applies one-axis discovery and safe small-axis corner probes |
| `AlgorithmOfflineModelCompiler.completionVectors` | new | Enumerates the capped complete small-axis Cartesian product |
| `AlgorithmOfflineModelCompiler.compile` | new | Produces a validated pooled profile model and report |
| `AlgorithmShapeEdgeDelta` | new | Explains concrete parameter/page/output changes along one specification axis |
| `AlgorithmOfflineModelResolver.resolve` | new | Resolves/caches an exact full-vector profile or legacy fallback |
| `MetadataDao.replaceAlgorithmShapeMetadata` | new | Atomically replaces algorithm info, specs, representative flat shape, and optional model |
| `MetadataDao.replaceAlgorithmOfflineModel` | new | Conflict-updates one already validated model row |
| `MetadataDao.getAlgorithmOfflineModel` | new | Loads one model row |
| `MetadataDao.deleteAlgorithmOfflineModel` | new | Invalidates stale model |
| `MetadataDao.getFullAlgorithmDetails` | existing | Remains the legacy fallback source |
| `OfflineDistingMidiManager.requestNumberOfParameters` and related methods | existing | Read one cached `ResolvedAlgorithmShape` instead of querying flat tables independently |
| `OfflineDistingMidiManager.offlineMetadataCoverageForSlot` | new | Exposes verified/partial/legacy resolution to callers without a UI change |
| `MetadataSyncService.lastShapeScanReports` | new | Exposes immutable reports from the most recent full scan |
| `fullMetadataExportVersion` | new | `lib/services/full_metadata_format.dart`; constant value 3 |
| `offlineModelBundleDigest` | new | Deterministic SHA-256 over exported model rows |
| `AlgorithmJsonExporter.exportFullMetadata` | existing | Emits version 3 and model rows |
| `MetadataImportService.importFromJson` | existing | Accepts versions 1-3, rejects unknown versions, imports models for v3 |
| `MetadataImportService.importOfflineModelsFromAsset` | new | Selectively imports changed bundled rows without replacing hardware-origin models |

No public compatibility re-export is needed for the new files.

## Decisions inventory

| Decision | Rationale | Classification |
|---|---|---|
| Model shape as `F(GUID, specs)` | Specification values can change the complete metadata surface | required |
| Persist exact profiles with a shared parameter pool | Exactness without a symbolic grammar or full-snapshot duplication | required |
| Use full metadata fingerprints, not parameter count | Same-count shapes can still change names, enums, pages, flags, or output usage | required |
| Enumerate the complete small-axis product only within fixed caps | Detects interior interactions without unbounded Cartesian growth | required |
| Treat names only as scheduling hints | Names are not a firmware contract | required |
| Keep flat tables | Backward compatibility and a defined fallback | required |
| Use one versioned JSON model table | Small schema change and evolvable payload | required |
| Resolve all offline metadata through one cached shape | Prevents count/info/page/enum disagreement | required |
| Defer symbolic repeat rules | Exact profile coverage solves the current problem with less inference risk | required |
| Keep scans explicit and destructive as today | Avoid hidden preset mutation and a new background workflow | required |
| Factory algorithms only in bundled v1 | Matches current exporter and avoids missing plug-in provenance | required |
| Do not synthesize unsampled profiles | An attractive guess is still wrong metadata | required |

## Acceptance criteria

- A hardware-derived Quantizer model includes exact profiles for Channels 1-12.
- Offline Quantizer Channels 4 matches the hardware snapshot fingerprint for
  parameters, enums, pages, and output-mode usage.
- Mixer Mono and Mixer Stereo models enumerate and resolve every supported
  `Channels x Sends` combination when the Cartesian product is at most 128.
- A multi-axis synthetic fixture proves that independent axis deltas are not
  treated as sufficient interaction evidence.
- An axis can change names, enums, pages, or output-mode usage without changing
  parameter count and is still detected as structural.
- A failed maximum probe produces partial coverage, not invariant coverage.
- Partial models resolve only exact full-vector profiles.
- Unsupported and unmeasured vectors return the legacy flat shape with coverage
  `legacy`; they never return a fabricated verified profile.
- All five offline shape request methods use the same cached resolved shape.
- Export version 3 round-trips models; versions 1 and 2 still import; unknown
  versions are rejected.
- Existing databases import newer bundled model rows without overwriting their
  synced flat metadata.
- A fresh database populated only from the bundled version-3 asset resolves the
  Quantizer and Mixer acceptance cases without connected hardware.
- Cancellation or failure never publishes a half-built model and leaves the
  device preset empty.
- `flutter analyze` reports no issues and the full test suite passes.

## Deferred follow-ups

Only consider these after measuring real version-3 payload and scan sizes:

- Compile verified repeat recipes behind `AlgorithmOfflineModelResolver` if the
  exact-profile asset is materially too large.
- Add connected-use exact-profile capture for previously partial tuples.
- Add plug-in build identity and plugin-model export.
- Add a normal UI badge for legacy/partial offline shapes.

These are not implementation escape hatches for version 1.
