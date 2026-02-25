# Keyboard Navigation & Shortcut Scheme

Comprehensive keyboard navigation design for NT Helper, enabling full operation via keyboard and screen reader without mouse/touch.

## Design Principles

1. **Platform-native modifiers**: `Cmd` on macOS, `Ctrl` on Windows/Linux (notated as `Mod` below)
2. **DAW-consistent**: Shortcuts follow conventions from Logic Pro, Ableton, Reaper where applicable
3. **Discoverable**: Shortcut help panel accessible via `Mod+/` or `?`
4. **Non-conflicting**: Avoids system-reserved shortcuts (Cmd+Q, Cmd+W, Cmd+Tab, etc.)
5. **Progressive**: Basic navigation uses standard Tab/Arrow patterns; power shortcuts layer on top
6. **Screen reader friendly**: All shortcut actions produce semantic announcements

## Implementation Architecture

Extend the existing `KeyBindingService` with a comprehensive `Intent`/`Action` system. All shortcuts use Flutter's `Shortcuts` + `Actions` widgets for testability and discoverability.

```
KeyBindingService
  ├── desktopZoomShortcuts (existing)
  ├── globalShortcuts (new)
  ├── parameterModeShortcuts (new)
  ├── routingModeShortcuts (new)
  ├── stepSequencerShortcuts (new)
  └── dialogShortcuts (new)
```

---

## 1. Global Shortcuts (Available Everywhere)

These work on any screen when no text field is focused.

| Shortcut | Action | Intent Class | Notes |
|----------|--------|-------------|-------|
| `Mod+S` | Save preset | `SavePresetIntent` | Mirrors every DAW |
| `Mod+N` | New preset | `NewPresetIntent` | Shows confirmation if algorithms exist |
| `Mod+O` | Browse/open presets | `BrowsePresetsIntent` | Opens preset browser dialog |
| `Mod+A` | Add algorithm | `AddAlgorithmIntent` | Same as FAB button |
| `Mod+R` | Refresh | `RefreshIntent` | Re-syncs from hardware |
| `Mod+,` | Settings | `OpenSettingsIntent` | macOS convention |
| `Mod+/` or `?` | Show shortcut help | `ShowShortcutHelpIntent` | Overlay listing all shortcuts |
| `Mod+P` | Performance screen | `OpenPerformanceIntent` | Quick access to perform mode |
| `Escape` | Close dialog/sheet/cancel | (built-in) | Standard dismiss |
| `F5` | Refresh | `RefreshIntent` | Windows convention alternative |

### Mode Switching

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+1` | Switch to Parameters mode | SegmentedButton selection |
| `Mod+2` | Switch to Routing mode | SegmentedButton selection |

### Algorithm Selection (Main Screen)

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+[` | Previous algorithm/slot | Moves selection up in list |
| `Mod+]` | Next algorithm/slot | Moves selection down in list |
| `Mod+Shift+[` | Move algorithm up | Reorders slot in preset |
| `Mod+Shift+]` | Move algorithm down | Reorders slot in preset |
| `Mod+Backspace` | Remove selected algorithm | Shows confirmation dialog |

---

## 2. Focus Management Strategy

### Tab Order (Main Synchronized Screen)

Focus flows in a logical reading order using `FocusTraversalGroup` with `OrderedTraversalPolicy`:

```
[App Bar]
  1. Preset name button
  2. Refresh button
  3. Mode-specific action buttons (Move Up, Move Down, Remove)
  4. Overflow menu button

[Main Content - Parameters Mode]
  5. Algorithm list (sidebar on wide, tab bar on narrow)
     - Each algorithm is a focusable list item
  6. Parameter sections
     - Section headers (expandable)
     - Parameter rows within each section
       - Parameter name (read-only label)
       - Parameter value (editable)
       - Mapping button

[Main Content - Routing Mode]
  7. Routing canvas (FocusTraversalGroup)
     - Algorithm nodes (ordered by slot number)
       - Node header (name, slot number)
       - Input ports (top to bottom)
       - Output ports (top to bottom)
     - Physical input nodes
     - Physical output nodes

[Bottom Bar]
  8. Mode selector (Parameters / Routing)
  9. Display mode buttons
  10. MCP status indicator
  11. Version display
```

### Focus Restoration Rules

