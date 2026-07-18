# Repeat-aware offline algorithm metadata

Status: design specification only. No production code is implemented here.

Baseline ref: `1cb7bb70`

## Decision

Keep one flat metadata shape per algorithm and add a small grammar describing
which sections repeat for which count specification.

The grammar references rows already present in the flat shape. It does not
store another shape for every specification value. Delay length, sample time,
and other allocation-only specifications are not sampled or modeled.

The feature does not change presets or templates. A new preset still forgets
the previous preset's specifications by design.

## Accepted inference rule

Version 1 adopts this domain rule:

> If an adjacent `n`/`n + 1` comparison uniquely identifies one additional
> isomorphic section, and the inferred grammar reconstructs both observations,
> that is proof of the repeat law over the specification's declared range.

This is a domain inference proof, not a mathematical claim that two arbitrary
samples prove all unseen behavior. It deliberately avoids minimum/maximum and
Cartesian sampling.

## Scope

The implementation must:

- reproduce offline parameter count, parameter metadata, enums, pages, page
  membership, and output-mode relationships for requested count values;
- support several sections controlled by one specification;
- support nested sections such as Mixer Mono `Channels x Sends`;
- ship the grammar in `assets/metadata/full_metadata.json`;
- use the current flat metadata whenever inference or expansion fails.

It must not add:

- exact profiles, per-value snapshots, coverage matrices, or stored proof data;
- a model for delay length, sample duration, buffer size, or other allocation;
- arbitrary conditional metadata rules;
- runtime inference, an inference editor, or a preset/template behavior change.

## Which specifications are sampled

Reuse the existing count-specification selector in
`MetadataSyncService._isUsefulOfflineCountSpec`:

```text
type is 0 or 2
and name matches channels, inputs, outputs, sends, stereo, or voices
```

This selector only decides which axes are worth probing. It never proves a
repeat. A selected axis still needs the adjacent hardware proof. An unselected
axis is absent from the grammar.

Consequences:

- Quantizer `quan` Channels is probed.
- Mixer Mono `mix1` Channels and Sends are probed.
- Delay (Mono) `delm` Max delay time is not probed.
- Sample/record time specifications are not probed.

The selector may be extended later when a new count noun is deliberately added;
that is a scanner policy change, not a grammar-format change.

## Canonical capture

For every selected axis with `min < max`, choose:

```text
n     = specification minimum
n + 1 = specification minimum + 1
```

Build the canonical vector as follows:

- selected mutable axes use `n + 1`;
- every other axis uses its safe default.

Capture that vector once. It is both the flat metadata persisted for the
algorithm and the `n + 1` witness for every selected axis. For each selected
axis, capture one more vector with only that axis lowered to `n`. This yields one
canonical capture plus one adjacent capture per count axis.

If no grammar is proven, preserve today's representative `_scanSpecValues`
shape as the flat fallback instead. Allocation-only algorithms therefore keep
their current scan behavior.

A witness is valid only when the hardware reports the requested GUID and exact
specification vector after instantiation. A timeout, clamp, different vector,
or incomplete metadata response is a failed proof.

## Shape snapshot

`AlgorithmShapeSnapshot` is immutable and contains:

- the specification vector;
- ordered parameters with name, min, max, default, raw unit, power of ten,
  `ioFlags`, and ordered enum strings;
- ordered pages;
- ordered page-to-parameter membership edges;
- ordered output-mode-control-to-affected-parameter edges.

Parameter numbers and page indexes become logical row references during
inference. Expansion assigns concrete zero-based numbers after cloning, so page
and output relationships cannot retain stale canonical indexes.

The proof concerns duplication topology. A scalar change on a fixed row does
not create a repeat and is outside this feature. Within a proposed repeated
section, all properties must either match or use one of the ordinal
substitutions below.

## Compact repeat grammar

The grammar contains coherent repeat sections:

```text
Grammar := baselineSpecifications + RepeatSection*

RepeatSection :=
  specificationIndex
  + countBias
  + sourceOrdinal
  + StreamRun*
  + OrdinalSubstitution*
  + RepeatSection*

repeatCount := specificationValue + countBias
```

A `StreamRun` identifies the corresponding canonical occurrences in one of four
streams: parameters, pages, page memberships, or output usage. It stores only:

```text
stream, firstStart, itemCount
```

`repeatCount` canonical occurrences are contiguous and begin at
`firstStart + ordinal * itemCount`.
Rows not covered by any repeat section are fixed and are copied once. Child
sections use offsets relative to the parent's canonical occurrence. More than
one top-level section may reference the same specification.

Relationships are remapped automatically:

- a page-membership edge follows the generated logical page and parameter;
- both endpoints of an output-usage edge follow their generated logical
  parameters;
- the deepest repeated endpoint owns the edge, preventing duplicate clones;
- a relationship that cannot be assigned uniquely rejects the grammar.

Only two substitution forms exist:

- ordinal text parts for parameter names, enum strings, and page names;
- affine ordinal integers for parameter min/max/default.

Raw unit, power of ten, and `ioFlags` are copied literally. A mismatch in one of
those fields rejects the repeated section.

