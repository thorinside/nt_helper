# Phase 4: Mapping Row Highlight - Context

**Gathered:** 2026-02-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Visual indicator on the mapping icon when the mapping editor bottom sheet is open for that parameter. The highlight appears when the bottom sheet opens and clears when it closes.

</domain>

<decisions>
## Implementation Decisions

### Highlight style
- Thin border around the element
- Use the secondary/tertiary color (the orange one in the theme)
- Should be subtle but clearly visible

### Highlight target
- Border around the mapping icon (MappingEditButton) only, not the entire row
- The rest of the row remains visually unchanged

### Claude's Discretion
- Border thickness and radius
- Exact color shade from the theme's secondary/tertiary palette
- How state is communicated between the bottom sheet lifecycle and the icon widget

</decisions>

<specifics>
## Specific Ideas

- User specifically wants the orange color to distinguish the "currently editing" state from the existing "has mapping" state (which uses primaryContainer)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-mapping-row-highlight*
*Context gathered: 2026-02-01*