- After closing a dialog: restore focus to the element that triggered it
- After adding an algorithm: focus the new algorithm in the list
- After deleting an algorithm: focus the next algorithm (or previous if last was deleted)
- After creating a routing connection: focus the destination port
- After deleting a connection: focus the source port
- After mode switch: focus the first element in the new mode

### Focus Indicators

Every focusable element must show a visible focus ring (2px solid, theme primary color) distinct from the selection highlight. Use `FocusableActionDetector` or `Focus` widgets with `onFocusChange` to manage visual state.

---

## 3. Parameters Mode Shortcuts

### Parameter List Navigation

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Tab` | Next parameter | Standard forward traversal |
| `Shift+Tab` | Previous parameter | Standard backward traversal |
| `Up Arrow` | Previous parameter | Within focused parameter list |
| `Down Arrow` | Next parameter | Within focused parameter list |
| `Home` | First parameter | Jump to top |
| `End` | Last parameter | Jump to bottom |
| `Enter` or `Space` | Edit focused parameter | Opens editor or activates control |
| `M` | Open mapping editor | Opens mapping bottom sheet for focused parameter |
| `Mod+Z` | Undo last parameter change | Standard undo |

### Parameter Value Editing

When a parameter value editor is focused:

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Up Arrow` | Increment value by 1 | Standard slider behavior |
| `Down Arrow` | Decrement value by 1 | |
| `Page Up` | Increment by 10 | Coarse adjustment |
| `Page Down` | Decrement by 10 | Coarse adjustment |
| `Shift+Up` | Increment by 10 | Alternative coarse adjustment |
| `Shift+Down` | Decrement by 10 | Alternative coarse adjustment |
| `Home` | Set to minimum | |
| `End` | Set to maximum | |
| `Enter` | Confirm and move to next | Commits value, advances focus |
| `Escape` | Cancel edit | Reverts to previous value |
| `0-9`, `.`, `-` | Direct numeric entry | Opens inline text field |

For enum/dropdown parameters:

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Up Arrow` | Previous enum value | Cycle through options |
| `Down Arrow` | Next enum value | Cycle through options |
| `Space` or `Enter` | Open dropdown | Show full list |
| First letter | Jump to matching option | Type-ahead search |

### Section Navigation

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+Up` | Previous section header | Jump between parameter sections |
| `Mod+Down` | Next section header | Jump between parameter sections |
| `Left Arrow` | Collapse section | When section header is focused |
| `Right Arrow` | Expand section | When section header is focused |

### Display Mode Switching

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+Shift+1` | Parameter List view | Hardware parameter view |
| `Mod+Shift+2` | Algorithm UI view | Custom algorithm interface |
| `Mod+Shift+3` | Overview UI view | All slots at once |
| `Mod+Shift+4` | Overview VU Meters | Real-time levels |

---

## 4. Routing Mode Shortcuts

### Canvas Navigation

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+=` / `Mod++` | Zoom in | Existing implementation |
| `Mod+-` | Zoom out | Existing implementation |
| `Mod+0` | Reset zoom to 100% | Existing implementation |
| `Mod+Shift+F` | Fit all nodes in view | Centers and scales to show everything |
| `Arrow keys` | Pan canvas | 50px per keypress (matches grid snap) |
| `Shift+Arrow keys` | Pan canvas fast | 200px per keypress |

### Node Navigation

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Tab` | Next node | Cycles through nodes in slot order |
| `Shift+Tab` | Previous node | Reverse cycle |
| `Enter` | Enter node (port list) | Shifts focus into the node's ports |
| `Escape` | Exit node / clear selection | Returns to node-level navigation |
| `I` | Jump to node's input ports | Quick access |
| `O` | Jump to node's output ports | Quick access |

### Node Actions (When Node is Focused)

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+Shift+Up` | Move node up (slot order) | Same as toolbar button |
| `Mod+Shift+Down` | Move node down (slot order) | Same as toolbar button |
| `Delete` / `Backspace` | Delete node | Shows confirmation |
| `Mod+Shift+R` | Reset node connections | Clears all connections for this node |
| `Arrow keys` | Move node position | 50px grid-snapped movement |
| `Shift+Arrow keys` | Fine move node position | 10px movement |
| `F` | Toggle focus mode | Dims all other nodes to focus on this one |

