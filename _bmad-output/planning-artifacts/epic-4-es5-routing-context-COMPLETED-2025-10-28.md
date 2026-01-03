# Epic 4: ES-5 Direct Output Support for New Algorithms - Technical Context

**Generated:** 2025-10-28
**Epic:** 4
**Status:** Ready for Story Development

---

## Epic Overview

**Goal:** Extend ES-5 direct output support to three algorithms that gained this capability in Disting NT firmware 1.12: Poly CV (pycv), Clock Divider (clkd), and Clock Multiplier (clkm).

**Value:** Users with ES-5 expander modules can configure and visualize ES-5 routing for all supported algorithms in nt_helper, eliminating the need to fall back to the reference HTML editor for these three algorithms. This maintains nt_helper's role as the primary preset management tool.

---

## Existing Infrastructure (ES-5 Pattern Already Established)

### Base Class Pattern

**File:** `lib/core/routing/es5_direct_output_algorithm_routing.dart` (206 lines)

The ES-5 direct output pattern is fully implemented as a base class that handles dual-mode output logic:

**Dual-Mode Behavior:**
1. **ES-5 Mode** (ES-5 Expander > 0): Output routes directly to ES-5 port, **completely ignoring** the normal Output parameter
2. **Normal Mode** (ES-5 Expander = 0): Output uses normal bus assignment from Output parameter

**Key Features:**
- Extends `MultiChannelAlgorithmRouting` for per-channel support
- Special bus marker: `es5DirectBusParam = 'es5_direct'` for ES-5 connections
- Helper method: `getChannelParameter(channel, paramName)` extracts channel-prefixed parameters (e.g., "1:ES-5 Expander")
- Factory helper: `createConfigFromSlot()` provides shared creation logic

**Port Generation Pattern:**
```dart
@override
List<Port> generateOutputPorts() {
  for (int channel = 1; channel <= config.channelCount; channel++) {
    final es5ExpanderValue = getChannelParameter(channel, 'ES-5 Expander');

    if (es5ExpanderValue != null && es5ExpanderValue > 0) {
      // ES-5 MODE: Create ES-5 direct output port
      final es5OutputValue = getChannelParameter(channel, 'ES-5 Output') ?? channel;
      ports.add(Port(
        id: '${algorithmUuid}_channel_${channel}_es5_output',
        name: 'Ch$channel → ES-5 $es5OutputValue',
        busParam: es5DirectBusParam, // Special marker
        channelNumber: es5OutputValue, // ES-5 port number
      ));
    } else {
      // NORMAL MODE: Create normal output port using Output parameter
      final outputBus = getChannelParameter(channel, 'Output') ?? 0;
      if (outputBus > 0) {
        ports.add(Port(
          id: '${algorithmUuid}_channel_${channel}_output',
          name: 'Channel $channel',
          busValue: outputBus,
          channelNumber: channel,
        ));
      }
    }
  }
}
```

---

## Reference Implementations (Already Working)

### 1. Clock Algorithm (clck)
**File:** `lib/core/routing/clock_algorithm_routing.dart` (50 lines)

**Pattern:**
- Simple extension of `Es5DirectOutputAlgorithmRouting`
- Implements `canHandle(Slot slot)` checking `slot.algorithm.guid == 'clck'`
- Factory method `createFromSlot()` calls base class helper
- Minimal algorithm-specific code

**Key Code:**
```dart
class ClockAlgorithmRouting extends Es5DirectOutputAlgorithmRouting {
  @override
  String get algorithmName => 'ClockAlgorithmRouting';

  static bool canHandle(Slot slot) {
    return slot.algorithm.guid == 'clck';
  }

  static ClockAlgorithmRouting createFromSlot(Slot slot, ...) {
    final configData = Es5DirectOutputAlgorithmRouting.createConfigFromSlot(
      slot,
      ioParameters: ioParameters,
      debugName: 'ClockAlgorithmRouting',
    );
    return ClockAlgorithmRouting(slot: slot, config: configData.config);
  }
}
```

### 2. Euclidean Algorithm (eucp)
**File:** `lib/core/routing/euclidean_algorithm_routing.dart` (50 lines)

**Pattern:**
- Identical structure to Clock
- Guid check: `slot.algorithm.guid == 'eucp'`
- Per-channel ES-5 support (multiple Euclidean channels)

