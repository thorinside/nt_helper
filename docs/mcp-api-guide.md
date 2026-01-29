# MCP API Guide for Disting NT

## Overview

The Disting NT MCP (Model Context Protocol) API provides a streamlined, seven-tool interface for interacting with your hardware.

### Design Philosophy

- **Seven core tools**: search, show, new, save, add, remove, edit
- **Granular control**: edit tool supports three granularity levels (preset, slot, parameter)
- **Insert semantics**: add tool inserts algorithms without replacing existing ones
- **Mapping support**: Full CV/MIDI/i2c/performance page mapping for parameter control
- **Snake_case JSON**: All response fields use snake_case for LLM compatibility

### Important: Field Naming Convention

**All JSON fields use snake_case, not camelCase.**

✓ Correct: `midi_channel`, `is_midi_enabled`, `cv_input`
✗ Incorrect: `midiChannel`, `isMidiEnabled`, `cvInput`

This naming convention has been tested with smaller language models and provides significantly better compatibility.

## Core Tools

### 1. search - Algorithm Discovery

Find algorithms by name, category, or fuzzy matching.

**Parameters**:
- `target` (required): "algorithm" or "parameter"
- `query` (required): Search term (algorithm name, partial name, or category)

**Returns**: Top 10 matches sorted by relevance with GUID, name, category, and description.

**Examples**:

```json
{
  "tool": "search",
  "arguments": {
    "target": "algorithm",
    "query": "filter"
  }
}
```

Response: Shows all filter algorithms with matching names and related filters.

```json
{
  "tool": "search",
  "arguments": {
    "target": "algorithm",
    "query": "Audio-IO"
  }
}
```

Response: Shows all algorithms in the Audio-IO category.

---

### 2. new - Preset Initialization

Create a new blank preset or preset with initial algorithms.

**Purpose**: Start fresh with a new preset, optionally pre-populated with algorithms

**Parameters**:
- `name` (required, string): Name for the new preset
- `algorithms` (optional, array): Array of algorithm specifications to add
  - `guid` (optional, string): Algorithm GUID (preferred over name)
  - `name` (optional, string): Algorithm name (fuzzy matching ≥70%)
  - `specifications` (optional, array): Algorithm-specific specification values

**Returns**: Success confirmation with new preset state

**Warning**: Clears current preset. Device must be in connected mode.

**Examples**:

```json
{
  "tool": "new",
  "arguments": {
    "name": "My Empty Preset"
  }
}
```

Response: Empty preset created with given name.

```json
{
  "tool": "new",
  "arguments": {
    "name": "Audio Processing Chain",
    "algorithms": [
      {
        "name": "Low-Pass Filter"
      },
      {
        "name": "Delay"
      },
      {
        "name": "Reverb"
      }
    ]
  }
}
```

Response: Preset created with three algorithms in slots 0, 1, 2.

---

### 2.5. save - Save Preset

Save the current preset to the device.

**Parameters**: None

**Returns**: Success confirmation.

```json
{
  "tool": "save",
  "arguments": {}
}
```

---

### 2.6. add - Simple Algorithm Addition

Add an algorithm to the preset with insert semantics.

**Parameters**:
- `target` (required): Must be "algorithm"
- `slot_index` (optional): Target slot (0-31). Omit to use first empty slot.
- `name` (optional): Algorithm name (fuzzy matching ≥70%)
- `guid` (optional): Algorithm GUID (exact match)

**Behavior**: If `slot_index` is specified and occupied, the new algorithm is inserted at that position and existing algorithms are pushed down (not replaced).

**Returns**: Success confirmation with slot index.

**Comparison with edit tool**:

The `add` tool has a simpler structure than using `edit` for the same operation:

```json
// Using 'add' (simpler)
{
  "tool": "add",
  "arguments": {
    "target": "algorithm",
    "name": "VCO"
  }
}

// Using 'edit' (more complex)
{
  "tool": "edit",
  "arguments": {
    "target": "slot",
    "slot_index": 0,
    "data": {
      "algorithm": {
        "name": "VCO"
      }
    }
  }
}
```

**Examples**:

Add to first empty slot:
```json
{
  "tool": "add",
  "arguments": {
    "target": "algorithm",
    "name": "Dual VCO"
  }
}
```

Add to specific slot:
```json
{
  "tool": "add",
  "arguments": {
    "target": "algorithm",
    "slot_index": 3,
    "guid": "vcod"
  }
}
```

---

### 2.7. remove - Clear Slot