### Port Navigation (Inside a Node)

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Up Arrow` | Previous port | Within current node |
| `Down Arrow` | Next port | Within current node |
| `Tab` | Next port (wraps to next node) | Cross-node traversal |
| `Shift+Tab` | Previous port | Reverse |
| `Space` | Start/complete connection | Two-press flow (see below) |
| `Enter` | Start/complete connection | Alternative to Space |
| `Delete` | Delete connection on port | If port has a connection |
| `Escape` | Cancel pending connection | Aborts connection creation |

### Keyboard Connection Creation Flow

This is the accessible alternative to drag-to-connect:

1. Navigate to source port using Tab/Arrow keys
2. Press `Space` to select it as connection source
3. Screen reader announces: "Selected [Port Name] as source. Navigate to a destination port and press Space to connect."
4. Navigate to destination port
5. Press `Space` to complete the connection
6. Screen reader announces: "Connected [Source] to [Destination]"
7. Press `Escape` at any point to cancel

### Connection Navigation

| Shortcut | Action | Notes |
|----------|--------|-------|
| `C` | Cycle through connections | When on a connected port, cycles focus through its connections |
| `Delete` | Delete focused connection | Existing implementation |
| `Backspace` | Delete focused connection | Alternative |

---

## 5. Step Sequencer Shortcuts

The step sequencer presents a 16-step grid. Keyboard navigation treats it as a 2D grid (steps x parameters).

### Grid Navigation

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Left Arrow` | Previous step | Wraps at boundaries |
| `Right Arrow` | Next step | Wraps at boundaries |
| `Up Arrow` | Increment value | +1 for current parameter on current step |
| `Down Arrow` | Decrement value | -1 for current parameter on current step |
| `Shift+Up` | Coarse increment | +10 for pitch/velocity/mod |
| `Shift+Down` | Coarse decrement | -10 for pitch/velocity/mod |
| `Page Up` | Large increment | +12 for pitch (one octave), +10 for others |
| `Page Down` | Large decrement | -12 for pitch (one octave), -10 for others |
| `Home` | Set to minimum | Parameter minimum |
| `End` | Set to maximum | Parameter maximum |
| `0-9` | Direct value entry | Opens inline editor for numeric input |
| `Tab` | Next step | Forward traversal |
| `Shift+Tab` | Previous step | Backward traversal |

### Parameter Mode Switching

| Shortcut | Action | Notes |
|----------|--------|-------|
| `P` | Pitch mode | Select pitch parameter |
| `V` | Velocity mode | Select velocity parameter |
| `G` | Gate mode | Select gate/division parameter |
| `T` | Ties mode | Select ties parameter |
| `B` | Bit pattern mode | Select pattern parameter |
| `Shift+M` | Modulation mode | Select mod parameter |

### Playback & Editing

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+Z` | Undo last quantize | Reverts last quantization operation |
| `Mod+Shift+Z` | Redo | If undo history supports redo |
| `Q` | Quantize all steps | Apply scale quantization |
| `Mod+Shift+R` | Randomize | Opens randomize settings dialog |
| `S` | Toggle snap/quantize | Enable/disable snap-to-scale |

### Sequence Selection

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+Left` | Previous sequence | Sequences 0-31 |
| `Mod+Right` | Next sequence | Sequences 0-31 |

### Bit Pattern Editing (Pattern/Ties Modes)

When in Pattern or Ties mode, each step shows 8 toggle bits:

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Up Arrow` | Move to higher bit | Bit 0 (bottom) to Bit 7 (top) |
| `Down Arrow` | Move to lower bit | |
| `Space` or `Enter` | Toggle bit | Set/unset the focused bit |
| `Left/Right Arrow` | Previous/next step | Navigate between steps |
| `A` | Set all valid bits | Fill pattern |
| `Mod+A` | Clear all bits | Clear pattern |

---

## 6. Add Algorithm Screen Shortcuts

This screen already has arrow key navigation (existing implementation in `add_algorithm_screen.dart`). Additional shortcuts:

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Up/Down Arrow` | Navigate algorithms | Existing implementation |
| `Left/Right Arrow` | Navigate algorithms | Existing implementation |
| `Enter` or `Space` | Select algorithm | Existing implementation |
| `/` or `Mod+F` | Focus search field | Jump to search input |
| `Escape` | Clear search / go back | Clear filter first, then navigate back |
| `F` | Toggle favorites filter | Quick filter toggle |
| `Mod+1` through `Mod+4` | Switch view mode | Grid, List, Column, Category |
| `?` or `Mod+I` | View algorithm documentation | Opens documentation screen |