All iteration ordinals are zero-based. The selected canonical source begins at
`firstStart + sourceOrdinal * itemCount`. A text placeholder renders
`iterationOrdinal + displayBias`. An affine integer renders
`constant + sum(coefficient * activeIterationOrdinal)`. It never uses the raw
specification value. Output-mode usage contains parameter references, so both
its source and affected parameter are remapped as logical references rather
than patched as integers.

The compact JSON encoding is:

```text
grammar := [1, baselineSpecifications, sections]
section := ["r", specIndex, countBias, sourceOrdinal, runs, patches, children]
run     := [streamCode, firstStart, itemCount]
text    := ["t", streamCode, rowOffset, fieldCode, elementIndex, parts]
integer := ["i", streamCode, rowOffset, fieldCode, elementIndex,
            constant, [[specIndex, coefficient]...]]
```

Text `parts` are literal strings or `[specIndex, displayBias]`. Stream and field
codes are fixed by grammar version 1. Unknown tags/codes/versions fail decoding.
The JSON contains no raw metadata rows, witness snapshots, ignored-axis list,
or per-value profiles.

## Adjacent inference proof

### One axis

Compare the canonical `n + 1` capture to the capture with that axis at `n`:

1. Produce a deterministic shortest edit script for each ordered stream.
2. Candidate insertions in the `n + 1` shape must form one or more complete
   section occurrences.
3. Compare each inserted occurrence to its neighboring canonical occurrence.
   Normalize only digit runs that advance with the section ordinal.
4. Infer integer substitution only when corresponding occurrences have a
   constant affine step.
5. Require a unique section decomposition. Tied alignments, overlapping runs,
   unsupported property changes, or unresolved relationships reject it.
6. Expand the candidate at `n` and `n + 1`; require exact topology, exact
   repeated-row properties, and valid references in both.

If the selected axis adds no row or relationship, it contributes no section. If
it changes topology but cannot pass the proof, the algorithm grammar is
unproven and the flat fallback is used.

### Interacting axes

Independently inferred sections that overlap or contain one another form an
interaction group. Capture one additional witness per group with all axes in
that group lowered to `n`; other axes remain at their canonical values.

For Mixer Mono the captures are:

```text
Channels 2, Sends 1   canonical
Channels 1, Sends 1   Channels witness
Channels 2, Sends 0   Sends witness
Channels 1, Sends 0   one interaction witness
```

Use the interaction witness to place the inner section at the same relative
offset in every outer occurrence. Re-expand all four captures exactly. Disjoint
sections need no interaction witness. Version 1 supports exactly two axes in an
interaction group; three or more interacting axes are unproven. Missing or
ambiguous interaction evidence rejects the whole grammar rather than saving a
partial rule.

## Persistence and bundle

Add one table:

```text
AlgorithmRepeatGrammars
- algorithmGuid TEXT PRIMARY KEY REFERENCES Algorithms(guid)
- grammarVersion INTEGER NOT NULL
- grammarJson TEXT NOT NULL
```

Only algorithms with a proven repeat need a row. `full_metadata` export version
3 adds `tables.algorithmRepeatGrammars`; versions 1 and 2 remain importable and
fall back to flat metadata.

Publish replacement flat rows and their grammar in one database transaction.
A fallback replacement writes the flat rows and removes any stale grammar.
Algorithm parent upserts must use conflict-update semantics, not SQLite
`REPLACE`, so foreign-key cascades cannot discard a grammar accidentally.

Import grammar rows together with their canonical flat rows during the existing
empty-database bundle import. Do not attach a bundled grammar to older flat rows
whose canonical capture may differ. Existing populated databases keep flat
fallback until a hardware rescan writes a matching shape and grammar. The
checked-in bundle is the shipping truth for a fresh offline install.

## Offline expansion

Resolve by `(algorithmGuid, specificationValues)`:

1. Load the canonical flat rows.
2. Return them unchanged when no grammar exists.
3. Decode and validate specification count/ranges, runs, repeat counts,
   substitutions, and relationship ownership.
4. Expand sections, assign parameter/page numbers, and remap relationships.
5. Return the complete immutable result and cache it by GUID/vector.

Any error returns the whole flat shape. Never expose a partial expansion.

The resolved shape supplies `requestNumberOfParameters`,
`requestParameterInfo`, `requestParameterEnumStrings`,
`requestParameterPages`, and `requestOutputModeUsage` in
`OfflineDistingMidiManager`.

## Acceptance criteria

- `quan` is proven from Channels 1/2 and expands to 1, 4, and 12 channel
  sections from one canonical flat shape.
- `mix1` is proven from the four captures above and expands nested Channels and
  Sends without dangling page or output references.
- `delm` Max delay time and sample/record-time axes are never requested by the
  repeat scanner and consume no grammar space.
- Every persisted grammar reconstructs its canonical, individual adjacent, and
  interaction witnesses before storage.
- The version-3 bundle stores repeat spans/substitutions only, not copied shapes
  or proof evidence.
- Invalid/missing grammars and v1/v2 bundles retain flat behavior.
- New-preset and template specification behavior is unchanged.
- `flutter analyze` and the full `flutter test` suite pass.
