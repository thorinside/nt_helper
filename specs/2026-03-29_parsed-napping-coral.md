# Progressive Disclosure for MCP/Chat Show Tools

## Context

`show_preset` currently dumps the entire preset — all slots with all parameters, enum value lists, and mappings. A 6-slot preset can produce 30-50KB+ of JSON. This wastes LLM context tokens, slows tool execution (serial enum string fetches), and is rarely needed in full. The goal is a 3-tier progressive disclosure model where agents drill down on demand.

## Design

**Level 1 — `show_preset` (overview)**
- Returns: preset name + slot summaries (index, algorithm guid/name, parameter_count)
- NO parameters, NO mappings — ~100 bytes/slot

**Level 2 — `show_slot` (paginated parameter summaries)**
- New optional params: `offset` (default 0), `limit` (default 10)
- Each parameter shows: number, name, is_disabled, current value (resolved enum name or scaled numeric), min/max for numerics, `is_enum` flag
- Omits: `valid_enum_values` lists, full mapping objects, `unit` code
- Includes `has_mapping: true` + `performance_page` when applicable
- Response includes `parameter_count`, `offset`, `limit`, `has_more` for navigation

**Level 3 — `show_parameter` (full detail, unchanged)**
- Existing behavior: enum value lists, full mapping objects, everything

## Files to Change

### 1. `lib/mcp/tools/algorithm_tools.dart`

**`showPreset()`** (line 560) — Replace implementation:
- Keep sync check and `getCurrentPresetName()`
- For each slot from `getAllSlots()`, only fetch `getParametersForSlot(i).length` for the count
- Build: `{slot_index, algorithm: {guid, name}, parameter_count}`
- Do NOT fetch values, mappings, or enum strings

**`showSlot()`** (line 593) — Add pagination:
- Change signature to accept named `offset` and `limit` params
- After fetching parameters/values/mappings, slice to `[offset..min(offset+limit, total)]`
- Call new `_buildParameterSummaryJson()` instead of `_buildParameterJson()`
- Return: `{slot_index, algorithm, parameter_count, offset, limit, has_more, parameters}`

**New `_buildParameterSummaryJson()`** — Lightweight parameter representation:
- Include: parameter_number, parameter_name, is_disabled, value (resolved), min/max (numerics), is_enum
- Omit: valid_enum_values, full mapping objects, unit code
- Add: `has_mapping: true` flag when any mapping is active, `performance_page` when assigned

**`_buildSlotJson()`** — Will become dead code (no callers after changes). Remove it, and inline the empty-slot response in `showSlot()`.

### 2. `lib/mcp/tool_registry.dart`

**`show_preset` registration** (line 187):
- Update description: "Show a compact preset overview: preset name, slot list with algorithm names and parameter counts. Use show_slot to drill into a specific slot."

**`show_slot` registration** (line 195):
- Update description: explain paginated summaries, point to show_parameter for full detail
- Add `offset` and `limit` to input schema (both optional integers)
- Update handler to pass `offset` and `limit` from args

### 3. `lib/chat/services/system_prompt.dart`

- Update workflow rule #1: Replace "Always show_preset or show_slot first" with progressive disclosure guidance
- Update workflow rule #5: Clarify that `show_parameter` (not show_slot) is needed for enum value lists
- Add pagination note to Tool Reference section

### 4. `docs/mcp-api-guide.md`

- Update `show_preset` section with new compact response format and example
- Update `show_slot` section with pagination params and example response
- Add progressive disclosure workflow example

### 5. Tests — `test/mcp/tools/algorithm_tools_audit_test.dart`

**Update existing tests:**
- `'showPreset — synchronized state'` group: assert `parameter_count` instead of `parameters` array
- `'showSlot — empty slot handling'` group: update assertions for new response shape (pagination metadata, summary format)

**Add new tests:**
- `showSlot` pagination: default page, custom offset/limit, has_more true/false, offset beyond range
- Parameter summary format: enum without valid_enum_values, has_mapping flag, performance_page inclusion

## Verification

1. `flutter analyze` — zero warnings
2. `flutter test test/mcp/` — all MCP tests pass
3. Manual test with running app + MCP client:
   - `show_preset` returns compact overview
   - `show_slot` with no offset returns first 10 params
   - `show_slot` with offset/limit paginates correctly
   - `show_parameter` still returns full detail with enum lists and mappings