### Category Filter Navigation

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Tab` | Next category chip | Navigate filter chips |
| `Shift+Tab` | Previous category chip | |
| `Space` or `Enter` | Toggle category | Select/deselect filter |
| `Mod+Backspace` | Clear all filters | Reset to unfiltered |

---

## 7. Performance Screen Shortcuts

| Shortcut | Action | Notes |
|----------|--------|-------|
| `1` - `5` | Switch to page P1-P5 | Quick page selection |
| `Up/Down Arrow` | Navigate parameters | Within current page |
| `Left/Right Arrow` | Adjust parameter value | |
| `Space` | Toggle polling | Start/stop live parameter updates |
| `Escape` | Return to main screen | |

---

## 8. Preset Browser Shortcuts

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Up/Down Arrow` | Navigate preset list | |
| `Left Arrow` | Collapse folder / go to parent | Filesystem-style navigation |
| `Right Arrow` | Expand folder / enter | |
| `Enter` | Load selected preset | Primary action |
| `Mod+Enter` | Append preset | Secondary action |
| `/` or `Mod+F` | Focus search/filter | |
| `Escape` | Close browser | |
| `Home` | Jump to first item | |
| `End` | Jump to last item | |
| `Tab` | Cycle panels | Navigate between tree and action buttons |

---

## 9. Mapping Editor Shortcuts (Bottom Sheet)

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+1` | CV tab | Switch to CV mapping |
| `Mod+2` | MIDI tab | Switch to MIDI mapping |
| `Mod+3` | I2C tab | Switch to I2C mapping |
| `Mod+4` | Performance tab | Switch to Performance mapping |
| `Tab` | Next field | Standard form traversal |
| `Shift+Tab` | Previous field | |
| `Escape` | Close editor | Dismiss bottom sheet |
| `L` | Start MIDI Learn | When in MIDI tab, begins listening for CC |

---

## 10. Plugin Manager Screen Shortcuts

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Mod+1` | Available plugins tab | |
| `Mod+2` | Installed plugins tab | |
| `/` or `Mod+F` | Focus search | Jump to search field |
| `Up/Down Arrow` | Navigate plugin list | |
| `Enter` | Install/manage selected | Primary action on focused plugin |
| `Escape` | Close / go back | |

---

## 11. Dialog & Confirmation Shortcuts

