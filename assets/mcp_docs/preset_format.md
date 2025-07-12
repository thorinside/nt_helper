# Preset Format Reference

## JSON Structure for `build_preset_from_json`

### Complete Preset Structure
```json
{
  "preset_name": "My Preset",
  "slots": [
    {
      "algorithm": {
        "guid": "algorithm_guid",
        "name": "Algorithm Name"
      },
      "parameters": [
        {
          "parameter_number": 0,
          "value": 1.5
        }
      ]
    }
  ]
}
```

### Required Fields
- **`preset_name`**: String name for the preset
- **`slots`**: Array of slot configurations (max 32 slots)

### Slot Structure
- **`algorithm`**: Algorithm to load in this slot
  - **`guid`**: Exact algorithm GUID (preferred)
  - **`name`**: Algorithm name (fuzzy matching ≥70%)
- **`parameters`**: Array of parameter configurations (optional)

### Parameter Structure  
- **`parameter_number`**: 0-based parameter index (from `get_current_preset`)
- **`value`**: Display value (automatically scaled for device)

### Alternative Parameter Syntax
```json
{
  "parameter_name": "Frequency",
  "value": 440.0
}
```

### Empty Slots
- Use `null` in slots array for empty slots
- Slots are 0-indexed, so slot 4 is `slots[4]` (the 5th slot)

### Example: Audio Processing Chain
```json
{
  "preset_name": "Audio Chain",
  "slots": [
    {
      "algorithm": {"guid": "filt"},
      "parameters": [
        {"parameter_number": 0, "value": 1000},
        {"parameter_number": 1, "value": 0.7}
      ]
    },
    null,
    {
      "algorithm": {"name": "Reverb"},
      "parameters": [
        {"parameter_name": "Size", "value": 0.5}
      ]
    }
  ]
}
```