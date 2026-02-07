# Notes Algorithm View: Edit State Not Communicated to Screen Readers

**Severity:** Medium

**Status: Addressed (2026-02-06)** — in commit 664e27b

**Files affected:**
- `lib/ui/notes_algorithm_view.dart` (lines 250-324, build method)
- `lib/ui/notes_algorithm_view.dart` (lines 326-351, `_buildTextDisplay`)
- `lib/ui/notes_algorithm_view.dart` (lines 354-531, `_buildTextEditor`)

## Description

The Notes algorithm view has two modes (display and edit) that are toggled via an Edit button. Issues:

1. **No state announcement**: Switching to edit mode is not communicated via `SemanticsService.announce()`.
2. **Save progress**: The Save button changing to "Saving..." with a spinner is not announced.
3. **Text display has no semantic grouping**: Individual `Text` lines lack context that they form a single text block.
4. **Preview validation warnings** ("Some lines too long") are not announced.
5. **Edit button disabled state** for older firmware has only a tooltip explanation.

## Impact on blind users

Blind users won't know when they've entered edit mode, when saving is in progress, or when validation errors prevent saving.

## Recommended fix

Add `SemanticsService.announce()` for mode transitions and validation errors. Add `Semantics(label: 'Notes content')` grouping for display text.