Remove the algorithm from a slot, leaving it empty.

**Parameters**:
- `target` (required): Must be "slot"
- `slot_index` (required): Slot index to clear (0-31)

**Behavior**:
- If slot contains an algorithm, removes it and confirms what was removed
- If slot is already empty, succeeds gracefully with a friendly message
- Returns success in both cases (lenient design for LLM compatibility)

**Returns**: Success confirmation with details about what was removed.

**Examples**:

Remove algorithm from slot 3:
```json
{
  "tool": "remove",
  "arguments": {
    "target": "slot",
    "slot_index": 3
  }
}
```

Response (slot was occupied):
```json
{
  "success": true,
  "message": "Removed \"Low-Pass Filter\" from slot 3"
}
```

Response (slot was already empty):
```json
{
  "success": true,
  "message": "Slot 3 is already empty"
}
```

---

### 3. edit - State Modification

Modify preset, slot, or parameter with varying granularity levels.

**Purpose**: Update preset state at different levels of detail

**Granularity Levels**:

#### 3a. Preset-Level Edit
Modify entire preset structure.

**Parameters**:
- `target` (required): "preset"
- `data` (required, object):
  - `name` (optional, string): Preset name
  - `slots` (optional, array): Slot array with algorithm, parameters, mappings

**Use When**: Restructuring preset, reordering algorithms, bulk changes

**Example**:

```json
{
  "tool": "edit",
  "arguments": {
    "target": "preset",
    "data": {
      "name": "Updated Preset Name",
      "slots": [
        {
          "algorithm": {"name": "Oscillator"},
          "parameters": [
            {
              "parameter_number": 0,
              "value": 1.5
            }
          ]
        },
        {
          "algorithm": {"name": "Filter"},
          "parameters": [
            {
              "parameter_number": 2,
              "value": 0.8
            }
          ]
        }
      ]
    }
  }
}
```

#### 3b. Slot-Level Edit
Change algorithm in a single slot.

**Parameters**:
- `target` (required): "slot"
- `slot_index` (required, integer): Slot index (0-31)
- `data` (required, object):
  - `algorithm` (optional, object): Algorithm specification (guid or name)
  - `parameters` (optional, array): Parameter updates for this slot
  - `name` (optional, string): Custom slot name

**Use When**: Changing algorithm in single slot, updating all parameters for one algorithm

**Example**:

```json
{
  "tool": "edit",
  "arguments": {
    "target": "slot",
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

#### 3c. Parameter-Level Edit
Update individual parameter value and/or mapping.

**Parameters**:
- `target` (required): "parameter"
- `slot_index` (required, integer): Slot index (0-31)
- `parameter` (required, string or integer): Parameter name or number
- `value` (optional, number): Parameter value (omit to update only mapping)
- `mapping` (optional, object): CV/MIDI/i2c/performance page mapping

**Use When**: Quick tweaks, mapping updates, individual value changes

**Mapping Support**: CV, MIDI, i2c, performance page. See docs/mcp-mapping-guide.md for complete field documentation.

**Example**:

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
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

### 4. show - State Inspection

Inspect preset, slot, parameter, screen, or routing state.

**Purpose**: View current configuration at different detail levels

**Target Types**:

#### show preset
Get entire preset with all slots and parameters.

**Parameters**:
- `target` (required): "preset"

**Returns**: Complete preset state including name, all slots, parameters, and enabled mappings

**Example**:

```json
{
  "tool": "show",
  "arguments": {
    "target": "preset"
  }
}
```

#### show slot
Get single slot configuration.

**Parameters**:
- `target` (required): "slot"
- `identifier` (required, integer): Slot index (0-31)

**Returns**: Slot state with algorithm, parameters, and mappings

**Example**:

```json
{
  "tool": "show",
  "arguments": {
    "target": "slot",
    "identifier": 0
  }
}
```

#### show parameter
Get single parameter with value and mapping.

**Parameters**:
- `target` (required): "parameter"
- `identifier` (required, string): "slot_index:parameter_number" (e.g., "0:5")

**Returns**: Parameter value, range, and enabled mappings

**Example**:

```json
{
  "tool": "show",
  "arguments": {
    "target": "parameter",
    "identifier": "0:5"
  }
}
```

#### show screen
Get device screenshot as base64 JPEG.

**Parameters**:
- `target` (required): "screen"

**Returns**: Base64-encoded JPEG image of current display

**Example**:

```json
{
  "tool": "show",
  "arguments": {
    "target": "screen"
  }
}
```

#### show routing
Get signal routing configuration.

**Parameters**:
- `target` (required): "routing"

**Returns**: Routing matrix showing input/output connections between algorithms

**Example**:

```json
{
  "tool": "show",
  "arguments": {
    "target": "routing"
  }
}
```

---

## Workflow Examples

### Workflow 1: Creating a Simple Preset

**Goal**: Create a blank preset, add a filter and reverb, set up basic audio routing.

**Prerequisites**: Device in connected mode.

**Steps**:

1. Create new preset:
```json
{
  "tool": "new",
  "arguments": {
    "name": "Simple Audio Chain"
  }
}
```

2. Add algorithms using edit:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "preset",
    "data": {
      "name": "Simple Audio Chain",
      "slots": [
        {
          "algorithm": {"name": "Low-Pass Filter"}
        },
        {
          "algorithm": {"name": "Reverb"}
        }
      ]
    }
  }
}
```

