# Zero SemanticsService.announce() Calls in Entire Codebase

**Severity: Critical**

## Files Affected
- Entire codebase (`lib/` directory)

## Description

The app contains **zero** calls to `SemanticsService.announce()` anywhere in the codebase. This Flutter API is the primary mechanism for informing screen reader users about dynamic state changes that don't involve focus movement, such as:

- Loading/sync completion
- Parameter value changes
- Connection creation/deletion
- Mode switches
- Error states
- Save confirmations

Without any announcements, screen reader users operate in near-silence, unable to confirm whether their actions had any effect.

## Impact on Blind Users

Every dynamic operation in the app is silent to screen readers:

- Saving a preset: no confirmation
- Changing a parameter value: no readback of the new value
- Creating a routing connection: no confirmation
- Loading algorithms: no progress indication
- Errors: no notification
- Mode changes: no context switch announcement

This is the single most impactful gap in the entire accessibility story. A sighted user gets constant visual feedback; a blind user gets none.

## Recommended Fix

Add `SemanticsService.announce()` calls for all state transitions. Priority announcements:

1. Parameter value changes (most frequent user action)
2. Connection created/deleted (critical routing feedback)
3. Save/load confirmations
4. Error messages
5. Loading/sync state changes
6. Mode switches

See [keyboard-navigation-scheme.md](keyboard-navigation-scheme.md) section 13 for a complete announcement table.
