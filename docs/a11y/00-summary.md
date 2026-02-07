# NT Helper Accessibility Audit Summary

## Executive Summary

NT Helper is a Flutter-based MIDI controller app for the Expert Sleepers Disting NT Eurorack module, providing preset management, algorithm loading, parameter control, routing visualization, and step sequencing. This audit evaluated the app's accessibility for screen reader users, keyboard-only users, and users with low vision.

**The app has significant accessibility support after the 2026-02-06 audit and implementation pass.** Using Flutter's Material 3 framework as a baseline, the app now has:

- **Extensive** `SemanticsService.announce()` calls for state transitions, slot/tab selection, algorithm add/select, mode switches
- **Active** `FocusTraversalGroup` and `FocusNode` management in routing canvas and parameter lists
- **Dev-time** accessibility checking via `accessibility_tools` (no dedicated test suite yet)
- **Broad** `Semantics` widget coverage across parameters, routing, step sequencer, dialogs, and navigation
- **Keyboard navigation** for global shortcuts (Mod+S/N/O/R), slot navigation (Mod+[/]), routing connections (Space), step sequencer (arrow keys + letter keys)
- **No** text scaling support
- **No** high contrast mode detection

### Progress Log

| Date | Changes |
|------|---------|
| 2026-02-06 | Commit 664e27b: keyboard shortcuts, parameter semantics, routing keyboard navigation, step sequencer a11y, icon labels, dialog labels, mapping editor SwitchListTile, tap target fixes, focus traversal, SemanticsService announcements, accessibility_tools dev dependency. **58 issues addressed, 12 partially addressed.** |
| 2026-02-06 | Follow-up: FAB "Add to Preset" announcement, tab/slot selection announcements, algorithm selection announcement, chip grid view semantics, empty preset live region guidance, spec input range labels + offline read-only hint. |

### Remaining Work

Of 75 original issues: **58 fully addressed**, **15 partially addressed**, **2 not yet addressed** (text scaling, high contrast — no source file references changed).

For a blind musician, the core workflows now have basic accessibility support. The main remaining gaps are:
- **Text scaling** and **high contrast mode** detection
- **Dedicated a11y test suite**
- A few source files not yet modified (`connection_painter.dart`, `accessibility_colors.dart`, `interactive_connection_widget.dart`, `pitch_bar_painter.dart`, `mobile_drill_down_navigator.dart`, `mapping_editor_bottom_sheet.dart`, `reset_outputs_dialog.dart`, `preset_package_dialog.dart`)

The audit identified **75 individual issues** across all areas of the app, documented in detail in this directory. Below is a prioritized roadmap for the remaining work.

---

## Issues by Severity

### Critical (14 issues)

These issues completely block core workflows for screen reader users.

| # | Issue | File |
|---|-------|------|
| 1 | [Zero SemanticsService.announce() calls in entire codebase](app-wide-no-semantics-service-announcements.md) | App-wide |
| 2 | [No focus traversal groups or policies](app-wide-no-focus-traversal-management.md) | App-wide |
| 3 | [Keyboard shortcuts missing for all major features](keyboard-shortcuts-for-all-major-features.md) | App-wide |
| 4 | [Parameter slider missing semantics](parameter-slider-missing-semantics.md) | Parameter editing |
| 5 | [Parameter value display not announced on change](parameter-value-display-no-live-region.md) | Parameter editing |
| 6 | [Routing canvas has no screen reader representation](01-routing-canvas-no-screen-reader-representation.md) | Routing |
| 7 | [ConnectionPainter has no semantic equivalent](02-connection-painter-no-semantic-equivalent.md) | Routing |
| 8 | [Drag-and-drop connection creation has no keyboard alternative](03-drag-and-drop-no-keyboard-alternative.md) | Routing |
| 9 | [Algorithm node widget missing semantics](04-algorithm-node-missing-semantics.md) | Routing |
| 10 | [Step sequencer grid completely inaccessible](step-sequencer-grid-inaccessible.md) | Step sequencer |
| 11 | [Bit pattern editor cells inaccessible](bit-pattern-editor-inaccessible.md) | Step sequencer |
| 12 | [Tab bar algorithm gesture-only actions](tab-bar-gestures-inaccessible.md) | Main navigation |
| 13 | [Add algorithm favorites toggle only via long press](add-algorithm-long-press-only-favorites.md) | Algorithm library |
| 14 | [Preset name editor missing semantics](preset-name-editor-missing-semantics.md) | Presets |

### High (22 issues)

These issues significantly degrade the experience but have partial workarounds.