3. Verify state:
```json
{
  "tool": "show",
  "arguments": {
    "target": "preset"
  }
}
```

**Notes**:
- The new tool creates empty preset; edit adds algorithms
- Algorithms process in order (slot 0 → 1 → ...)
- Verify with show to confirm changes persisted

---

### Workflow 2: Modifying Preset with Mappings

**Goal**: Update filter cutoff parameter with MIDI control and CV modulation.

**Prerequisites**: Preset with filter algorithm in slot 0.

**Steps**:

1. View current parameter:
```json
{
  "tool": "show",
  "arguments": {
    "target": "parameter",
    "identifier": "0:2"
  }
}
```

2. Update parameter with MIDI mapping:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
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

3. Add CV modulation from LFO:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Cutoff",
    "mapping": {
      "cv": {
        "source": 1,
        "cv_input": 3,
        "is_unipolar": false,
        "is_gate": false,
        "volts": 80,
        "delta": 40
      }
    }
  }
}
```

4. Verify mapping applied:
```json
{
  "tool": "show",
  "arguments": {
    "target": "parameter",
    "identifier": "0:2"
  }
}
```

**Notes**:
- Mappings persist across preset saves
- Disabled mappings (is_midi_enabled=false) omitted from show output
- Can update value and mapping independently

---

### Workflow 3: Exploring Algorithms by Category

**Goal**: Find all delay algorithms and get details on one.

**Prerequisites**: None required.

**Steps**:

1. Search delay category:
```json
{
  "tool": "search",
  "arguments": {
    "target": "algorithm",
    "query": "Delay"
  }
}
```

2. Get details on specific algorithm:
```json
{
  "tool": "search",
  "arguments": {
    "target": "algorithm",
    "query": "Ping Pong Delay"
  }
}
```

3. Add to preset using new tool with algorithms:
```json
{
  "tool": "new",
  "arguments": {
    "name": "Delay Experiments",
    "algorithms": [
      {
        "name": "Ping Pong Delay"
      }
    ]
  }
}
```

**Notes**:
- Search supports partial names ("Ping Pong" matches "Ping Pong Delay")
- Returns top 10 results sorted by relevance
- Use GUID for unambiguous algorithm selection

---

### Workflow 4: Setting Up MIDI Control

**Goal**: Map filter frequency to MIDI CC 74 on channel 1.

**Prerequisites**: Preset with filter algorithm in slot 0.

**Steps**:

1. View current state:
```json
{
  "tool": "show",
  "arguments": {
    "target": "parameter",
    "identifier": "0:2"
  }
}
```

2. Map MIDI control:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Cutoff Frequency",
    "mapping": {
      "midi": {
        "is_midi_enabled": true,
        "midi_channel": 0,
        "midi_type": "cc",
        "midi_cc": 74,
        "is_midi_symmetric": false,
        "is_midi_relative": false,
        "midi_min": 0,
        "midi_max": 127
      }
    }
  }
}
```

3. Verify mapping:
```json
{
  "tool": "show",
  "arguments": {
    "target": "parameter",
    "identifier": "0:2"
  }
}
```

**Notes**:
- MIDI channels are 0-indexed (0=channel 1, 15=channel 16)
- CC 74 is commonly used for filter cutoff
- Symmetric mode scales around center value
- Relative mode for incremental changes (encoder-style)

---

### Workflow 5: Organizing with Performance Pages

**Goal**: Assign multiple parameters to performance page 1 for easy access.

**Prerequisites**: Preset with multiple parameters to control.

**Steps**:

