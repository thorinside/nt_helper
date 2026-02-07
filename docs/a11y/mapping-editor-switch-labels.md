# Mapping Editor Switch Controls Missing Accessible Labels

**Severity: Critical**

**Status: Addressed (2026-02-06)** — in commit 664e27b

## Files Affected

- `lib/ui/widgets/packed_mapping_data_editor.dart` (lines 447-478, 613-656, 785-812)

## Description

Throughout the `PackedMappingDataEditor`, toggle switches are paired with adjacent `Text` widgets in `Row` layouts rather than using properly labeled switch controls. VoiceOver and TalkBack cannot programmatically associate the text label with the switch control.

Affected switches:
- **CV Tab**: "Unipolar" (line 448-463), "Gate" (line 465-478)
- **MIDI Tab**: "MIDI Enabled" (line 614-626), "MIDI Symmetric" (line 628-640), "MIDI Relative" (line 642-656)
- **I2C Tab**: "I2C Enabled" (line 786-798), "I2C Symmetric" (line 800-812)

Each follows this pattern:
```dart
Row(
  children: [
    const Text('Unipolar'),  // Not programmatically linked
    Switch(
      value: _data.isUnipolar,
      onChanged: (val) { ... },
    ),
  ],
)
```

## Impact on Blind Users

- Screen readers will announce the switch as "Switch, off" or "Switch, on" without any label indicating what the switch controls
- Users cannot determine which setting they are toggling
- This is especially confusing in the mapping editor where there are many switches in sequence
- A user navigating through the MIDI tab would hear "Switch on, Switch off, Switch on" without any way to know which is MIDI Enabled vs. MIDI Symmetric vs. MIDI Relative

## Recommended Fix

Replace `Row` + `Text` + `Switch` with `SwitchListTile` which properly associates the label:

```dart
SwitchListTile(
  title: const Text('Unipolar'),
  value: _data.isUnipolar,
  onChanged: (val) {
    setState(() {
      _data = _data.copyWith(isUnipolar: val);
    });
    _triggerOptimisticSave();
  },
),
```

Alternatively, wrap the `Switch` in a `Semantics` widget:

```dart
Row(
  children: [
    const Text('Unipolar'),
    Semantics(
      label: 'Unipolar',
      child: Switch(
        value: _data.isUnipolar,
        onChanged: (val) { ... },
      ),
    ),
  ],
)
```