| # | Issue | File |
|---|-------|------|
| 15 | [No text scaling / dynamic type support](app-wide-no-text-scaling-support.md) | App-wide |
| 16 | [Zero accessibility tests](app-wide-no-accessibility-tests.md) | App-wide |
| 17 | [Port widgets missing semantic labels](05-port-widget-missing-semantics.md) | Routing |
| 18 | [Connection deletion requires visual-only interactions](07-connection-deletion-not-accessible.md) | Routing |
| 19 | [Floating overlay widgets inaccessible](10-overlay-widgets-inaccessible.md) | Routing |
| 20 | [Focus management in graph editor is visual-only](13-focus-management-in-graph-editor.md) | Routing |
| 21 | [Connection state changes never announced](16-connection-state-changes-not-announced.md) | Routing |
| 22 | [Mapping editor switch controls missing labels](mapping-editor-switch-labels.md) | Mappings |
| 23 | [MCP status indicator completely inaccessible](mcp-status-indicator-inaccessible.md) | Status |
| 24 | [Parameter row uses gesture-only interactions](parameter-row-gesture-only-interactions.md) | Parameters |
| 25 | [Disabled parameter state not communicated](disabled-parameter-not-communicated.md) | Parameters |
| 26 | [BPM editor widget missing semantics](bpm-editor-missing-semantics.md) | Parameters |
| 27 | [Icon-only buttons missing accessible labels](icon-buttons-missing-labels.md) | App-wide |
| 28 | [Dialogs missing semantic labels and announcements](dialog-missing-semantic-labels.md) | Dialogs |
| 29 | [File parameter editor navigation buttons lack labels](file-parameter-editor-navigation-buttons.md) | Parameters |
| 30 | [Firmware update flow missing live regions](firmware-update-flow-missing-live-regions.md) | Firmware |
| 31 | [Bottom sheet missing drag handle and dismiss semantics](bottom-sheet-drag-handle-missing.md) | UI controls |
| 32 | [Mapping edit button has tiny tap target](mapping-edit-button-scaled-down.md) | Mappings |
| 33 | [Metadata sync page complex states not accessible](metadata-sync-page-complex-states.md) | Sync |
| 34 | [MIDI detector status not announced](midi-detector-status-not-announced.md) | Connection |
| 35 | [No screen reader announcements for loading/sync](no-state-announcements-for-loading-sync.md) | App-wide |
| 36 | [Progress indicators not announced](progress-indicators-not-announced.md) | App-wide |
| 37 | [Performance screen navigation rail labels not accessible](performance-screen-navigation-rail-labels.md) | Performance |
| 38 | [Preset browser three-panel navigation inaccessible](preset-browser-panel-navigation.md) | Presets |
| 39 | [Parameters/Routing mode switcher missing semantic context](segmented-button-mode-switcher-no-label.md) | Main navigation |
| 40 | [Step sequencer parameter mode not announced on change](step-sequencer-parameter-mode-selector.md) | Step sequencer |
| 41 | [Sync status indicator relies on color only](sync-status-indicator-color-only.md) | Status |

### Medium (27 issues)

These issues affect usability but don't completely block workflows.

