# Roadmap: Mapping Row Highlight

## Milestones

- **v2.10 14-bit MIDI Detection** - Phases 1-3 (shipped 2026-02-01)
- **Mapping Row Highlight** - Phase 4 (in progress)

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

<details>
<summary>v2.10 14-bit MIDI Detection (Phases 1-3) - SHIPPED 2026-02-01</summary>

### Phase 1: Type System Foundation
**Goal**: Typed MIDI events distinguish 7-bit CC, 14-bit CC (both byte orders), and notes at the type level
**Plans**: 1 plan

Plans:
- [x] 01-01: Type system and enum foundation

### Phase 2: 14-bit Detection
**Goal**: MIDI detection engine auto-classifies incoming CC pairs as 14-bit with correct byte order
**Plans**: 2 plans

Plans:
- [x] 02-01: 14-bit CC pair detection engine
- [x] 02-02: Byte order determination via variance analysis

### Phase 3: UI Integration
**Goal**: Detection results flow into the mapping editor, auto-configuring 14-bit mode and range slider
**Plans**: 1 plan

Plans:
- [x] 03-01: Mapping editor 14-bit auto-configuration

</details>

### Mapping Row Highlight (In Progress)

**Milestone Goal:** User can see at a glance which parameter row has its mapping editor open

- [ ] **Phase 4: Mapping Row Highlight** - Visual indicator on the active parameter row while the mapping editor bottom sheet is open

## Phase Details

### Phase 4: Mapping Row Highlight
**Goal**: User can identify which parameter row is being edited when the mapping bottom sheet is open
**Depends on**: Nothing (independent of previous milestone)
**Requirements**: UH-01, UH-02
**Success Criteria** (what must be TRUE):
  1. When the mapping editor bottom sheet is open for a parameter, the corresponding row in the parameter list is visually distinguished from other rows
  2. When the bottom sheet is dismissed, no row retains highlight styling -- the list returns to its normal appearance
**Plans**: 1 plan

Plans:
- [ ] 04-01-PLAN.md — Add orange highlight border to mapping icon during editing + tests

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Type System Foundation | v2.10 | 1/1 | Complete | 2026-02-01 |
| 2. 14-bit Detection | v2.10 | 2/2 | Complete | 2026-02-01 |
| 3. UI Integration | v2.10 | 1/1 | Complete | 2026-02-01 |
| 4. Mapping Row Highlight | Row Highlight | 0/1 | Not started | - |