**Registration in Factory:**
```dart
// From lib/core/routing/algorithm_routing.dart:309-320
} else if (ClockAlgorithmRouting.canHandle(slot)) {
  instance = ClockAlgorithmRouting.createFromSlot(...);
} else if (EuclideanAlgorithmRouting.canHandle(slot)) {
  instance = EuclideanAlgorithmRouting.createFromSlot(...);
}
```

---

## Algorithm-Specific Technical Details

### Algorithm 1: Clock Multiplier (clkm) - SIMPLEST

**Complexity:** Simple single-channel clock multiplier

**GUID:** `clkm`

**Expected ES-5 Parameters:**
- `ES-5 Expander` (parameter 7 or similar) - Mode selector (0=Off, 1-6=Active)
- `ES-5 Output` (parameter 8 or similar) - Port selector (1-8)

**I/O Parameters:**
```dart
ioParameters: {
  'Clock input': paramNumber,  // Input parameter
  'Clock output': paramNumber, // Normal output parameter
}
```

**Implementation Strategy:**
- Copy Clock algorithm pattern exactly
- Guid check: `slot.algorithm.guid == 'clkm'`
- Single channel (channelCount = 1)
- Global ES-5 configuration (not per-channel)

**File to Create:** `lib/core/routing/clock_multiplier_algorithm_routing.dart`

**Metadata Status:** ⚠️ ES-5 parameters NOT present in `docs/algorithms/clkm.json` - must be added in Story E4.4

---

### Algorithm 2: Clock Divider (clkd) - MODERATE COMPLEXITY

**Complexity:** Multichannel clock divider with per-channel ES-5 configuration

**GUID:** `clkd`

**Channel Structure:**
- Always has 8 channels in parameter list
- Parameters repeat every 11 positions per channel
- Channels filtered by `X:Enable` parameter (only show enabled channels)

**Expected ES-5 Parameters (Per-Channel):**
- `X:ES-5 Expander` where X is channel number 1-8
- `X:ES-5 Output` where X is channel number 1-8

**I/O Parameters (Per-Channel):**
```dart
ioParameters: {
  'X:Input': paramNumber,        // Per-channel input
  'X:Reset input': paramNumber,  // Per-channel reset
  'X:Output': paramNumber,       // Per-channel normal output
}

// Also supports shared reset:
'Reset input': paramNumber, // Global reset (non-prefixed)
```

**Channel Detection Pattern:**
```dart
// From base class:
for (final param in slot.parameters) {
  final match = RegExp(r'^(\d+):').firstMatch(param.name);
  if (match != null) {
    final channelNum = int.parse(match.group(1)!);
    if (channelNum > channelCount) {
      channelCount = channelNum;
    }
  }
}
// Result: channelCount = 8 (all channels always present)
```

**Channel Filtering:**
- Must check `X:Enable` parameter for each channel
- Only generate ports for enabled channels (Enable = 1)

**Implementation Strategy:**
- Follow Euclidean pattern (per-channel ES-5)
- Guid check: `slot.algorithm.guid == 'clkd'`
- Filter channels by `Enable` parameter
- Per-channel ES-5 configuration

**File to Create:** `lib/core/routing/clock_divider_algorithm_routing.dart`

**Metadata Status:** ⚠️ ES-5 parameters NOT present in `docs/algorithms/clkd.json` - must be added in Story E4.4

---

### Algorithm 3: Poly CV (pycv) - MOST COMPLEX

**Complexity:** Polyphonic MIDI/CV with multiple output types per voice and global ES-5 configuration

**GUID:** Starts with `py` (handled by `PolyAlgorithmRouting`)

**Current Routing:** `lib/core/routing/poly_algorithm_routing.dart` (500+ lines)

**ES-5 Configuration (Global):**
- `ES-5 Expander` (parameter 53) - Global mode selector
- `ES-5 Output` (parameter 54) - Base ES-5 port number

**Output Types (Per-Voice):**
- **Gate outputs** - Boolean parameter enables/disables
- **Pitch CV outputs** - Boolean parameter enables/disables
- **Velocity CV outputs** - Boolean parameter enables/disables

**Critical ES-5 Behavior:**
- ES-5 applies to **GATE OUTPUTS ONLY**
- Pitch and Velocity CVs **ALWAYS use normal bus allocation**
- When ES-5 Expander > 0:
  - Gate outputs route sequentially to ES-5 ports starting from `ES-5 Output` value
  - Example: ES-5 Output = 3, Voice count = 4 → Gates go to ES-5 ports 3, 4, 5, 6
  - Pitch/Velocity CVs still use `First output` parameter and normal buses

