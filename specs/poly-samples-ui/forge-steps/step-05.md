## STEP 5 of 14 — full DecentSamplerConvertOptions surface on PolyDecentImportCubit

Spec section: "Step 5 — PolyDecentImportCubit full options".

Files: `lib/ui/poly_multisample/poly_decent_import_cubit.dart`,
`test/poly_multisample/poly_decent_import_cubit_test.dart`.

1. Add the ten state fields, ten mutator methods, `analyzeSource` seeding,
   tag-overlap warnings, and the full `continueImport` options object —
   exactly per the spec's tables.
2. Tests (append to the existing group, reusing the file's existing
   `_FakeImportService` fixture — read the test file first). Add a field
   `DecentSamplerConvertOptions? lastOptions;` to `_FakeImportService` and
   set `lastOptions = options;` inside its `stageDecentSource` override.
   The existing `_overlappingAnalysis()` fixture has `tags: []`; for the tag
   tests below, build a second fixture `_taggedAnalysis()` — copy
   `_overlappingAnalysis()` and give it two `DecentSamplerTag` entries
   (keys `'tag:soft'`, `'tag:hard'`, labels `'soft'`/`'hard'`, each with
   `groupKeys` naming one group, `sampleCount: 2`, `confidence: 1.0`,
   `evidence: ''`, the same structure/note/velocity/RR summary strings
   as the groups, defaults low 60 / root 60 / high 61, velocity layer 1) and
   `recommendedGroupHandling: DecentSamplerGroupHandling.selectedTags`.
   Tests:
   - `test('analyzeSource seeds tag ranges and preset selection', ...)`.
   - `test('setTagRange recomputes overlap warnings under selectedTags', ...)`
     — two selected tags with overlapping ranges → non-empty warnings;
     disjoint → empty.
   - `test('continueImport forwards the full option set', ...)` — use
     `_taggedAnalysis()` with non-overlapping tag ranges, set
     `preserveXmlMapping`/`addUnmapped` true, select one tag, set one tag
     round-robin; after `continueImport`, assert those four values on
     `service.lastOptions!`.

Verify; test file:
`flutter test test/poly_multisample/poly_decent_import_cubit_test.dart`.

Commit message: `feat(poly): expose full Decent Sampler options in import cubit`

---