All dialogs follow Flutter's built-in dialog keyboard handling, plus:

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Enter` | Confirm / primary action | Activates primary button |
| `Escape` | Cancel / dismiss | Activates cancel button |
| `Tab` | Navigate between buttons | Standard focus traversal |
| `Mod+Backspace` | Destructive action | For "Delete", "Discard" confirmations (requires focus on the destructive button) |

### Rename Dialogs (Preset/Slot)

| Shortcut | Action | Notes |
|----------|--------|-------|
| `Enter` | Confirm rename | Submit the text field |
| `Escape` | Cancel | Dismiss without changes |
| `Mod+A` | Select all text | Standard text editing |

---

## 12. Shortcut Help Panel

Accessible via `Mod+/` or `?` (when no text field is focused). Displays a modal overlay organized by context:

```
┌─────────────────────────────────────────┐
│ Keyboard Shortcuts           [Escape]   │
├─────────────────────────────────────────┤
│ Global                                  │
│   Mod+S        Save Preset              │
│   Mod+N        New Preset               │
│   Mod+O        File Browser             │
│   Mod+A        Add Algorithm            │
│   Mod+R        Refresh                  │
│   Mod+1/2      Parameters / Routing     │
│   Mod+[/]      Previous / Next Slot     │
│                                         │
│ Parameters                              │
│   Up/Down      Navigate parameters      │
│   Enter        Edit parameter           │
│   M            Open mapping editor      │
│   Mod+Up/Down  Jump sections            │
│                                         │
│ Routing                                 │
│   Tab          Next node                │
│   Enter        Enter node ports         │
│   Space        Start/end connection     │
│   Delete       Remove connection        │
│   Arrows       Pan canvas               │
│   F            Toggle focus mode        │
│                                         │
│ Step Sequencer                          │
│   Left/Right   Navigate steps           │
│   Up/Down      Adjust value             │
│   P/V/G/T/B    Switch parameter mode    │
│   Q            Quantize                 │
│   Mod+Z        Undo quantize            │
└─────────────────────────────────────────┘
```

The panel should be a semantic dialog with `role="dialog"` and each shortcut as a description list item so screen readers can navigate it efficiently.

---

## 13. Screen Reader Announcements

Every keyboard action must produce an appropriate announcement via `SemanticsService.announce()`:

| Action | Announcement |
|--------|-------------|
| Save preset | "Preset saved" |
| Algorithm selected | "Slot [N]: [Algorithm Name] selected" |
| Parameter value changed | "[Parameter Name] set to [Value] [Unit]" |
| Mode switched | "Switched to [Parameters/Routing] mode" |
| Connection created | "Connected [Source Port] to [Destination Port]" |
| Connection deleted | "Connection removed between [Source] and [Destination]" |
| Node focused | "Slot [N]: [Algorithm], [X] inputs, [Y] outputs" |
| Port focused | "[Port Name], [input/output], [connected to X / not connected]" |
| Sequencer step changed | "Step [N], [Parameter] set to [Value]" |
| Connection mode entered | "Connection mode. Select a destination port and press Space" |
| Connection mode cancelled | "Connection cancelled" |
| Zoom changed | "Zoom [N]%" |
| Canvas panned | (no announcement - too frequent) |

---

## 14. Implementation Priority

### Phase 1: Foundation (High Impact, Moderate Effort)

1. **Global shortcuts** (`Mod+S`, `Mod+N`, `Mod+O`, `Mod+R`, mode switching)
   - Extend `KeyBindingService` with new Intent/Action pairs
   - Wrap `SynchronizedScreen` in `Shortcuts` + `Actions`
   - Immediate value for all keyboard users

2. **Parameter list keyboard navigation** (Tab, Arrow keys, Enter to edit)
   - Add `FocusTraversalGroup` to parameter list
   - Make each `ParameterViewRow` focusable
   - Add value adjustment via Arrow keys on focused parameter

3. **Algorithm list keyboard navigation** (`Mod+[`, `Mod+]`)
   - Connect to existing `_selectedIndex` state
   - Focus restoration on selection change

### Phase 2: Core Workflows (High Impact, Higher Effort)

4. **Routing node/port keyboard navigation** (Tab through nodes, Enter to enter ports)
   - Add `FocusNode` per node and per port
   - Implement `FocusTraversalGroup` with `OrderedTraversalPolicy`
   - Port focus indicators

5. **Keyboard connection creation** (Space to start/complete)
   - Implement two-press connection flow
   - Screen reader announcements for connection state
   - `Escape` to cancel pending connection

6. **Step sequencer keyboard navigation** (Arrow keys for grid, direct value entry)
   - Focus management for 16-step grid
   - Value adjustment with Arrow/Page keys
   - Parameter mode switching with letter keys

### Phase 3: Polish (Medium Impact, Moderate Effort)

7. **Shortcut help panel** (`Mod+/`)
   - Build help overlay widget
   - Context-sensitive (shows relevant shortcuts for current screen)

8. **Canvas pan/zoom keyboard controls** (Arrow keys for pan, existing zoom)
   - Arrow key pan with `ScrollController` integration
   - Fit-to-view shortcut (`Mod+Shift+F`)

9. **Focus restoration** across all dialogs and navigation transitions

10. **Preset browser keyboard navigation** (arrow keys, expand/collapse)

### Phase 4: Refinement (Lower Impact, Lower Effort)

11. **Performance screen shortcuts** (page switching, parameter editing)
12. **Plugin manager keyboard navigation**
13. **Mapping editor tab switching and field navigation**
14. **Tooltip/hint integration** with shortcut hints in button tooltips

---

## 15. Conflict Avoidance Matrix

### Reserved System Shortcuts (Do NOT Override)

| Platform | Shortcut | System Action |
|----------|----------|---------------|
| macOS | `Cmd+Q` | Quit application |
| macOS | `Cmd+W` | Close window |
| macOS | `Cmd+H` | Hide application |
| macOS | `Cmd+M` | Minimize |
| macOS | `Cmd+Tab` | App switcher |
| macOS | `Cmd+Space` | Spotlight |
| macOS | `Cmd+C/V/X` | Copy/Paste/Cut |
| Windows | `Ctrl+Alt+Del` | System menu |
| Windows | `Alt+Tab` | Window switcher |
| Windows | `Alt+F4` | Close window |
| All | `Tab` | Focus traversal (override contextually only) |

### Existing App Shortcuts (Preserve)

| Shortcut | Current Usage | Location |
|----------|--------------|----------|
| `Mod+=`/`Mod++` | Zoom in | Routing editor |
| `Mod+-` | Zoom out | Routing editor |
| `Mod+0` | Reset zoom | Routing editor |
| `Escape` | Cancel/clear | Routing editor |
| `Delete`/`Backspace` | Delete connection | Routing editor |
| `Arrow keys` | Navigate algorithms | Add algorithm screen |
| `Enter`/`Space` | Select algorithm | Add algorithm screen |

### Letter Key Shortcuts (Context-Sensitive Only)

Single letter shortcuts (`P`, `V`, `G`, `T`, `B`, `F`, `M`, `Q`, `S`, `C`, `I`, `O`, `L`) are only active when:
- No text field has focus
- The relevant screen/context is active
- A `FocusNode` on the appropriate widget has focus

This prevents conflicts with text input. Implementation: check `FocusManager.instance.primaryFocus` is not a `TextFormField` or `TextField` before handling letter shortcuts.

---

## 16. Testing Strategy

### Unit Tests (KeyBindingService)

Extend existing `key_binding_service_test.dart`:
- Test each new shortcut map contains expected activators
- Test platform-specific modifier resolution
- Test action callbacks invoke correct operations
- Test letter shortcuts are context-guarded

### Widget Tests

- Test Tab order matches specification for each screen
- Test focus restoration after dialog close
- Test Enter/Space activates focused elements
- Test Escape dismisses dialogs and cancels operations
- Test Arrow key navigation in parameter lists and step grid
- Test connection creation keyboard flow (select source, navigate, select destination)

### Integration Tests

- Full workflow: open app, navigate to algorithm, edit parameter, save preset - all keyboard
- Full workflow: create routing connection via keyboard
- Full workflow: edit step sequencer pattern via keyboard
- Verify screen reader announcements fire correctly

---

## 17. Flutter Implementation Notes

### Shortcuts Widget Hierarchy

```dart
// At SynchronizedScreen level - global shortcuts
Shortcuts(
  shortcuts: _keyBindingService.globalShortcuts,
  child: Actions(
    actions: _keyBindingService.buildGlobalActions(
      onSavePreset: () => cubit.requireDisting().requestSavePreset(),
      onNewPreset: () => _handleNewPreset(cubit),
      onBrowsePresets: () => _handleBrowsePresets(cubit),
      onRefresh: () => cubit.refreshAll(),
      onAddAlgorithm: () => _navigateToAddAlgorithm(),
      onSwitchToParameters: () => setState(() => _currentMode = EditMode.parameters),
      onSwitchToRouting: () => setState(() => _currentMode = EditMode.routing),
      // ...
    ),
    child: // existing content
  ),
)
```

### FocusTraversalGroup for Parameter List

```dart
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: ListView.builder(
    itemBuilder: (context, index) {
      return FocusTraversalOrder(
        order: NumericFocusOrder(index.toDouble()),
        child: ParameterViewRow(/* ... */),
      );
    },
  ),
)
```

### Focusable Parameter Row Pattern

```dart
class ParameterViewRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => _startEditing(),
        ),
        // M key for mapping
      },
      child: Semantics(
        label: '$parameterName: $valueString $unit',
        hint: 'Press Enter to edit, M to open mapping',
        child: // existing row content
      ),
    );
  }
}
```

### Keyboard Connection Flow State

```dart
// In RoutingEditorWidget state
Port? _pendingConnectionSource;

void _handlePortActivation(Port port) {
  if (_pendingConnectionSource == null) {
    _pendingConnectionSource = port;
    SemanticsService.announce(
      'Selected ${port.label} as connection source. '
      'Navigate to a destination port and press Space to connect, '
      'or press Escape to cancel.',
      TextDirection.ltr,
    );
  } else {
    _createConnection(_pendingConnectionSource!, port);
    _pendingConnectionSource = null;
  }
}
```