**Voice Count Dynamics:**
- Voice count controlled by specifications (varies with output configuration)
- Voice count may **increase** when ES-5 is enabled (specification change)
- Extract from parameter 23: "Voices"

**UI Pattern (Recommended - Option B from Story E4.3):**
- Each gate output port displays an ES-5 toggle button
- All gate toggles are **synchronized** (toggling one toggles all)
- All toggles control the same global parameter 53 (`ES-5 Expander`)
- Tooltip indicates global behavior: "ES-5 Mode: On (all gates)" / "ES-5 Mode: Off"

**Implementation Strategy:**
- Extend existing `PolyAlgorithmRouting` class (DO NOT create new file)
- Add ES-5 parameter parsing
- Modify `generateOutputPorts()` to handle ES-5 for gates only
- Populate `es5ChannelToggles` for all gate port channel numbers
- Populate `es5ExpanderParameterNumbers` with parameter 53 for all gates
- Leave pitch/velocity output generation unchanged (normal buses)

**Edge Cases:**
- Voice count > 8: Gates beyond 8th won't fit on ES-5 (warn or clip?)
- Mixed routing: Gates to ES-5, CVs to normal buses (most common use case)

**File to Modify:** `lib/core/routing/poly_algorithm_routing.dart` (existing)

**Metadata Status:** ⚠️ ES-5 parameters NOT present in `docs/algorithms/pycv.json` - must be added in Story E4.4

---

## Factory Registration Pattern

**File:** `lib/core/routing/algorithm_routing.dart`

**Current Registration (lines 309-320):**
```dart
} else if (ClockAlgorithmRouting.canHandle(slot)) {
  instance = ClockAlgorithmRouting.createFromSlot(
    slot,
    ioParameters: {...},
    algorithmUuid: algorithmUuid,
  );
} else if (EuclideanAlgorithmRouting.canHandle(slot)) {
  instance = EuclideanAlgorithmRouting.createFromSlot(
    slot,
    ioParameters: {...},
    algorithmUuid: algorithmUuid,
  );
}
```

**Required Additions:**
1. After Euclidean check, add Clock Multiplier check
2. After Clock Multiplier, add Clock Divider check
3. Poly CV already registered earlier in factory (guid starts with 'py')

**Registration Order:**
```
1. USB From (guid == 'usbf')
2. ES5 Encoder (guid == 'es5e')
3. Clock (guid == 'clck')
4. Euclidean (guid == 'eucp')
5. [NEW] Clock Multiplier (guid == 'clkm')
6. [NEW] Clock Divider (guid == 'clkd')
7. Poly algorithms (guid starts with 'py')
```

---

## Testing Infrastructure (Established Patterns)

### Existing Test File
**File:** `test/core/routing/clock_euclidean_es5_test.dart` (470+ lines)

**Test Pattern:**
```dart
group('Clock/Euclidean ES-5 Direct Routing Tests', () {
  test('Clock ES-5 mode: creates ES-5 direct output port', () {
    final slot = createClockSlot(
      channelCount: 1,
      channelConfigs: [(channel: 1, es5Expander: 1, es5Output: 3, output: 13)],
    );

    final routing = ClockAlgorithmRouting.createFromSlot(slot, ...);
    final outputPorts = routing.outputPorts;

    expect(outputPorts, hasLength(1));
    expect(outputPorts[0].name, equals('Ch1 → ES-5 3'));
    expect(outputPorts[0].busParam, equals('es5_direct'));
    expect(outputPorts[0].channelNumber, equals(3));
  });

  test('Clock normal mode: creates normal output port', () {
    final slot = createClockSlot(
      channelCount: 1,
      channelConfigs: [(channel: 1, es5Expander: 0, es5Output: 3, output: 15)],
    );

    final routing = ClockAlgorithmRouting.createFromSlot(slot, ...);
    final outputPorts = routing.outputPorts;

    expect(outputPorts, hasLength(1));
    expect(outputPorts[0].name, equals('Channel 1'));
    expect(outputPorts[0].busValue, equals(15));
  });
});
```

**Helper Functions:**
- `createClockSlot()` - Creates test slot with channel configs
- `createEuclideanSlot()` - Creates test slot for Euclidean
- Both helpers parameterize ES-5 Expander, ES-5 Output, and Output values