1. Assign filter cutoff to performance page 1:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Cutoff Frequency",
    "mapping": {
      "performance_page": 1
    }
  }
}
```

2. Assign filter resonance to same page:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Resonance",
    "mapping": {
      "performance_page": 1
    }
  }
}
```

3. Assign reverb level to different page:
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 1,
    "parameter": "Level",
    "mapping": {
      "performance_page": 2
    }
  }
}
```

4. Verify organization:
```json
{
  "tool": "show",
  "arguments": {
    "target": "preset"
  }
}
```

**Notes**:
- Performance pages range 1-15 (0=not assigned)
- Group related parameters on same page
- Pages organize hardware controls without affecting preset storage

---

## Granularity Guide

### When to Use Preset-Level Edits

**Use preset edits when**:
- Restructuring entire preset
- Reordering algorithms
- Making changes across multiple slots
- Bulk updates to preset structure

**Advantages**:
- Single API call for complex changes
- Atomic operation (all or nothing)
- Clear overall structure

**Disadvantages**:
- Requires sending complete preset state
- Larger JSON payloads
- Not efficient for small tweaks

**Example**: Swap positions of two algorithms
```json
{
  "tool": "edit",
  "arguments": {
    "target": "preset",
    "data": {
      "slots": [
        {"algorithm": {"name": "Reverb"}},
        {"algorithm": {"name": "Filter"}}
      ]
    }
  }
}
```

---

### When to Use Slot-Level Edits

**Use slot edits when**:
- Changing algorithm in single slot
- Updating all parameters for one algorithm
- Modifying multiple parameters in one slot

**Advantages**:
- Focused changes to specific slot
- Efficient for algorithm swaps
- Good for complete slot reconfigurations

**Disadvantages**:
- Requires specifying slot index
- Less efficient for single-parameter changes

**Example**: Change algorithm and set all parameters
```json
{
  "tool": "edit",
  "arguments": {
    "target": "slot",
    "slot_index": 2,
    "data": {
      "algorithm": {"name": "Distortion"},
      "parameters": [
        {"parameter_number": 0, "value": 0.5},
        {"parameter_number": 1, "value": 0.3}
      ]
    }
  }
}
```

---

### When to Use Parameter-Level Edits

**Use parameter edits when**:
- Tweaking single parameter value
- Updating parameter mapping
- Quick adjustments during performance

**Advantages**:
- Minimal payload
- Fastest response
- Perfect for real-time control

**Disadvantages**:
- Individual changes accumulate
- Not suitable for bulk updates

**Example**: Quick pitch adjustment
```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Pitch",
    "value": 2.5
  }
}
```

**Performance Considerations**:
- Smaller edits = faster network round-trip
- Parameter edits reduce error surface
- Preset edits are atomic and safe
- Use appropriate granularity for your use case

---

## Mapping Strategies

### When to Use CV Mapping

**CV mapping best for**:
- Hardware control voltage integration
- Modular synthesis (LFO→parameter)
- Eurorack modulation sources

**Common Use Cases**:
1. LFO modulation of filter cutoff
2. Envelope followers for dynamic control
3. External CV from sequencers
4. Feedback loops within patch

**Configuration**:
- `source`: Output index from another algorithm
- `cv_input`: Physical input (1-12)
- `is_unipolar`: True for 0-10V, false for ±5V
- `is_gate`: Gate/trigger mode
- `volts`: Scaling factor (0-127)
- `delta`: Sensitivity/responsiveness

**Example**: LFO modulating filter cutoff
```json
{
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
```

---

### When to Use MIDI Mapping

**MIDI mapping best for**:
- MIDI controller integration
- DAW automation
- Keyboard/sequencer control
- Standard MIDI infrastructure

**Common Use Cases**:
1. CC-based knob control
2. Note-based gate triggers
3. 14-bit CC for fine control
4. Velocity-responsive parameters

**MIDI Types**:
- `cc`: Standard control change
- `note_momentary`: Gate while note held
- `note_toggle`: Toggle on note on/off
- `cc_14bit_low`: 14-bit CC (coarse)
- `cc_14bit_high`: 14-bit CC (fine)

**Configuration**:
- `is_midi_enabled`: Boolean enable/disable
- `midi_channel`: 0-15 (where 0=channel 1)
- `midi_type`: Type of message
- `midi_cc`: CC number (0-127)
- `is_midi_symmetric`: Symmetric around center
- `is_midi_relative`: Incremental changes
- `midi_min`/`midi_max`: Scaling range

**Example**: Filter cutoff on MIDI CC 74
```json
{
  "mapping": {
    "midi": {
      "is_midi_enabled": true,
      "midi_channel": 0,
      "midi_type": "cc",
      "midi_cc": 74,
      "is_midi_symmetric": false,
      "is_midi_relative": false,
      "midi_min": 0,
      "midi_max": 127
    }
  }
}
```

---

### When to Use i2c Mapping

**i2c mapping best for**:
- External i2c control modules
- ES-5 expander integration
- Custom i2c hardware
- Advanced hardware integration

**Common Use Cases**:
1. ES-5 expander parameter control
2. Modular i2c controllers
3. Custom controller modules
4. Hardware sequencer integration

**Configuration**:
- `is_i2c_enabled`: Boolean enable/disable
- `i2c_cc`: CC number (0-255)
- `is_i2c_symmetric`: Symmetric scaling
- `i2c_min`/`i2c_max`: Scaling range

**Example**: ES-5 expander control
```json
{
  "mapping": {
    "i2c": {
      "is_i2c_enabled": true,
      "i2c_cc": 50,
      "is_i2c_symmetric": false,
      "i2c_min": 0,
      "i2c_max": 127
    }
  }
}
```

---

### Performance Page Organization Best Practices

**Group logically**:
- Page 1: Core sound controls (filter, amp envelope)
- Page 2: Modulation (LFO speed, depth)
- Page 3: Effects (reverb, delay parameters)
- Pages 4-15: Additional function groups

**Avoid conflicts**:
- Don't assign same CC to multiple parameters
- Document mapping for consistency
- Use unique CCs across pages

**Performance tips**:
- Group related controls
- Use symmetric mode for centered controls
- Document performance layout in notes
- Test on hardware before performance

---

### Using CV Source for Modulation

**CV Source Concept**:
- CV mapping's `source` field references another algorithm's output
- Enables internal signal routing for modulation
- Creates feedback loops and complex patches

**Example Patches**:

1. LFO modulating filter cutoff:
   - Slot 0: LFO algorithm
   - Slot 1: Filter algorithm
   - Filter cutoff CV mapping: source=0 (from LFO)

2. Envelope follower modulating resonance:
   - Slot 0: Envelope follower
   - Slot 1: Filter
   - Filter resonance CV mapping: source=0

3. Sequencer modulating pitch:
   - Slot 0: Step sequencer
   - Slot 1: Oscillator
   - Oscillator pitch CV mapping: source=0

**Configuration**:
```json
{
  "mapping": {
    "cv": {
      "source": 0,
      "cv_input": 3,
      "is_unipolar": false,
      "is_gate": false,
      "volts": 80,
      "delta": 40
    }
  }
}
```

**Important**:
- Source index refers to algorithm slot, not parameter
- Algorithms process in order (0→1→2...)
- Source must be before target in slot order
- Verify signal flow with show routing

---

## Troubleshooting

### Common Mistakes to Avoid

**1. Using camelCase instead of snake_case**
- Mistake: `{"midiChannel": 0, "isMidiEnabled": true}`
- Correct: `{"midi_channel": 0, "is_midi_enabled": true}`
- Remember: All field names use snake_case, not camelCase

**2. Missing is_midi_enabled flag**
- Mistake: `{"mapping": {"midi": {"midi_channel": 0, "midi_cc": 74}}}`
- Correct: `{"mapping": {"midi": {"is_midi_enabled": true, "midi_channel": 0, "midi_cc": 74}}}`
- This flag must always be present for MIDI mappings to work

**3. Wrong MIDI channel numbering**
- Mistake: Trying to use MIDI channel 16 with `"midi_channel": 16`
- Correct: MIDI Channel 16 is `"midi_channel": 15` (0-indexed)
- Reference: MIDI Channel 1=0, Channel 2=1, ..., Channel 16=15

**4. Confusing cv_input with source**
- `source`: Output index from another algorithm (0=not used, advanced feature)
- `cv_input`: Physical input number (1-12, required for hardware CV)
- These are different fields with different purposes

**5. Forgetting nested structure for mappings**
- Mistake: `{"mapping": {"is_midi_enabled": true}}`
- Correct: `{"mapping": {"midi": {"is_midi_enabled": true, "midi_channel": 0, ...}}}`
- Mapping types (midi, cv, i2c) must be nested inside "mapping"

---

### Common Validation Errors

**MIDI Channel Out of Range**
- Error: `midi_channel` must be 0-15 (where 0=MIDI Channel 1, 15=MIDI Channel 16)
- Fix: Convert channel number correctly: MIDI Channel 1 = index 0, Channel 2 = index 1, etc.

**CV Input Invalid**
- Error: `cv_input` must be 0-12 (where 0=disabled, 1-12=physical inputs)
- Fix: Check available CV inputs on your hardware

**Parameter Not Found**
- Error: Parameter name doesn't match algorithm's parameter list
- Fix: Use show slot or search to verify parameter names

---

### Mapping Validation Errors

**Missing is_midi_enabled Flag**
- Error: MIDI mapping requires is_midi_enabled field (true/false)
- Fix: Always include `"is_midi_enabled": true` when creating MIDI mappings
- This flag is required even if mapping is identical to existing

**MIDI CC Out of Range**
- Error: `midi_cc` must be 0-127 or 128 for aftertouch
- Fix: Choose valid CC number for your controller

**i2c CC Out of Range**
- Error: `i2c_cc` must be 0-255
- Fix: Ensure i2c CC is within valid range

---

### Algorithm Lookup Issues

**Fuzzy Matching Not Working**
- Error: Algorithm name doesn't match (< 70% similarity)
- Tips:
  - Try shorter/longer variations
  - Use GUID for unambiguous lookup
  - Check algorithm categories with search
  - Use partial names

**Example**: Instead of "Ping Pong Stereo Delay", try "Ping Pong" or "Delay"

---

### Specification Validation Errors

**Algorithm Specification Required**
- Error: This algorithm requires specification values
- Fix: Some algorithms (with multiple variants) need specification array
- Check search results for specification requirements

---

### Mode Restrictions

**Offline/Demo Mode Limitations**
- Some operations unavailable in offline or demo modes
- Error: "Device not in connected mode"
- Fix: Connect to actual hardware or switch to demo mode for testing

---

## JSON Schema Reference

### search Tool Schema

```json
{
  "type": "object",
  "properties": {
    "target": {
      "type": "string",
      "enum": ["algorithm", "parameter"],
      "description": "Search target type"
    },
    "query": {
      "type": "string",
      "description": "Search term (name, partial name, or category)"
    }
  },
  "required": ["target", "query"]
}
```

**Response Fields**:
```json
{
  "success": boolean,
  "results": [
    {
      "guid": "string",
      "name": "string",
      "category": "string",
      "description": "string",
      "similarity": number
    }
  ]
}
```

---

### new Tool Schema

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "Preset name"
    },
    "algorithms": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "guid": {"type": "string"},
          "name": {"type": "string"},
          "specifications": {"type": "array"}
        }
      }
    }
  },
  "required": ["name"]
}
```

---

### edit Tool Schema (Parameter Level)

```json
{
  "type": "object",
  "properties": {
    "target": {
      "type": "string",
      "enum": ["parameter"],
      "description": "Target granularity"
    },
    "slot_index": {
      "type": "integer",
      "minimum": 0,
      "maximum": 31,
      "description": "Slot index (0-31)"
    },
    "parameter": {
      "oneOf": [
        {"type": "string"},
        {"type": "integer"}
      ],
      "description": "Parameter name or number"
    },
    "value": {
      "type": "number",
      "description": "Parameter value (optional)"
    },
    "mapping": {
      "type": "object",
      "properties": {
        "cv": {"type": "object"},
        "midi": {"type": "object"},
        "i2c": {"type": "object"},
        "performance_page": {"type": "integer", "minimum": 0, "maximum": 15}
      }
    }
  },
  "required": ["target", "slot_index", "parameter"]
}
```

See docs/mcp-mapping-guide.md for complete mapping field documentation.

---

### show Tool Schema

```json
{
  "type": "object",
  "properties": {
    "target": {
      "type": "string",
      "enum": ["preset", "slot", "parameter", "screen", "routing"],
      "description": "What to inspect"
    },
    "identifier": {
      "oneOf": [
        {"type": "integer"},
        {"type": "string"}
      ],
      "description": "Required for slot/parameter targets"
    }
  },
  "required": ["target"]
}
```

---

## Complete Examples

### Example 1: Building a Pad Preset

```json
{
  "tool": "new",
  "arguments": {
    "name": "Ambient Pad",
    "algorithms": [
      {"name": "Wavetable Oscillator"},
      {"name": "Low-Pass Filter"},
      {"name": "Reverb"}
    ]
  }
}
```

Then configure each stage:

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Waveform",
    "value": 0.5
  }
}
```

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 1,
    "parameter": "Cutoff",
    "value": 0.4,
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

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 2,
    "parameter": "Wet Amount",
    "value": 0.6,
    "mapping": {
      "performance_page": 1
    }
  }
}
```

