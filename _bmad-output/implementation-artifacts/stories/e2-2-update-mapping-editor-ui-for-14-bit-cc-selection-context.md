# Story Context: E2.2 - Update mapping editor UI for 14-bit CC selection

**Generated:** 2025-10-27
**Epic:** E2 - 14-bit MIDI CC Support
**Story:** E2.2 - Update mapping editor UI for 14-bit CC selection

---

## Story Summary

Update the MIDI mapping editor UI to expose "14 bit CC - low" and "14 bit CC - high" options in the type dropdown, and disable the "MIDI Relative" switch when 14-bit types are selected. This follows the reference HTML editor UI pattern for consistency across preset editors.

---

## Technical Context

### Architecture Alignment

**From `docs/architecture.md`:**
- UI layer in `lib/ui/` with widgets in `lib/ui/widgets/`
- State management using Flutter Bloc (Cubit pattern)
- Property editors follow existing patterns for parameter configuration
- UI changes must be visually consistent with existing design

**Key UI Patterns:**
- Dropdown menus use `DropdownButton<T>` widgets
- Switch controls use `Switch` widget with nullable `onChanged` (null = disabled)
- State updates via `setState()` in StatefulWidget
- Data models updated using Freezed `.copyWith()` method

### Related Components

**Property Editor System:**
- `lib/ui/widgets/packed_mapping_data_editor.dart` - MIDI mapping configuration UI
- Parameter property editor hosts this widget
- User selects MIDI type, controller number, and options
- Changes immediately update local state, saved on user confirmation

### Reference Implementation UI

From Expert Sleepers commit 3e52e54453eef243fe07e356718a97b081152209:

**HTML Dropdown (Line 987):**
```html
<select>
  <option value=0>CC</option>
  <option value=1>Note - momentary</option>
  <option value=2>Note - toggle</option>
  <option value=3>14 bit CC - low</option>
  <option value=4>14 bit CC - high</option>
</select>
```

**Flutter Equivalent:**
- Display text must match exactly: "14 bit CC - low", "14 bit CC - high"
- Order must match: CC, Note types, then 14-bit CC types
- Values map to `MidiMappingType` enum

### Current UI Implementation

**Current Dropdown:**
- 3 options: CC, Note - momentary, Note - toggle
- Bound to `_data.midiMappingType`
- Updates state on selection

**Current Relative Switch:**
- Enabled only for CC type
- Disabled for note types (momentary, toggle)
- Need to extend disable logic to include 14-bit types

---

## Code Locations

### Files to Modify

| File | Location | Changes Required |
|------|----------|------------------|
| `lib/ui/widgets/packed_mapping_data_editor.dart` | UI widgets | Add dropdown items, update disable logic |

### Related Files (Read Only - for context)

| File | Purpose |
|------|---------|
| `lib/models/packed_mapping_data.dart` | Data model with enum values (from E2.1) |
| `lib/ui/synchronized_screen.dart` | Parent screen hosting property editor |

---

## Implementation Details

### Dropdown Extension

**Add Two New Menu Items:**
```dart
DropdownButton<MidiMappingType>(
  value: _data.midiMappingType,
  items: [
    DropdownMenuItem(
      value: MidiMappingType.cc,
      child: const Text('CC'),
    ),
    DropdownMenuItem(
      value: MidiMappingType.noteMomentary,
      child: const Text('Note - momentary'),
    ),
    DropdownMenuItem(
      value: MidiMappingType.noteToggle,
      child: const Text('Note - toggle'),
    ),
    // NEW ITEMS:
    DropdownMenuItem(
      value: MidiMappingType.cc14BitLow,
      child: const Text('14 bit CC - low'),
    ),
    DropdownMenuItem(
      value: MidiMappingType.cc14BitHigh,
      child: const Text('14 bit CC - high'),
    ),
  ],
  onChanged: (MidiMappingType? newType) {
    if (newType != null) {
      setState(() {
        _data = _data.copyWith(midiMappingType: newType);
      });
    }
  },
)
```

### Relative Switch Disable Logic

**Update _canUseRelative() Method:**
```dart
bool _canUseRelative() {
  // Only standard 7-bit CC supports relative mode
  return _data.midiMappingType == MidiMappingType.cc;
}

// In Switch widget:
Switch(
  value: _data.midiRelative,
  onChanged: _canUseRelative() ? (bool value) {
    setState(() {
      _data = _data.copyWith(midiRelative: value);
    });
  } : null,  // null onChanged disables the switch (greyed out)
)
```

**Behavior:**
- CC type: Switch enabled
- All other types (note + 14-bit CC): Switch disabled (greyed out)

---

## Testing Strategy

### Widget Tests

Create/update `test/ui/widgets/packed_mapping_data_editor_test.dart`:

1. **Dropdown displays all 5 options**
2. **Selecting 14-bit type updates model**
3. **Relative switch disabled for 14-bit types**
4. **Relative switch enabled for CC type**
5. **Visual consistency verification**

### Manual Testing Checklist

**UI Behavior:**
- [ ] Open parameter property editor
- [ ] Navigate to MIDI mapping tab
- [ ] Click MIDI Type dropdown
- [ ] Verify 5 options displayed in correct order
- [ ] Select "14 bit CC - low"
- [ ] Verify relative switch becomes disabled (greyed out)
- [ ] Verify controller number field still enabled
- [ ] Select "CC"
- [ ] Verify relative switch becomes enabled
- [ ] Select "14 bit CC - high"
- [ ] Verify relative switch disabled again

**Visual Consistency:**
- [ ] Dropdown text size matches existing items
- [ ] Dropdown text color matches existing items
- [ ] Spacing between items consistent
- [ ] Disabled switch visual state clear (greyed out)
- [ ] No layout shifts when switching types

---

## Dependencies

### Prerequisites
- **Story E2.1** - MidiMappingType enum must include cc14BitLow and cc14BitHigh

### Blocks
- Story E2.3 (UI must be functional before SysEx testing)

---

## Implementation Notes

### UI Behavior Rules

1. **Dropdown Order:** CC → Note types → 14-bit CC types
2. **Text Labels:** Must match HTML editor exactly (consistency for users)
3. **Relative Mode:** Only CC supports relative, all other types disable it
4. **State Updates:** Use `copyWith()` to preserve other fields

### Code Style

- Use `const` for Text widgets where possible
- Use `debugPrint()` for any logging
- Follow existing widget tree structure
- Maintain null-safety throughout
- Use descriptive method names like `_canUseRelative()`

### Flutter Conventions

- StatefulWidget for interactive UI
- `setState()` for local state updates
- Nullable `onChanged` to disable widgets
- `DropdownMenuItem<T>` with explicit type parameter

---

## Definition of Done Checklist

- [ ] Dropdown includes "14 bit CC - low" and "14 bit CC - high"
- [ ] All 5 MIDI types displayed in correct order
- [ ] Selecting 14-bit type updates data model
- [ ] Relative switch disabled for 14-bit CC types
- [ ] Relative switch enabled for CC type
- [ ] UI visually consistent with existing design
- [ ] Widget tests written and passing
- [ ] Manual testing completed
- [ ] `flutter analyze` passes with zero warnings
- [ ] Screenshots captured for documentation

---

## Epic Context Reference

See `docs/tech-spec-epic-2.md` for full epic technical specification.
