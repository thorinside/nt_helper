# Keyboard Shortcuts for All Major Features

**Severity: Critical**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## User Feedback

A blind tester specifically requested comprehensive keyboard shortcuts for **all major portions of the app**. This is the single most impactful accessibility improvement for power users who rely on keyboard and screen reader navigation.

## Current State

The app has **minimal** keyboard shortcut support:

- **Exists:** Zoom shortcuts (`Cmd/Ctrl + Plus/Minus/0`) in the routing editor only
- **Exists:** Arrow key navigation in the Add Algorithm screen
- **Missing:** Everything else

There are no keyboard shortcuts for:
- Saving presets
- Creating new presets
- Browsing presets
- Adding algorithms
- Switching between Parameters and Routing modes
- Navigating between algorithm slots
- Editing parameter values
- Creating routing connections
- Step sequencer editing
- Performance screen operations
- Opening the mapping editor
- Plugin management

## Impact on Blind Users

Without keyboard shortcuts, a blind user must:
1. Tab through potentially hundreds of widgets to reach their target
2. Rely on screen reader gestures (swipe right/left) which are slow in complex UIs
3. Cannot perform common operations quickly (save, switch modes, navigate slots)
4. Has no way to perform some operations at all (routing connections, step sequencer editing)

For a music production tool, speed matters. Sighted users can click directly on any element; keyboard users need shortcuts to achieve equivalent efficiency.

## Comprehensive Keyboard Shortcut Scheme

A complete keyboard navigation scheme has been designed and documented in [keyboard-navigation-scheme.md](keyboard-navigation-scheme.md). It covers:

1. **Global shortcuts** - Save, new preset, browse, add algorithm, refresh, settings, mode switching
2. **Focus management** - Tab order, focus restoration, focus indicators
3. **Parameter mode** - Navigate parameters, edit values, section navigation, mapping access
4. **Routing mode** - Node/port navigation, keyboard connection creation, canvas pan/zoom
5. **Step sequencer** - Grid navigation, value editing, parameter mode switching
6. **Add algorithm screen** - Search, filter, view modes
7. **Performance screen** - Page switching, parameter editing
8. **Preset browser** - Tree navigation, load/append
9. **Mapping editor** - Tab switching, field navigation, MIDI learn
10. **Plugin manager** - Tab switching, search, install
11. **Dialogs** - Confirm/cancel, destructive actions
12. **Shortcut help panel** - Discoverable via `Cmd/Ctrl + /`

## Implementation Roadmap

### Phase 1: Foundation (Highest Impact)
- Global shortcuts (`Mod+S` save, `Mod+N` new, `Mod+O` browse, `Mod+R` refresh)
- Mode switching (`Mod+1` Parameters, `Mod+2` Routing)
- Algorithm slot navigation (`Mod+[` / `Mod+]`)
- Parameter list keyboard navigation (Tab, Arrow keys, Enter to edit)

### Phase 2: Core Workflows
- Routing node/port keyboard navigation
- Keyboard connection creation (two-press Space flow)
- Step sequencer grid navigation
- Value editing via Arrow/Page keys

### Phase 3: Polish
- Shortcut help panel (`Mod+/`)
- Canvas pan/zoom keyboard controls
- Focus restoration across all dialogs
- Preset browser keyboard navigation

### Phase 4: Refinement
- Performance screen shortcuts
- Plugin manager navigation
- Mapping editor shortcuts
- Tooltip integration showing keyboard shortcuts

## Technical Foundation

The app already has `KeyBindingService` (`lib/services/key_binding_service.dart`) implementing zoom shortcuts using Flutter's `Shortcuts` + `Actions` pattern. This service should be extended with all new shortcut maps following the same architecture. See [keyboard-navigation-scheme.md](keyboard-navigation-scheme.md) sections 14-17 for implementation details.