### Required New Test Files

**1. Clock Multiplier Tests:**
- **File:** `test/core/routing/clock_multiplier_es5_test.dart`
- **Tests:**
  - ES-5 mode: ES-5 Expander > 0 creates ES-5 direct output
  - Normal mode: ES-5 Expander = 0 creates normal output
  - Output parameter ignored in ES-5 mode
- **Pattern:** Copy clock_euclidean_es5_test.dart structure, simplify for single channel

**2. Clock Divider Tests:**
- **File:** `test/core/routing/clock_divider_es5_test.dart`
- **Tests:**
  - Multichannel with mixed ES-5/normal outputs
  - Per-channel ES-5 configuration
  - Channel filtering by Enable parameter
  - Shared vs. per-channel reset inputs
- **Pattern:** Follow Euclidean multichannel pattern, add channel filtering

**3. Poly CV ES-5 Tests:**
- **File:** `test/core/routing/poly_cv_es5_test.dart`
- **Tests:**
  - Multi-voice ES-5 routing (gates only)
  - Pitch/Velocity CVs always use normal buses
  - Mixed routing: gates to ES-5, CVs to normal buses
  - Voice count extraction (1-14 voices)
  - Edge case: Voice count > 8 ES-5 ports
- **Pattern:** New pattern for poly algorithm with selective ES-5 (gates only)

### Metadata Test
**File:** `test/services/es5_parameters_metadata_test.dart`

This test verifies ES-5 parameters are present in algorithm metadata for all ES-5-capable algorithms.

**Expected Update:**
```dart
test('Clock Multiplier has ES-5 parameters', () {
  // Verify clkm metadata includes ES-5 Expander and ES-5 Output
});

test('Clock Divider has ES-5 parameters', () {
  // Verify clkd metadata includes per-channel ES-5 parameters
});

test('Poly CV has ES-5 parameters', () {
  // Verify pycv metadata includes global ES-5 parameters
});
```

---

## ES-5 Hardware Context

**ES-5 Expander Module:**
- Provides 8 additional CV/gate outputs (ES-5 ports 1-8)
- Connected via ribbon cable to Disting NT
- Outputs are independent of Disting NT's 4 main outputs

**Bus Assignments:**
- Normal inputs: 1-12
- Normal outputs: 13-20
- ES-5 outputs: 35-42 (ports 1-8 map to buses 35-42)
- ES-5 direct: Special marker `es5_direct` bypasses normal bus system

**Connection Discovery:**
- `ConnectionDiscoveryService` recognizes `es5_direct` bus marker
- Creates connections to ES-5 hardware nodes in routing graph
- ES-5 ports displayed as separate output nodes in routing editor

---

## Metadata Update Requirements (Story E4.4)

### Files to Update

**1. Clock Multiplier:** `docs/algorithms/clkm.json`
```json
{
  "parameters": [
    // ... existing parameters ...
    {
      "name": "ES-5 Expander",
      "min": 0,
      "max": 6,
      "default": 0,
      "type": "enum",
      "parameterNumber": 7
    },
    {
      "name": "ES-5 Output",
      "min": 1,
      "max": 8,
      "default": 1,
      "type": "enum",
      "parameterNumber": 8
    }
  ]
}
```

**2. Clock Divider:** `docs/algorithms/clkd.json`
```json
{
  "parameters": [
    // ... existing parameters ...
    {
      "name": "ES-5 Expander",
      "min": 0,
      "max": 6,
      "default": 0,
      "type": "enum",
      "is_per_channel": true
    },
    {
      "name": "ES-5 Output",
      "min": 1,
      "max": 8,
      "default": 1,
      "type": "enum",
      "is_per_channel": true
    }
  ]
}
```

**3. Poly CV:** `docs/algorithms/pycv.json`
```json
{
  "parameters": [
    // ... existing parameters ...
    {
      "name": "ES-5 Expander",
      "min": 0,
      "max": 6,
      "default": 0,
      "type": "enum",
      "parameterNumber": 53
    },
    {
      "name": "ES-5 Output",
      "min": 1,
      "max": 8,
      "default": 1,
      "type": "enum",
      "parameterNumber": 54
    }
  ]
}
```

**4. Full Metadata:** `assets/metadata/full_metadata.json`
- Regenerate after updating algorithm JSON files
- Run metadata sync or rebuild script