| # | Issue | File |
|---|-------|------|
| 42 | [No high contrast mode support](app-wide-no-high-contrast-support.md) | App-wide |
| 43 | [Offline preset building accessibility](offline-preset-building-accessibility.md) | Offline mode |
| 44 | [Mini map widget completely inaccessible](06-mini-map-inaccessible.md) | Routing |
| 45 | [Ghost and invalid connection tooltips hover-only](08-ghost-invalid-tooltips-hover-only.md) | Routing |
| 46 | [Firmware flow diagram has no semantic description](11-firmware-flow-diagram-no-semantics.md) | Firmware |
| 47 | [AccessibilityColors class exists but not integrated](12-accessibility-colors-not-integrated.md) | Routing |
| 48 | [Physical I/O nodes have incomplete semantics](14-physical-io-nodes-good-but-incomplete-semantics.md) | Routing |
| 49 | [Canvas pan and node movement are gesture-only](15-node-movement-and-canvas-pan-not-accessible.md) | Routing |
| 50 | [Top-level port widget has no semantic information](17-top-level-port-widget-no-semantics.md) | Routing |
| 51 | [Algorithm list double-tap and long-press undiscoverable](algorithm-list-gesture-actions.md) | Main navigation |
| 52 | [BPM editor increment/decrement buttons lack context](bpm-editor-button-labels.md) | Parameters |
| 53 | [Confirmation dialogs don't announce destructive nature](confirmation-dialogs-destructive-actions.md) | Dialogs |
| 54 | [Contextual help bar invisible to screen readers](contextual-help-bar-invisible-to-screen-readers.md) | Help |
| 55 | [CPU monitor information only in tooltip](cpu-monitor-tooltip-only-information.md) | Status |
| 56 | [Gallery documentation button too small](gallery-documentation-button-tiny-tap-target.md) | Gallery |
| 57 | [Gallery filter chips use onDeleted hack](gallery-filter-chips-dropdown-workaround.md) | Gallery |
| 58 | [Linkified text has no semantic link role](linkified-text-tap-targets.md) | UI controls |
| 59 | [Mapping editor dirty state indicator not accessible](mapping-editor-dirty-state-indicator.md) | Mappings |
| 60 | [Notes algorithm view edit state unclear](notes-algorithm-view-edit-state-unclear.md) | Parameters |
| 61 | [Overflow menu items create duplicate screen reader content](overflow-menu-items-double-content.md) | Menus |
| 62 | [Package install dialog conflict resolution accessibility](package-install-conflict-resolution.md) | Plugins |
| 63 | [Playback controls sliders use opacity for disabled state](playback-controls-slider-labels.md) | Step sequencer |
| 64 | [Plugin manager expansion tile state unclear](plugin-manager-expansion-tiles-unclear-state.md) | Plugins |
| 65 | [Plugin selection checkbox list accessibility](plugin-selection-checkbox-list.md) | Plugins |
| 66 | [Randomize dialog sliders lack grouped labels](randomize-dialog-sliders-missing-context.md) | Dialogs |
| 67 | [Randomize settings dialog accessibility issues](randomize-settings-dialog-a11y.md) | Dialogs |
| 68 | [Range sliders missing semantic labels](range-slider-accessibility.md) | Parameters |
| 69 | [Performance page badges rely on color and short labels](section-parameter-page-badges-color-only.md) | Performance |

### Low (6 issues)

These issues are cosmetic or affect secondary features.

| # | Issue | File |
|---|-------|------|
| 70 | [Canvas grid background painter has no semantics](09-canvas-grid-painter-no-semantics.md) | Routing |
| 71 | [Algorithm documentation missing heading semantics](algorithm-documentation-missing-heading-semantics.md) | Documentation |
| 72 | [Debug diagnostics color-only status indicators](debug-diagnostics-color-only-indicators.md) | Debug |
| 73 | [Debug panel log accessibility](debug-panel-log-accessibility.md) | Debug |
| 74 | [Disting version unsupported state not communicated](disting-version-unsupported-state.md) | Status |
| 75 | [RTT stats data tables accessibility](rtt-stats-data-tables.md) | Debug |

---

## Keyboard Shortcuts Roadmap

A blind tester specifically requested keyboard shortcuts for all major features. A comprehensive keyboard navigation scheme has been designed: [keyboard-navigation-scheme.md](keyboard-navigation-scheme.md).

### Current State
- Only zoom shortcuts exist (`Cmd/Ctrl + Plus/Minus/0`) in routing editor
- Arrow key navigation in Add Algorithm screen
- No other keyboard shortcuts

### Implementation Plan

**Phase 1: Global Shortcuts** (Highest impact, moderate effort)
- `Mod+S` Save, `Mod+N` New, `Mod+O` Browse presets
- `Mod+1`/`Mod+2` Switch Parameters/Routing modes
- `Mod+[`/`Mod+]` Navigate algorithm slots
- Extend existing `KeyBindingService` with Intent/Action pairs

**Phase 2: Parameter Navigation** (Core workflow)
- Tab/Arrow keys through parameter list
- Enter to edit, Arrow keys to adjust values
- `M` key to open mapping editor
- Section navigation with `Mod+Up`/`Mod+Down`

**Phase 3: Routing Keyboard Navigation** (Critical for blind users)
- Tab through nodes, Enter to access ports
- Space to start/complete connections (two-press flow)
- Arrow keys for canvas pan
- Delete for connection removal

**Phase 4: Step Sequencer** (Music creation)
- Left/Right arrows for step navigation
- Up/Down for value adjustment
- Letter keys for parameter mode switching (P=Pitch, V=Velocity, etc.)
- Direct numeric entry

**Phase 5: Help & Polish**
- `Mod+/` shortcut help panel
- Focus restoration across all dialogs
- Screen reader announcements for all shortcut actions
- Preset browser and plugin manager navigation

### Design Principles
- Platform-native modifiers (Cmd on macOS, Ctrl on Windows/Linux)
- DAW-consistent conventions (Logic Pro, Ableton, Reaper patterns)
- Non-conflicting with system shortcuts
- Every action produces a screen reader announcement
- Single letter shortcuts only active when no text field is focused

---

## Offline Workflow for Blind Users

A blind tester requested offline preset building capability. The good news: **this already works**. The app supports both Demo mode (simulated hardware) and Offline mode (cached metadata from a previous connection). See [offline-preset-building-accessibility.md](offline-preset-building-accessibility.md) for details.

### What Works
- Full preset creation without hardware
- All parameter editing with value formatting
- Algorithm selection from cached library
- Preset save/load to local database
- Performance page assignment

### What Needs Improvement
1. **Discoverability**: Demo/Offline buttons need better semantic descriptions
2. **Mode announcements**: Entering offline mode should announce the capability
3. **Error handling**: Hardware-only operations should show friendly messages, not crash
4. **Upload workflow**: Reconnecting with offline presets needs a guided sync flow
5. **Documentation**: In-app help explaining the offline workflow

---

## Recommended Implementation Roadmap

### Phase 1: Quick Wins (1-2 weeks)

High-impact changes with minimal code modification:

1. **Add semantic labels to icon buttons** ([icon-buttons-missing-labels.md](icon-buttons-missing-labels.md))
   - Add `tooltip` to all `IconButton` widgets
   - Affects ~30 buttons across the app

2. **Add tooltips to segmented buttons** ([segmented-button-mode-switcher-no-label.md](segmented-button-mode-switcher-no-label.md))
   - Add `tooltip` to `ButtonSegment` widgets on mobile

3. **Add Semantics to parameter slider** ([parameter-slider-missing-semantics.md](parameter-slider-missing-semantics.md))
   - Wrap slider in `Semantics` with label, value, hint

4. **Add dialog semantic labels** ([dialog-missing-semantic-labels.md](dialog-missing-semantic-labels.md))
   - Add `semanticLabel` to `showDialog` calls

5. **Fix overflow menu duplicate content** ([overflow-menu-items-double-content.md](overflow-menu-items-double-content.md))
   - Add `excludeFromSemantics: true` to menu item icons

6. **Add mapping switch labels** ([mapping-editor-switch-labels.md](mapping-editor-switch-labels.md))
   - Add `Semantics` labels to switch controls

7. **Add MCP status semantics** ([mcp-status-indicator-inaccessible.md](mcp-status-indicator-inaccessible.md))
   - Wrap status indicator in `Semantics`

### Phase 2: Core Navigation (2-4 weeks)

Enable keyboard-only operation for the main workflow:

8. **Global keyboard shortcuts** ([keyboard-shortcuts-for-all-major-features.md](keyboard-shortcuts-for-all-major-features.md))
   - Extend `KeyBindingService` with global shortcuts
   - Save, new, browse, refresh, mode switching

9. **Focus traversal for parameter list**
   - Add `FocusTraversalGroup` to parameter list view
   - Make each parameter row focusable
   - Arrow key navigation between parameters

10. **SemanticsService announcements**
    - Add announcements for parameter value changes
    - Add announcements for mode switches
    - Add announcements for save/load confirmations
    - Add announcements for connection status changes

11. **Tab bar accessible actions** ([tab-bar-gestures-inaccessible.md](tab-bar-gestures-inaccessible.md))
    - Add `customSemanticsActions` for rename and focus

12. **Disabled parameter communication** ([disabled-parameter-not-communicated.md](disabled-parameter-not-communicated.md))
    - Wrap disabled parameters in `Semantics(enabled: false)`

13. **Live regions for value changes** ([parameter-value-display-no-live-region.md](parameter-value-display-no-live-region.md))
    - Add `liveRegion: true` to parameter value displays

### Phase 3: Complex Widgets (4-8 weeks)

Make the visual-heavy features accessible:

14. **Routing canvas screen reader representation** ([01-routing-canvas-no-screen-reader-representation.md](01-routing-canvas-no-screen-reader-representation.md))
    - Add semantic tree representing nodes and connections
    - Implement keyboard node/port navigation

15. **Keyboard connection creation** ([03-drag-and-drop-no-keyboard-alternative.md](03-drag-and-drop-no-keyboard-alternative.md))
    - Implement two-press Space connection flow
    - Screen reader announcements for connection state

16. **Step sequencer keyboard navigation** ([step-sequencer-grid-inaccessible.md](step-sequencer-grid-inaccessible.md))
    - Wrap each step in `Semantics` with value/increment/decrement
    - Arrow key navigation for grid
    - Letter keys for parameter mode switching

17. **Bit pattern editor keyboard support** ([bit-pattern-editor-inaccessible.md](bit-pattern-editor-inaccessible.md))
    - Arrow keys for bit navigation
    - Space/Enter to toggle bits

18. **Preset browser keyboard navigation** ([preset-browser-panel-navigation.md](preset-browser-panel-navigation.md))
    - Arrow keys for tree navigation
    - Enter to load, tab between panels

19. **Performance screen navigation** ([performance-screen-navigation-rail-labels.md](performance-screen-navigation-rail-labels.md))
    - Add labels to navigation rail items
    - Number keys for page switching

### Phase 4: Advanced Features (8-12 weeks)

Polish and complete coverage:

20. **Shortcut help panel**
    - Build `Mod+/` overlay showing all shortcuts
    - Context-sensitive display

21. **Focus restoration system**
    - Restore focus after dialog close
    - Restore focus after navigation transitions

22. **Text scaling support** ([app-wide-no-text-scaling-support.md](app-wide-no-text-scaling-support.md))
    - Test and fix layouts at 1.5x and 2.0x text scale

23. **High contrast mode** ([app-wide-no-high-contrast-support.md](app-wide-no-high-contrast-support.md))
    - Detect and respond to high contrast setting
    - Integrate `AccessibilityColors` class

24. **Accessibility test suite** ([app-wide-no-accessibility-tests.md](app-wide-no-accessibility-tests.md))
    - Add semantics assertions to existing widget tests
    - Add dedicated a11y workflow tests

25. **Offline mode discoverability** ([offline-preset-building-accessibility.md](offline-preset-building-accessibility.md))
    - Better semantic descriptions for Demo/Offline buttons
    - Mode transition announcements
    - Guided upload workflow on reconnect

---

## Priority Matrix: What a Blind Musician Needs Most

For a user making music with the Disting NT, these are the workflows ranked by importance:

| Priority | Workflow | Current State | Key Issues |
|----------|----------|---------------|------------|
| 1 | **Parameter control** | Broken - sliders have no semantics | #4, #5, #24, #25 |
| 2 | **Preset save/load** | Partially broken - no keyboard shortcuts, no announcements | #14, #38, #1 |
| 3 | **Algorithm selection** | Partially working - arrow keys exist, but favorites and gestures broken | #12, #13 |
| 4 | **Routing connections** | Completely broken - visual/drag only | #6, #7, #8, #9 |
| 5 | **Step sequencing** | Completely broken - canvas only | #10, #11, #40 |
| 6 | **Mapping configuration** | Mostly broken - switches unlabeled, tiny targets | #22, #32 |
| 7 | **Performance pages** | Broken - rail labels missing, color-only badges | #37, #69 |
| 8 | **Mode switching** | Broken on mobile - icon-only with no tooltips | #39, #2 |

---

## References

### Flutter Accessibility Documentation
- [Flutter Accessibility Overview](https://docs.flutter.dev/ui/accessibility-and-internationalization/accessibility)
- [Semantics Widget](https://api.flutter.dev/flutter/widgets/Semantics-class.html)
- [SemanticsService](https://api.flutter.dev/flutter/semantics/SemanticsService-class.html)
- [FocusTraversalGroup](https://api.flutter.dev/flutter/widgets/FocusTraversalGroup-class.html)
- [Shortcuts and Actions](https://docs.flutter.dev/ui/interactivity/actions-and-shortcuts)

### WCAG Guidelines
- [WCAG 2.1 Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)
- [1.3.1 Info and Relationships](https://www.w3.org/WAI/WCAG21/Understanding/info-and-relationships) - Semantics
- [2.1.1 Keyboard](https://www.w3.org/WAI/WCAG21/Understanding/keyboard) - All functionality via keyboard
- [4.1.2 Name, Role, Value](https://www.w3.org/WAI/WCAG21/Understanding/name-role-value) - Semantic labels

### Platform Screen Readers
- iOS: VoiceOver (built-in)
- Android: TalkBack (built-in)
- macOS: VoiceOver (built-in)
- Windows: NVDA (free) or JAWS
- Linux: Orca

### Audit Files in This Directory
- 75 individual issue files with severity, affected files, impact, and recommended fixes
- [keyboard-navigation-scheme.md](keyboard-navigation-scheme.md) - Complete keyboard shortcut design
- [keyboard-shortcuts-for-all-major-features.md](keyboard-shortcuts-for-all-major-features.md) - Shortcut roadmap overview
- [offline-preset-building-accessibility.md](offline-preset-building-accessibility.md) - Offline workflow analysis
