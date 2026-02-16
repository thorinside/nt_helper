# MCP API Guide for Disting NT

## Overview

The Disting NT MCP (Model Context Protocol) API provides 15 individual, well-named tools for interacting with your hardware. Each tool does one thing with a flat parameter structure, making it easy for any LLM to use correctly.

### Design Philosophy

- **15 individual tools**: Each tool has a single purpose with simple parameters
- **No multiplexing**: No `target` parameters to route behavior — tool name says what it does
- **Flat schemas**: Parameters are top-level, not nested inside `data` objects
- **Mapping support**: Full CV/MIDI/i2c/performance page mapping for parameter control
- **Snake_case JSON**: All response fields use snake_case for LLM compatibility

### Important: Field Naming Convention

**All JSON fields use snake_case, not camelCase.**

- Correct: `midi_channel`, `is_midi_enabled`, `cv_input`
- Incorrect: `midiChannel`, `isMidiEnabled`, `cvInput`

## Tool Reference

### Search Tools

#### search_algorithms

Search for algorithms by name, category, description, use cases, parameter names, or port descriptions. Supports fuzzy name matching, BM25 text search across all fields, and synonym expansion for common Eurorack terminology.

**Parameters**:
- `query` (required, string): Algorithm name, partial name, category, or descriptive terms (e.g., "reverb", "pitch shifting", "clock divider", "resonance")

**Returns**: Top 10 matches sorted by relevance with GUID, name, category, and description.

**Search capabilities**:
- **Exact/fuzzy name match**: "Clock", "Oscilator" (typo-tolerant)
- **Category match**: "Filter", "Audio-IO"
- **Description keywords**: "tempo synchronization", "voltage controlled"
- **Parameter names**: "resonance", "cutoff", "feedback"
- **Synonym expansion**: "echo" finds delay algorithms, "wobble" finds modulation/LFO

```json
{"tool": "search_algorithms", "arguments": {"query": "filter"}}
```

```json
{"tool": "search_algorithms", "arguments": {"query": "echo"}}
```

```json
{"tool": "search_algorithms", "arguments": {"query": "pitch shifting"}}
```

---

#### search_parameters

Search for parameters by name within the current preset or a specific slot.

**Parameters**:
- `query` (required, string): Parameter name (case-insensitive)
- `scope` (optional, string): "preset" (all slots) or "slot" (specific slot)
- `slot_index` (optional, integer): Slot index (0-31), required when scope is "slot"
- `partial_match` (optional, boolean): If true, find parameters containing the query. Default: false

```json
{"tool": "search_parameters", "arguments": {"query": "Cutoff", "scope": "preset"}}
```

```json
{"tool": "search_parameters", "arguments": {"query": "freq", "scope": "slot", "slot_index": 0, "partial_match": true}}
```

---

### Show Tools

#### show_preset

Show the complete preset with all slots, parameters, and enabled mappings.

**Parameters**: None

**Returns**: Complete preset state including name, all slots, parameters, and enabled mappings.

```json
{"tool": "show_preset", "arguments": {}}
```

---

#### show_slot

Show a single slot with its algorithm, parameters, and enabled mappings.

**Parameters**:
- `slot_index` (required, integer): Slot index (0-31)

```json
{"tool": "show_slot", "arguments": {"slot_index": 0}}
```

---

#### show_parameter

Show a single parameter with its value, range, unit, and enabled mappings.

**Parameters**:
- `slot_index` (required, integer): Slot index (0-31)
- `parameter` (required, integer): Parameter number (0-based index)

```json
{"tool": "show_parameter", "arguments": {"slot_index": 0, "parameter": 5}}
```

---

#### show_screen

Capture and return the current device screen as a base64 JPEG image.

**Parameters**:
- `display_mode` (optional, string): Display mode to switch to before capturing. Options: "parameter", "algorithm", "overview", "vu_meters"

```json
{"tool": "show_screen", "arguments": {}}
```

```json
{"tool": "show_screen", "arguments": {"display_mode": "overview"}}
```

---

#### show_routing

Show the current signal routing state with input/output bus assignments for all slots.

**Parameters**: None

```json
{"tool": "show_routing", "arguments": {}}
```

---

#### show_cpu

Show CPU usage for the device and per-slot usage breakdown.

**Parameters**: None

```json
{"tool": "show_cpu", "arguments": {}}
```

---

### Edit Tools

#### edit_preset

Edit the entire preset state including name and all slots. Replaces the full preset.

**Parameters**:
- `data` (required, object): Full preset data with `name` and `slots` array

**Use when**: Restructuring preset, reordering algorithms, bulk changes.

```json
{
  "tool": "edit_preset",
  "arguments": {
    "data": {
      "name": "Updated Preset",
      "slots": [
        {
          "algorithm": {"name": "Oscillator"},
          "parameters": [{"parameter_number": 0, "value": 1.5}]
        },
        {
          "algorithm": {"name": "Filter"},
          "parameters": [{"parameter_number": 2, "value": 0.8}]
        }
      ]
    }
  }
}
```