**Note:** Actual parameter numbers and names must be verified against firmware 1.12+ hardware. The numbers above are estimates based on typical patterns.

---

## Story Implementation Guidance

### Story E4.1: Clock Multiplier (Simplest)
**Estimated Effort:** 2 hours

**Steps:**
1. Copy `clock_algorithm_routing.dart` → `clock_multiplier_algorithm_routing.dart`
2. Change guid check to `'clkm'`
3. Update algorithm name
4. Define ioParameters (Clock input, Clock output)
5. Register in factory after Euclidean
6. Copy test file structure from `clock_euclidean_es5_test.dart`
7. Run tests: `flutter test test/core/routing/clock_multiplier_es5_test.dart`
8. Run `flutter analyze` (must pass)

**Success Criteria:**
- Routing editor shows ES-5 output when ES-5 Expander > 0
- Routing editor shows normal output when ES-5 Expander = 0
- Tests pass
- No analyzer warnings

---

### Story E4.2: Clock Divider (Moderate)
**Estimated Effort:** 3-4 hours

**Steps:**
1. Create `clock_divider_algorithm_routing.dart` extending `Es5DirectOutputAlgorithmRouting`
2. Implement guid check: `'clkd'`
3. Define per-channel ioParameters (X:Input, X:Reset input, X:Output)
4. Add channel filtering logic (check `X:Enable` parameter)
5. Handle shared reset input (non-prefixed parameter)
6. Register in factory after Clock Multiplier
7. Create comprehensive tests for multichannel, mixed ES-5/normal, filtering
8. Run tests: `flutter test test/core/routing/clock_divider_es5_test.dart`
9. Run `flutter analyze` (must pass)

**Success Criteria:**
- Per-channel ES-5 configuration works
- Only enabled channels show ports
- Shared reset input handled correctly
- Mixed ES-5/normal outputs work
- Tests pass
- No analyzer warnings

---

### Story E4.3: Poly CV (Most Complex)
**Estimated Effort:** 4-6 hours

**Steps:**
1. Open `lib/core/routing/poly_algorithm_routing.dart` (DO NOT create new file)
2. Add ES-5 parameter parsing (parameters 53, 54)
3. Modify `generateOutputPorts()`:
   - Extract voice count from parameter 23
   - Check ES-5 Expander (parameter 53)
   - If ES-5 active: Gate outputs → ES-5 ports sequentially
   - If ES-5 off: All outputs → normal buses (existing behavior)
   - Pitch/Velocity CVs **always** use normal buses
4. Implement synchronized ES-5 toggle pattern:
   - Populate `es5ChannelToggles` for gate port channel numbers
   - Populate `es5ExpanderParameterNumbers` with parameter 53
5. Handle edge cases (voice count > 8)
6. Create poly CV ES-5 tests (new pattern)
7. Run tests: `flutter test test/core/routing/poly_cv_es5_test.dart`
8. Run all tests: `flutter test` (ensure no regressions)
9. Run `flutter analyze` (must pass)

**Success Criteria:**
- Gate outputs route to ES-5 when ES-5 Expander > 0
- Pitch/Velocity CVs always use normal buses
- Mixed routing works (gates to ES-5, CVs to buses)
- ES-5 toggles synchronized
- Voice count correctly extracted
- Tests pass
- No analyzer warnings

---

### Story E4.4: Metadata Update (Can Run in Parallel)
**Estimated Effort:** 2 hours

**Steps:**
1. Research firmware 1.12 release notes for actual ES-5 parameter names/numbers
2. Update `docs/algorithms/clkm.json` with ES-5 parameters
3. Update `docs/algorithms/clkd.json` with per-channel ES-5 parameters
4. Update `docs/algorithms/pycv.json` with global ES-5 parameters
5. Regenerate `assets/metadata/full_metadata.json`
6. Update `test/services/es5_parameters_metadata_test.dart`
7. Run metadata test: `flutter test test/services/es5_parameters_metadata_test.dart`
8. Run `flutter analyze` (must pass)

**Success Criteria:**
- ES-5 parameters present in all three algorithm JSON files
- Parameter names match firmware
- Metadata test passes
- No analyzer warnings

---

### Story E4.5: Tests (After E4.1-E4.3 Complete)
**Estimated Effort:** 3 hours