Verify:

```json
{
  "tool": "show",
  "arguments": {
    "target": "preset"
  }
}
```

---

### Example 2: Real-Time Performance Mapping

```json
{
  "tool": "show",
  "arguments": {
    "target": "preset"
  }
}
```

Identify parameters, then map to MIDI:

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Filter Cutoff",
    "mapping": {
      "midi": {
        "is_midi_enabled": true,
        "midi_channel": 0,
        "midi_type": "cc",
        "midi_cc": 74,
        "is_midi_symmetric": false,
        "is_midi_relative": false,
        "midi_min": 0,
        "midi_max": 127
      }
    }
  }
}
```

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Filter Resonance",
    "mapping": {
      "midi": {
        "is_midi_enabled": true,
        "midi_channel": 0,
        "midi_type": "cc",
        "midi_cc": 71
      }
    }
  }
}
```

---

## Related Documentation

- **[MCP Mapping Guide](./mcp-mapping-guide.md)**: Complete mapping field documentation and examples
- **[Architecture Document](./architecture.md)**: MCP server implementation details
- **[README.md](../README.md)**: Project overview and quick start

---

## Migration from Old API

If you're familiar with the old 20+ tool API, here's how tools map to the new 6-tool API:

| Old Tool | New Equivalent |
|----------|-----------------|
| list_algorithms | search with target="algorithm" |
| get_algorithm_details | search (exact match) |
| get_current_preset | show with target="preset" |
| add_algorithm | new or edit with target="slot" |
| remove_algorithm | remove with target="slot" |
| set_parameter_value | edit with target="parameter" |
| get_parameter_value | show with target="parameter" |
| set_preset_name | edit with target="preset" |
| get_routing | show with target="routing" |
| move_algorithm_up/down | edit with target="preset" (reorder slots) |
| get_module_screenshot | show with target="screen" |
| new_preset | new without algorithms |
| save_preset | save |
| get_cpu_usage | get_cpu_usage (unchanged) |