---

#### edit_slot

Edit a specific slot: change algorithm, set parameters, or rename.

**Parameters**:
- `slot_index` (required, integer): Slot index (0-31)
- `data` (required, object): Slot data with optional `algorithm`, `parameters`, and `name`

**Use when**: Changing algorithm in single slot, updating all parameters for one algorithm.

```json
{
  "tool": "edit_slot",
  "arguments": {
    "slot_index": 0,
    "data": {
      "algorithm": {"name": "Wavetable Oscillator"},
      "parameters": [
        {
          "parameter_number": 0,
          "value": 1.0,
          "mapping": {
            "midi": {
              "is_midi_enabled": true,
              "midi_channel": 0,
              "midi_type": "cc",
              "midi_cc": 74
            }
          }
        }
      ]
    }
  }
}
```

---

#### edit_parameter

Edit a single parameter value and/or mapping.

**Parameters**:
- `slot_index` (required, integer): Slot index (0-31)
- `parameter` (required, string or integer): Parameter name or number (0-based)
- `value` (optional, number): Parameter value (omit to update only mapping)
- `mapping` (optional, object): CV/MIDI/i2c/performance page mapping

**Use when**: Quick tweaks, mapping updates, individual value changes.

```json
{
  "tool": "edit_parameter",
  "arguments": {
    "slot_index": 0,
    "parameter": "Cutoff Frequency",
    "value": 0.65,
    "mapping": {
      "cv": {
        "source": 1,
        "cv_input": 3,
        "is_unipolar": false,
        "is_gate": false,
        "volts": 100,
        "delta": 50
      }
    }
  }
}
```

---

### Preset Management Tools

#### new

Create a new blank preset or preset with initial algorithms. WARNING: Clears current preset.

**Parameters**:
- `name` (required, string): Name for the new preset
- `algorithms` (optional, array): Array of `{name: string}` or `{guid: string}` to add

```json
{"tool": "new", "arguments": {"name": "My Preset"}}
```

```json
{
  "tool": "new",
  "arguments": {
    "name": "Audio Chain",
    "algorithms": [
      {"name": "Low-Pass Filter"},
      {"name": "Delay"},
      {"name": "Reverb"}
    ]
  }
}
```

---

#### save

Save the current preset to the device.

**Parameters**: None

```json
{"tool": "save", "arguments": {}}
```

---

#### add

Add an algorithm to the preset. Inserts without replacing existing algorithms.

**Parameters**:
- `target` (required): Must be "algorithm"
- `name` (optional, string): Algorithm name (fuzzy matching)
- `guid` (optional, string): Algorithm GUID (exact match)
- `slot_index` (optional, integer): Target slot (0-31). Omit for first empty slot.

```json
{"tool": "add", "arguments": {"target": "algorithm", "name": "Dual VCO"}}
```

```json
{"tool": "add", "arguments": {"target": "algorithm", "slot_index": 3, "guid": "vcod"}}
```

---

#### remove

Remove the algorithm from a slot, leaving it empty.

**Parameters**:
- `target` (required): Must be "slot"
- `slot_index` (required, integer): Slot index to clear (0-31)

```json
{"tool": "remove", "arguments": {"target": "slot", "slot_index": 3}}
```

---

## Workflow Examples

### Workflow 1: Creating a Simple Preset

1. Create preset with algorithms:
```json
{"tool": "new", "arguments": {"name": "Simple Audio Chain", "algorithms": [{"name": "Low-Pass Filter"}, {"name": "Reverb"}]}}
```

2. Verify state:
```json
{"tool": "show_preset", "arguments": {}}
```

---

### Workflow 2: Modifying a Parameter with MIDI Control

1. View current parameter:
```json
{"tool": "show_parameter", "arguments": {"slot_index": 0, "parameter": 2}}
```

2. Update parameter with MIDI mapping:
```json
{
  "tool": "edit_parameter",
  "arguments": {
    "slot_index": 0,
    "parameter": "Cutoff",
    "value": 0.65,
    "mapping": {
      "midi": {
        "is_midi_enabled": true,
        "midi_channel": 0,
        "midi_type": "cc",
        "midi_cc": 74
      }
    }
  }
}
```

3. Verify mapping:
```json
{"tool": "show_parameter", "arguments": {"slot_index": 0, "parameter": 2}}
```

---

### Workflow 3: Exploring Algorithms

1. Search:
```json
{"tool": "search_algorithms", "arguments": {"query": "Delay"}}
```

2. Add to preset:
```json
{"tool": "add", "arguments": {"target": "algorithm", "name": "Ping Pong Delay"}}
```

---

### Workflow 4: Performance Page Organization

1. Assign parameters to performance pages:
```json
{"tool": "edit_parameter", "arguments": {"slot_index": 0, "parameter": "Cutoff Frequency", "mapping": {"performance_page": 1}}}
```

```json
{"tool": "edit_parameter", "arguments": {"slot_index": 0, "parameter": "Resonance", "mapping": {"performance_page": 1}}}
```