**Steps:**
1. Review test coverage for all three new routing implementations
2. Add missing test cases (if any)
3. Update `test/core/routing/algorithm_loading_test.dart` to include new algorithms
4. Update `test/integration/es5_routing_integration_test.dart` if needed
5. Run full test suite: `flutter test`
6. Fix any failures
7. Run `flutter analyze` (must pass)

**Success Criteria:**
- All new tests pass
- Integration tests pass
- Full test suite passes
- No analyzer warnings

---

### Story E4.6: Documentation (After All Stories Complete)
**Estimated Effort:** 1 hour

**Steps:**
1. Update `docs/architecture.md` routing section
2. Add Epic 4 completion note
3. List all 5 ES-5-capable algorithms: clck, eucp, clkm, clkd, pycv
4. Update routing audit if exists: `docs/audit/routing_audit.md`
5. Update `CLAUDE/index.md` if routing section exists
6. Run `flutter analyze` (must pass)

**Success Criteria:**
- Documentation updated
- All 5 ES-5 algorithms listed
- No analyzer warnings

---

---

### Story E4.7: Routing Editor Visual Refinements (Completed 2025-11-25)
**Estimated Effort:** 4 hours

**Goal:** Refine the visual presentation of connections and algorithm nodes in the `RoutingEditorWidget` to ensure professional quality and usability.

**Changes Implemented:**
1.  **Clipped Connection Endpoints:**
    - Modified `ConnectionPainter` to clip connection lines precisely to the bounding box of source and destination nodes.
    - Removed fixed-length "tail" segments that looked disconnected on larger nodes.
    - Updated `RoutingEditorWidget` to calculate and pass `nodeBoundsMap` to the painter.

2.  **Algorithm Node Styling:**
    - Updated `AlgorithmNodeWidget` title bar transparency to match the node body (`alpha: 0.7`).
    - Ensures consistent visual weight across the node.

3.  **Bus Label Positioning & Z-Order:**
    - **Positioning:** Implemented size reporting for `PhysicalInputNode` and `PhysicalOutputNode` to ensure accurate obstacle avoidance. Reduced avoidance margin for connected nodes (20.0 -> 5.0) to prevent labels from being "repelled" too far.
    - **Z-Order:** Moved bus label rendering to the foreground pass (`drawEndpointsOnly: true`) in `RoutingEditorWidget`. This ensures labels are always drawn *on top* of nodes, never underneath.

**Success Criteria:**
- ✅ Connections appear to emerge from node edges.
- ✅ Algorithm node styling is consistent.
- ✅ Bus labels are legible, correctly positioned, and always visible on top of nodes.
- ✅ No regressions in routing functionality.

---

## Risk Mitigation

**Risks:**
1. **Metadata Accuracy** → ES-5 parameter names/numbers must match firmware 1.12+
   - Mitigation: Test with actual hardware, verify with firmware release notes
2. **Poly CV Complexity** → Multiple output types, global ES-5, voice count dynamics
   - Mitigation: Start with simple test cases, incrementally add complexity
3. **Channel Filtering (Clock Divider)** → Enable parameter must correctly filter channels
   - Mitigation: Add explicit tests for channel filtering

**Performance:**
- ES-5 adds minimal overhead (same pattern as existing Clock/Euclidean)
- Connection discovery already handles ES-5 markers efficiently

**Testing Strategy:**
- Unit tests for each algorithm routing class
- Integration tests for connection discovery
- Manual testing with hardware (if available)

---

## Success Criteria

1. ✅ Clock Multiplier ES-5 routing works in routing editor
2. ✅ Clock Divider per-channel ES-5 routing works
3. ✅ Poly CV gate-only ES-5 routing works
4. ✅ Metadata includes ES-5 parameters for all three algorithms
5. ✅ All tests pass
6. ✅ `flutter analyze` passes with zero warnings
7. ✅ Documentation updated
8. ✅ No regressions in existing routing functionality

---

## References

- Base class: `lib/core/routing/es5_direct_output_algorithm_routing.dart`
- Reference implementations: `clock_algorithm_routing.dart`, `euclidean_algorithm_routing.dart`
- Test pattern: `test/core/routing/clock_euclidean_es5_test.dart`
- Factory registration: `lib/core/routing/algorithm_routing.dart` (lines 309-320)
- Epic spec: `docs/epics.md` (Epic 4 section)
- Firmware 1.12 release notes: [Expert Sleepers website]