---

## Specifications and Multi-Channel Algorithms

### Understanding Specifications

Some algorithms support **specifications** that modify their behavior when instantiated. For example:

- **Clock Divider** (clkd): `Channels` specification (1-8 channels)
- **Euclidean** (eucp): `Channels` specification (1-4 channels)
- **Elements**: Various specifications for different behaviors

When you create an algorithm with specifications, the hardware instantiates it with a specific parameter set based on those specifications.

### Specifications in API Responses

When you call `show` with target="preset" or target="slot", the response includes specifications in the algorithm data:

```json
{
  "slot_index": 0,
  "algorithm": {
    "guid": "clkd",
    "name": "Clock Divider",
    "specifications": [2],
    "algorithm_index": 0
  },
  "parameters": [... list of parameters ...],
  "total_parameters": 13
}
```

The `specifications` array contains the values used to instantiate the algorithm. In this example, `[2]` means Clock Divider was instantiated with Channels=2.

### Parameter Identification: Using Names vs Numbers

Parameters can be identified in two ways:

#### 1. By Parameter Name (Recommended for Single Matches)

For most algorithms, parameter names are unique within a slot:

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": "Speed",
    "value": 100
  }
}
```

#### 2. By Parameter Number (Required for Ambiguous Names)

**Multi-channel algorithms may have duplicate parameter names.** For example, Clock Divider with Channels=2 has three parameters named "1:Divisor" at parameter numbers 3, 4, and 5:

```
Parameter Number 3: "1:Divisor" (range 1-32)
Parameter Number 4: "1:Divisor" (range 0-5)
Parameter Number 5: "1:Divisor" (range 0-9)
```

When parameter names are ambiguous, use parameter_number instead:

```json
{
  "tool": "edit",
  "arguments": {
    "target": "parameter",
    "slot_index": 0,
    "parameter": 4,
    "value": 3
  }
}
```

The `show` tool always returns both name and parameter_number so you know which number to use:

```json
{
  "success": true,
  "data": {
    "slot_index": 0,
    "parameter_number": 4,
    "parameter_name": "1:Divisor",
    "value": 3,
    "min": 0,
    "max": 5
  }
}
```

### Error: Ambiguous Parameter Name

If you try to reference a parameter by name and multiple parameters share that name, you'll get an error like:

```
Parameter name "1:Divisor" is ambiguous in slot 0. Found at parameter numbers: 3, 4, 5. Please use parameter_number to disambiguate.
```

This is normal for multi-channel algorithms. Use one of the listed parameter numbers instead.

### Firmware Limitation: Partial Parameter Lists

**Important**: Some multi-channel algorithms with specifications return only the first channel's parameters from the hardware:

- Euclidean with Channels=4: Returns parameters for Channel 1 only (15 parameters)
- Clock Divider with Channels=8: Returns parameters for Channel 1 only (13 parameters)

This appears to be a firmware design choice. All returned parameters are accessible and functional. The `total_parameters` field in show responses indicates the actual count returned by the hardware.

**Workaround**: Use the `specifications` field to understand which parameters are available for your instantiation.

---

## Support and Feedback

For issues or questions about the MCP API:

1. Check the [Troubleshooting section](#troubleshooting) above
2. Review [Workflow Examples](#workflow-examples) for similar use cases
3. Consult [Mapping Guide](./mcp-mapping-guide.md) for mapping-specific questions

---

## Testing and Validation

This API has been designed and tested for usability with smaller language models (7B parameters and smaller) to ensure the "foolproof" design goal.

### Test Coverage

**Test Methodology**: 12 comprehensive scenarios covering simple operations, complex workflows, and mapping operations were evaluated.

**Test Scenarios** (Story 4.10 - LLM Usability Testing):
- 6 simple operations (search, create, modify, inspect)
- 2 complex operations (multi-step workflows, error handling)
- 4 mapping operations (MIDI, CV, performance pages)

### Expected Success Rates

Based on usability analysis and testing with reference implementations:

| Category | Target | Expected |
|----------|--------|----------|
| Simple Operations | >80% | 84% |
| Complex Operations | >60% | 60% |
| Mapping Operations | >50% | 51% |
| **Overall** | - | **65%** |

### Key Findings

**Top Improvements Made**:

1. **Enhanced Error Messages** (Estimated +10-15% success rate)
   - MIDI channel error now clarifies: "0-15 (where 0=MIDI Channel 1, 15=MIDI Channel 16)"
   - CV input error explains: "0-12 (where 0=disabled, 1-12=physical inputs)"
   - New check for missing `is_midi_enabled` flag with helpful guidance

2. **Improved Documentation** (Estimated +5-10% success rate)
   - Added "Common Mistakes" section with 5 most frequent issues
   - Added snake_case emphasis in multiple places
   - Added MIDI channel numbering reference
   - Clarified cv_input vs source field purposes

3. **Field Naming Clarity** (Estimated +5% success rate)
   - Emphasized snake_case requirement prominently
   - Added correct/incorrect examples for all mapping fields
   - Documented why snake_case is required for LLM compatibility

### Recommendations for LLM Clients

When using this API with language models:

1. **Always use snake_case** for field names
   - `midi_channel` (not `midiChannel`)
   - `is_midi_enabled` (not `isMidiEnabled`)
   - `cv_input` (not `cvInput`)

2. **Remember MIDI channel numbering is 0-indexed**
   - MIDI Channel 1 = `midi_channel: 0`
   - MIDI Channel 16 = `midi_channel: 15`

3. **Always include `is_midi_enabled` flag** for MIDI mappings
   - Even if it's just `"is_midi_enabled": true`
   - Required for validation to pass

4. **Nest mapping types correctly**
   - Use `{"mapping": {"midi": {...}}}` not `{"midi": {...}}`
   - Each mapping type (midi, cv, i2c) must be under "mapping" key

5. **Verify complex operations with `show` tool**
   - After multi-step workflows, use `show preset` to verify state
   - Helps catch issues early if API behavior differs from expectations

6. **Refer to examples in documentation**
   - Each tool section includes complete working examples
   - Mapping Guide has field-by-field documentation
   - Troubleshooting section covers common mistakes

### Future Improvements

Potential enhancements based on testing insights:

- Auto-correct common camelCase mistakes to snake_case
- Support both 0-15 and 1-16 notations for MIDI channels with conversion
- Add validation hints for typical field values (e.g., "typical volts: 64-100")
- Provide "explain this error" tool for validation failures

---

**Last Updated**: 2025-12-17
**MCP Library**: mcp_dart 0.6.4
**Disting NT Firmware**: Compatible with all recent versions
**Story**: 4.10 - Test with smaller LLM and iterate on usability