```json
{"tool": "edit_parameter", "arguments": {"slot_index": 1, "parameter": "Level", "mapping": {"performance_page": 2}}}
```

2. Verify:
```json
{"tool": "show_preset", "arguments": {}}
```

---

## Mapping Reference

### CV Mapping

For hardware control voltage integration and internal modulation.

Fields:
- `source`: Output index from another algorithm (0=not used)
- `cv_input`: Physical input (0=disabled, 1-12=inputs)
- `is_unipolar`: True for 0-10V, false for +/-5V
- `is_gate`: Gate/trigger mode
- `volts`: Scaling factor (0-127)
- `delta`: Sensitivity/responsiveness

```json
{"mapping": {"cv": {"source": 1, "cv_input": 3, "is_unipolar": false, "is_gate": false, "volts": 100, "delta": 50}}}
```

### MIDI Mapping

For MIDI controller and DAW integration.

Fields:
- `is_midi_enabled`: Boolean (required!)
- `midi_channel`: 0-15 (where 0=MIDI Channel 1, 15=MIDI Channel 16)
- `midi_type`: "cc", "note_momentary", "note_toggle", "cc_14bit_low", "cc_14bit_high"
- `midi_cc`: CC number (0-127) or 128 for aftertouch
- `is_midi_symmetric`: Symmetric scaling around center
- `is_midi_relative`: Incremental changes
- `midi_min`/`midi_max`: Scaling range

```json
{"mapping": {"midi": {"is_midi_enabled": true, "midi_channel": 0, "midi_type": "cc", "midi_cc": 74, "midi_min": 0, "midi_max": 127}}}
```

### i2c Mapping

For external i2c control modules.

Fields:
- `is_i2c_enabled`: Boolean
- `i2c_cc`: CC number (0-255)
- `is_i2c_symmetric`: Symmetric scaling
- `i2c_min`/`i2c_max`: Scaling range

```json
{"mapping": {"i2c": {"is_i2c_enabled": true, "i2c_cc": 50, "i2c_min": 0, "i2c_max": 127}}}
```

### Performance Page

Assign parameters to hardware performance pages (1-15, 0=not assigned).

```json
{"mapping": {"performance_page": 1}}
```

---

## Troubleshooting

### Common Mistakes

1. **Using camelCase instead of snake_case**
   - Wrong: `{"midiChannel": 0}`
   - Right: `{"midi_channel": 0}`

2. **Missing is_midi_enabled flag**
   - Wrong: `{"mapping": {"midi": {"midi_cc": 74}}}`
   - Right: `{"mapping": {"midi": {"is_midi_enabled": true, "midi_cc": 74}}}`

3. **Wrong MIDI channel numbering** (0-indexed)
   - MIDI Channel 1 = `"midi_channel": 0`
   - MIDI Channel 16 = `"midi_channel": 15`

4. **Confusing cv_input with source**
   - `source`: Output index from another algorithm
   - `cv_input`: Physical hardware input (1-12)

5. **Forgetting nested structure for mappings**
   - Wrong: `{"mapping": {"is_midi_enabled": true}}`
   - Right: `{"mapping": {"midi": {"is_midi_enabled": true}}}`

### Ambiguous Parameter Names

Multi-channel algorithms may have duplicate parameter names. Use parameter number instead of name:

```json
{"tool": "edit_parameter", "arguments": {"slot_index": 0, "parameter": 4, "value": 3}}
```

The `show_slot` and `show_parameter` tools always return both `parameter_name` and `parameter_number`.

---

## Specifications and Multi-Channel Algorithms

Some algorithms support **specifications** that modify their behavior (e.g., channel count). When creating with `new` or `edit_slot`, include specifications in the algorithm object:

```json
{"algorithm": {"name": "Clock Divider", "specifications": [2]}}
```

The `show_slot` response includes specifications in the algorithm data so you can see how an algorithm was instantiated.

---

## Related Documentation

- **[MCP Mapping Guide](./mcp-mapping-guide.md)**: Complete mapping field documentation
- **[Architecture Document](./architecture.md)**: MCP server implementation details

---

## Migration from Previous API

| Previous Tool | New Tool |
|--------------|----------|
| `search` target="algorithm" | `search_algorithms` |
| `search` target="parameter" | `search_parameters` |
| `show` target="preset" | `show_preset` |
| `show` target="slot" | `show_slot` |
| `show` target="parameter" | `show_parameter` |
| `show` target="screen" | `show_screen` |
| `show` target="routing" | `show_routing` |
| `show` target="cpu" | `show_cpu` |
| `edit` target="preset" | `edit_preset` |
| `edit` target="slot" | `edit_slot` |
| `edit` target="parameter" | `edit_parameter` |
| `new` | `new` (unchanged) |
| `save` | `save` (unchanged) |
| `add` | `add` (unchanged) |
| `remove` | `remove` (unchanged) |

---

**Last Updated**: 2026-02-16
**MCP Library**: mcp_dart 1.2.2
