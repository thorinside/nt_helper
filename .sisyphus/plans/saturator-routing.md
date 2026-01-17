# Saturator Algorithm Routing Improvements

## Context

### Original Request
The saturator algorithm (`satu`) uses the same bus for input AND output (in-place processing), but the routing editor doesn't visualize this correctly. It shows no outputs, and inputs from physical outputs (buses 13-20) appear as unconnected.

### Interview Summary
**Key Discussions**:
- Saturator has TWO dimensions of multiplicity: Channels (1-8 from specification) and Width (per-channel consecutive buses)
- Each channel has prefixed parameters: `1:Input`, `1:Width`, `2:Input`, `2:Width`, etc.
- For each input, create a virtual output on the same bus with `OutputMode.replace`
- Width expands to numbered ports: `1:Input 1`...`1:Input N` → `1:Output 1`...`1:Output N`
- When reading from physical output buses (13-20), draw connection FROM hardware output node

**Research Findings**:
- `Es5DirectOutputAlgorithmRouting` is a good subclass pattern to follow (stores `Slot` reference)
- Saturator `1:Input` found at `assets/metadata/full_metadata.json:7386` with `ioFlags: 5` (input + audio)
- Saturator `1:Width` found at `assets/metadata/full_metadata.json:9834` with `minValue: 1`, `maxValue: 12`
- `ConnectionDiscoveryService` only creates hardware input connections for buses 1-12 (`lib/core/routing/connection_discovery_service.dart:112`)
- Saturator guid is `satu` (confirmed in `docs/algorithms/satu.json:2`)

### Metis Review
**Identified Gaps** (addressed):
- Parameter name validation: Confirmed `N:Input`, `N:Width` pattern from metadata
- Width semantics: Confirmed as count 1-12, `minValue: 1` means width=0 is invalid
- Guardrails updated: Physical output as input source becomes a GENERAL feature (not Saturator-specific)

---

## Work Objectives

### Core Objective
Create a `SaturatorAlgorithmRouting` subclass that generates virtual input/output ports based on channels × width, with all outputs forcing replace mode, and enable physical output buses (13-20) as input sources in the connection discovery for ALL algorithms.

### Concrete Deliverables
- `lib/core/routing/saturator_algorithm_routing.dart` - New routing subclass
- Modified `lib/core/routing/algorithm_routing.dart` - Factory registration
- Modified `lib/core/routing/connection_discovery_service.dart` - Physical output as input source (general feature)
- `test/core/routing/saturator_algorithm_routing_test.dart` - Unit tests
- `test/core/routing/saturator_routing_integration_test.dart` - Integration tests

### Definition of Done
- [ ] `flutter analyze` passes with zero warnings
- [ ] `flutter test` passes (all existing + new tests)
- [ ] Saturator with 1 channel, width=1 shows 1 input + 1 output on same bus
- [ ] Saturator with 1 channel, width=3 shows 3 inputs + 3 outputs on consecutive buses
- [ ] Saturator with 2 channels shows separate input/output pairs per channel
- [ ] All virtual outputs have `OutputMode.replace`
- [ ] Any algorithm reading from bus 15 shows connection from hardware output O3

### Must Have
- `SaturatorAlgorithmRouting` extends `MultiChannelAlgorithmRouting` and stores `Slot` reference
- `canHandle(slot)` returns true only for `satu` guid
- Virtual output ports for each input port, same bus, replace mode
- Width-expanded virtual inputs when width > 1
- Physical output (13-20) as input source in ConnectionDiscoveryService (general feature for all algorithms)
- Factory registration before `MultiChannelAlgorithmRouting` fallback

### Must NOT Have (Guardrails)
- ❌ Modifications to `MultiChannelAlgorithmRouting` class itself
- ❌ New `ConnectionType` enum values (use existing `ConnectionType.hardwareInput`)
- ❌ UI component changes (`RoutingEditorWidget`, `PortWidget`, etc.)
- ❌ Debug logging (per AGENTS.md)
- ❌ Width=0 handling (metadata shows `minValue: 1`, so width=0 is invalid)

---

## Verification Strategy (MANDATORY)

### Test Decision
- **Infrastructure exists**: YES (Flutter test framework)
- **User wants tests**: YES (TDD)
- **Framework**: `flutter test`

### TDD Workflow
Each TODO follows RED-GREEN:

1. **RED**: Write failing test first
   - Test file created
   - `flutter test <file>` → FAIL (test exists, implementation doesn't or is incomplete)
2. **GREEN**: Implement minimum code to pass
   - `flutter test <file>` → PASS

---

## Task Flow

```
TODO 1 (canHandle tests) 
    ↓
TODO 2 (canHandle impl)
    ↓
TODO 3 (port generation tests - mono)
    ↓
TODO 4 (port generation impl - mono)
    ↓
TODO 5 (port generation tests - width)
    ↓
TODO 6 (port generation impl - width)
    ↓
TODO 7 (port generation tests - multi-channel)
    ↓
TODO 8 (port generation impl - multi-channel)
    ↓
TODO 9 (factory registration)
    ↓
TODO 10 (physical output input tests)
    ↓
TODO 11 (physical output input impl)
    ↓
TODO 12 (integration tests)
    ↓
TODO 13 (final verification)
```

## Parallelization

| Task | Depends On | Reason |
|------|------------|--------|
| 1 | - | First task |
| 2 | 1 | GREEN phase for TODO 1's RED |
| 3 | 2 | Needs canHandle working |
| 4 | 3 | GREEN phase for TODO 3's RED |
| 5 | 4 | Needs mono working first |
| 6 | 5 | GREEN phase for TODO 5's RED |
| 7 | 6 | Needs width working |
| 8 | 7 | GREEN phase for TODO 7's RED |
| 9 | 8 | Needs all port generation working |
| 10 | 9 | Factory must be registered |
| 11 | 10 | GREEN phase for TODO 10's RED |
| 12 | 11 | All components must work |
| 13 | 12 | Final verification |

---

## TODOs

### TODO 1: RED - canHandle() Tests

**What to do**:
- Create test file `test/core/routing/saturator_algorithm_routing_test.dart`
- Write tests for `SaturatorAlgorithmRouting.canHandle()`
- Test: returns `true` for slot with `algorithm.guid == 'satu'`
- Test: returns `false` for slot with different guid (e.g., `'mixr'`)

**Must NOT do**:
- Implement the actual class yet (RED phase)
- Import non-existent file (create minimal stub that returns false)

**Parallelizable**: NO (first task)

**References**:

**Pattern References** (existing test slot creation to follow):
- `test/core/routing/clock_euclidean_es5_test.dart:13-97` - `createClockSlot()` helper function pattern
- `test/core/routing/clock_euclidean_es5_test.dart:114-198` - `createEuclideanSlot()` helper with parameters

**API/Type References** (contracts to implement against):
- `lib/core/routing/clock_algorithm_routing.dart:15-25` - Example `canHandle()` signature and implementation
- `lib/cubit/disting_cubit.dart:Slot` - Slot type with `algorithm.guid` property

**Test References** (testing patterns to follow):
- `test/core/routing/clock_euclidean_es5_test.dart:217-227` - Test structure for canHandle verification

**Documentation References**:
- `docs/algorithms/satu.json:2` - Confirms guid is `satu`
- `assets/metadata/full_metadata.json:7386` - `1:Input` parameter structure

**Acceptance Criteria**:
- [x] Test file created: `test/core/routing/saturator_algorithm_routing_test.dart`
- [x] Minimal stub created: `lib/core/routing/saturator_algorithm_routing.dart` with `canHandle()` returning `false`
- [x] Tests written for canHandle true/false cases
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → FAIL (canHandle returns false)

**Commit**: NO (groups with TODO 2)

---

### TODO 2: GREEN - canHandle() Implementation

**What to do**:
- Implement `SaturatorAlgorithmRouting.canHandle()` to return `true` for `satu` guid
- Add class skeleton extending `MultiChannelAlgorithmRouting`
- Store `Slot` reference in the class (like `Es5DirectOutputAlgorithmRouting`)

**Must NOT do**:
- Implement port generation yet
- Register in factory yet

**Parallelizable**: NO (depends on 1)

**References**:

**Pattern References** (existing code to follow):
- `lib/core/routing/clock_algorithm_routing.dart:15-30` - `canHandle()` implementation pattern
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:25-36` - Class structure with `Slot` storage

**Acceptance Criteria**:
- [x] `SaturatorAlgorithmRouting` class extends `MultiChannelAlgorithmRouting`
- [x] Class stores `final Slot slot` reference
- [x] `static bool canHandle(Slot slot)` returns `slot.algorithm.guid == 'satu'`
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → PASS

**Commit**: YES
- Message: `feat(routing): add SaturatorAlgorithmRouting.canHandle()`
- Files: `lib/core/routing/saturator_algorithm_routing.dart`, `test/core/routing/saturator_algorithm_routing_test.dart`
- Pre-commit: `flutter test test/core/routing/saturator_algorithm_routing_test.dart`

---

### TODO 3: RED - Port Generation Tests (Mono)

**What to do**:
- Add tests for mono (width=1) port generation
- Test: 1 channel, width=1, input=bus 5 → 1 input port `1:Input` (bus 5), 1 output port `1:Output` (bus 5, replace mode)
- Test: Output port has `OutputMode.replace`
- Test: Output port has same `busValue` as input

**Must NOT do**:
- Implement port generation yet (RED phase)

**Parallelizable**: NO (depends on 2)

**References**:

**Pattern References** (slot creation helpers):
- `test/core/routing/clock_euclidean_es5_test.dart:13-97` - Slot creation with parameters and values

**API/Type References**:
- `lib/core/routing/models/port.dart:1-50` - Port model with `OutputMode`, `busValue`, `direction`
- `assets/metadata/full_metadata.json:7386` - `1:Input` has `parameterNumber: 4`, `ioFlags: 5`

**Test References**:
- `test/core/routing/clock_euclidean_es5_test.dart:227-251` - Output port assertion patterns

**Acceptance Criteria**:
- [x] Tests for mono port generation added
- [x] Tests check input port name `1:Input`, busValue=5
- [x] Tests check output port name `1:Output`, busValue=5, `outputMode == OutputMode.replace`
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → FAIL (ports not generated correctly)

**Commit**: NO (groups with TODO 4)

---

### TODO 4: GREEN - Port Generation Implementation (Mono)

**What to do**:
- Implement `generateInputPorts()` to create input ports from `N:Input` parameters
- Implement `generateOutputPorts()` to create virtual output ports matching inputs
- Each output has same bus as corresponding input, `OutputMode.replace`
- Implement `createFromSlot()` static factory method

**Must NOT do**:
- Handle width > 1 yet
- Handle multi-channel complexity yet

**Parallelizable**: NO (depends on 3)

**References**:

**Pattern References** (existing implementations):
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:43-92` - `generateOutputPorts()` override pattern
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:346-398` - `getChannelParameter()` for prefixed params like `1:Input`
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:406-461` - `createConfigFromSlot()` pattern

**API/Type References**:
- `lib/core/routing/models/port.dart:OutputMode` - `OutputMode.replace` enum value
- `lib/core/routing/multi_channel_algorithm_routing.dart:564-600` - Base `createFromSlot()` signature

**Acceptance Criteria**:
- [x] `generateInputPorts()` returns input ports from slot parameters with `N:Input` pattern
- [x] `generateOutputPorts()` returns output ports matching inputs
- [x] Output ports have `outputMode: OutputMode.replace`
- [x] Output ports have same `busValue` as corresponding input
- [x] `createFromSlot()` factory method implemented
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → PASS

**Commit**: YES
- Message: `feat(routing): add SaturatorAlgorithmRouting mono port generation`
- Files: `lib/core/routing/saturator_algorithm_routing.dart`, `test/core/routing/saturator_algorithm_routing_test.dart`
- Pre-commit: `flutter test test/core/routing/saturator_algorithm_routing_test.dart`

---

### TODO 5: RED - Port Generation Tests (Width)

**What to do**:
- Add tests for width > 1 port generation
- Test: 1 channel, width=3, input=bus 5 → 3 input ports (`1:Input 1` bus 5, `1:Input 2` bus 6, `1:Input 3` bus 7)
- Test: 3 corresponding output ports with consecutive buses, all replace mode
- Test: width=1 still works (single port, no suffix)

**Must NOT do**:
- Implement width handling yet (RED phase)

**Parallelizable**: NO (depends on 4)

**References**:

**Pattern References**:
- `lib/core/routing/multi_channel_algorithm_routing.dart:836-867` - Existing width-based virtual port pattern (for reference, not to copy)

**Documentation References**:
- `assets/metadata/full_metadata.json:9834` - `1:Width` has `minValue: 1`, `maxValue: 12`

**Acceptance Criteria**:
- [x] Tests for width > 1 added (e.g., width=3)
- [x] Tests verify correct port count (width × 2 for input+output)
- [x] Tests verify consecutive bus values (bus 5, 6, 7 for width=3)
- [x] Tests verify naming pattern `1:Input 1`, `1:Input 2`, `1:Output 1`, `1:Output 2`
- [x] Tests verify width=1 produces `1:Input` / `1:Output` (no suffix)
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → FAIL (width not handled)

**Commit**: NO (groups with TODO 6)

---

### TODO 6: GREEN - Port Generation Implementation (Width)

**What to do**:
- Read `N:Width` parameter for each channel using `getChannelParameter()`
- For width=1: single port named `N:Input` / `N:Output`
- For width>1: generate numbered ports `N:Input 1`...`N:Input W` and `N:Output 1`...`N:Output W`
- Each virtual input/output uses consecutive bus values

**Must NOT do**:
- Multi-channel iteration yet (focus on single channel with width)

**Parallelizable**: NO (depends on 5)

**References**:

**Pattern References**:
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:346-398` - `getChannelParameter()` for reading `N:Width`
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:231-273` - `getParameterValueAndNumber()` for reading params

**Acceptance Criteria**:
- [x] Width parameter read from `N:Width` using existing helper patterns
- [x] Width=1 produces single ports without numeric suffix
- [x] Width>1 produces numbered virtual input/output ports
- [x] Bus values are consecutive (base + 0, base + 1, ... base + width-1)
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → PASS

**Commit**: YES
- Message: `feat(routing): add SaturatorAlgorithmRouting width-based port expansion`
- Files: `lib/core/routing/saturator_algorithm_routing.dart`, `test/core/routing/saturator_algorithm_routing_test.dart`
- Pre-commit: `flutter test test/core/routing/saturator_algorithm_routing_test.dart`

---

### TODO 7: RED - Port Generation Tests (Multi-Channel)

**What to do**:
- Add tests for multi-channel scenarios
- Test: 2 channels, ch1 width=2 bus 5, ch2 width=1 bus 10
- Test: Channel 1 has 2 input/output pairs (buses 5,6), Channel 2 has 1 pair (bus 10)
- Test: Ports correctly prefixed `1:Input 1`, `1:Input 2`, `2:Input`

**Must NOT do**:
- Implement multi-channel yet (RED phase)

**Parallelizable**: NO (depends on 6)

**References**:

**Pattern References**:
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:420-430` - Channel counting from parameter prefixes

**Test References**:
- `test/core/routing/clock_divider_es5_test.dart:164-190` - Multi-channel test patterns

**Acceptance Criteria**:
- [x] Tests for 2+ channels added
- [x] Tests verify each channel has correct port count based on its width
- [x] Tests verify channel prefixes (`1:`, `2:`)
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → PASS (multi-channel already working)

**Commit**: NO (groups with TODO 8)

---

### TODO 8: GREEN - Port Generation Implementation (Multi-Channel)

**What to do**:
- Detect number of channels from prefixed parameters (`1:Input`, `2:Input`, etc.)
- Iterate over each channel, applying width logic per channel
- Generate all input/output ports with proper prefixes and consecutive buses

**Must NOT do**:
- Factory registration yet

**Parallelizable**: NO (depends on 7)

**References**:

**Pattern References**:
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:420-430` - Channel counting logic: iterate params, extract `N:` prefix, find max N
- `lib/core/routing/es5_direct_output_algorithm_routing.dart:46-92` - Multi-channel output generation loop

**Acceptance Criteria**:
- [x] Channel count detected from parameter prefixes
- [x] Each channel processed independently with its own width
- [x] All ports correctly prefixed with channel number
- [x] `flutter test test/core/routing/saturator_algorithm_routing_test.dart` → PASS

**Commit**: YES
- Message: `feat(routing): add SaturatorAlgorithmRouting multi-channel support`
- Files: `lib/core/routing/saturator_algorithm_routing.dart`, `test/core/routing/saturator_algorithm_routing_test.dart`
- Pre-commit: `flutter test test/core/routing/saturator_algorithm_routing_test.dart`

---

### TODO 9: Factory Registration

**What to do**:
- Add import for `saturator_algorithm_routing.dart` in `algorithm_routing.dart`
- Add `SaturatorAlgorithmRouting.canHandle()` check in `AlgorithmRouting.fromSlot()`
- Place BEFORE `PolyAlgorithmRouting` check and `MultiChannelAlgorithmRouting` fallback (around line 422)
- Call `SaturatorAlgorithmRouting.createFromSlot()` when canHandle returns true

**Must NOT do**:
- Modify any other canHandle checks or routing logic
- Change the order of existing checks

**Parallelizable**: NO (depends on 8)

**References**:

**Pattern References**:
- `lib/core/routing/algorithm_routing.dart:380-439` - Factory method with canHandle checks
- `lib/core/routing/algorithm_routing.dart:9-15` - Import statements section
- `lib/core/routing/algorithm_routing.dart:422-429` - PolyAlgorithmRouting check (insert before this)

**Acceptance Criteria**:
- [x] Import added: `import 'saturator_algorithm_routing.dart';`
- [x] `SaturatorAlgorithmRouting.canHandle(slot)` check added before PolyAlgorithmRouting
- [x] `SaturatorAlgorithmRouting.createFromSlot()` called when canHandle returns true
- [x] `flutter analyze` → 0 issues
- [x] `flutter test` → All tests pass

**Commit**: YES
- Message: `feat(routing): register SaturatorAlgorithmRouting in factory`
- Files: `lib/core/routing/algorithm_routing.dart`
- Pre-commit: `flutter test`

---

### TODO 10: RED - Physical Output as Input Source Tests

**What to do**:
- Create test file `test/core/routing/physical_output_as_input_test.dart`
- Test: ANY algorithm with input on bus 15 (physical output O3) creates connection FROM `hw_out_3` TO algorithm input
- Test: Connection type is `ConnectionType.hardwareInput`
- Test: Existing algorithms with inputs on buses 1-12 still work (no regression)
- Test: Algorithm with input on bus 21 (aux bus) does NOT create hardware connection

**Must NOT do**:
- Implement connection discovery changes yet (RED phase)

**Parallelizable**: NO (depends on 9)

**References**:

**Pattern References**:
- `lib/core/routing/connection_discovery_service.dart:112-125` - Hardware input connection logic for buses 1-12
- `lib/core/routing/connection_discovery_service.dart:199-224` - `_createHardwareInputConnections()` helper
- `lib/core/routing/bus_spec.dart:27-28` - `isPhysicalInput()`, `isPhysicalOutput()` helpers

**Test References**:
- `test/core/routing/connection_discovery_service_test.dart` - Existing connection discovery tests

**API/Type References**:
- `lib/core/routing/models/connection.dart:ConnectionType.hardwareInput` - Connection type to use

**Acceptance Criteria**:
- [x] Test file created: `test/core/routing/physical_output_as_input_test.dart`
- [x] Test for algorithm input reading from physical output bus (13-20)
- [x] Test verifies connection created with `sourcePortId: 'hw_out_3'` for bus 15
- [x] Test verifies `connectionType: ConnectionType.hardwareInput`
- [x] Test for buses 1-12 still works (regression)
- [x] Test for aux bus (21+) does not create hardware connection
- [x] `flutter test test/core/routing/physical_output_as_input_test.dart` → FAIL

**Commit**: NO (groups with TODO 11)

---

### TODO 11: GREEN - Physical Output as Input Source Implementation

**What to do**:
- Modify `ConnectionDiscoveryService.discoverConnections()` to handle physical output buses (13-20) as input sources
- Add logic after existing hardware input handling (around line 125)
- For buses 13-20, create connection from `hw_out_{busNumber - 12}` to the input port
- Use `ConnectionType.hardwareInput` (same as buses 1-12)

**Must NOT do**:
- Create new ConnectionType values
- Change behavior for aux buses (21-28) or ES-5 buses (29-30)

**Parallelizable**: NO (depends on 10)

**References**:

**Pattern References**:
- `lib/core/routing/connection_discovery_service.dart:112-142` - Session-aware connection creation for hardware inputs
- `lib/core/routing/connection_discovery_service.dart:199-224` - `_createHardwareInputConnections()` helper to extend
- `lib/core/routing/connection_discovery_service.dart:257-258` - Hardware output port ID pattern: `hw_out_${busNumber - 12}`
- `lib/core/routing/bus_spec.dart:28` - `isPhysicalOutput(n)` returns true for 13-20

**Acceptance Criteria**:
- [x] Physical output buses (13-20) create hardware input connections for algorithm inputs
- [x] Connection source is `hw_out_{busNumber - 12}` (e.g., bus 15 → `hw_out_3`)
- [x] Connection type is `ConnectionType.hardwareInput`
- [x] Aux buses (21-28) and ES-5 buses (29-30) unchanged
- [x] `flutter test test/core/routing/physical_output_as_input_test.dart` → PASS
- [x] `flutter test` → All tests pass (no regressions)

**Commit**: YES
- Message: `feat(routing): support physical output buses as input sources`
- Files: `lib/core/routing/connection_discovery_service.dart`, `test/core/routing/physical_output_as_input_test.dart`
- Pre-commit: `flutter test`

---

### TODO 12: Integration Tests

**What to do**:
- Create `test/core/routing/saturator_routing_integration_test.dart`
- Test full flow: Create Saturator slot → `AlgorithmRouting.fromSlot()` → verify returns `SaturatorAlgorithmRouting`
- Test: Connection discovery creates expected connections for Saturator with input on physical output
- Test: Multi-channel Saturator with different widths works end-to-end

**Must NOT do**:
- Skip any edge cases identified in planning

**Parallelizable**: NO (depends on 11)

**References**:

**Pattern References**:
- `test/integration/es5_routing_integration_test.dart:22-90` - Integration test slot creation helpers
- `test/integration/es5_routing_integration_test.dart:332-370` - Full routing integration test pattern

**Test References**:
- `test/core/routing/clock_euclidean_es5_test.dart:217-251` - Combined routing + connection test

**Acceptance Criteria**:
- [ ] Integration test file created: `test/core/routing/saturator_routing_integration_test.dart`
- [ ] Tests verify `AlgorithmRouting.fromSlot()` returns `SaturatorAlgorithmRouting` for satu guid
- [ ] Tests verify connection discovery works with Saturator
- [ ] Tests cover mono (width=1), width>1, and multi-channel scenarios
- [ ] Tests verify physical output as input source with Saturator
- [ ] `flutter test test/core/routing/saturator_routing_integration_test.dart` → PASS

**Commit**: YES
- Message: `test(routing): add Saturator routing integration tests`
- Files: `test/core/routing/saturator_routing_integration_test.dart`
- Pre-commit: `flutter test`

---

### TODO 13: Final Verification

**What to do**:
- Run full test suite: `flutter test`
- Run analyzer: `flutter analyze`
- Verify no regressions in existing routing tests
- Review all new files for any missed guardrails (no debug logging, no UI changes)

**Must NOT do**:
- Add any new features not in the plan
- Skip verification steps

**Parallelizable**: NO (final task)

**References**:
- All files created/modified in this plan

**Acceptance Criteria**:
- [ ] `flutter analyze` → 0 issues
- [ ] `flutter test` → All tests pass
- [ ] No debug logging in new code
- [ ] No modifications to unrelated files

**Commit**: NO (verification only)

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 2 | `feat(routing): add SaturatorAlgorithmRouting.canHandle()` | saturator_algorithm_routing.dart, test file | flutter test (specific) |
| 4 | `feat(routing): add SaturatorAlgorithmRouting mono port generation` | saturator_algorithm_routing.dart, test file | flutter test (specific) |
| 6 | `feat(routing): add SaturatorAlgorithmRouting width-based port expansion` | saturator_algorithm_routing.dart, test file | flutter test (specific) |
| 8 | `feat(routing): add SaturatorAlgorithmRouting multi-channel support` | saturator_algorithm_routing.dart, test file | flutter test (specific) |
| 9 | `feat(routing): register SaturatorAlgorithmRouting in factory` | algorithm_routing.dart | flutter test (all) |
| 11 | `feat(routing): support physical output buses as input sources` | connection_discovery_service.dart, test file | flutter test (all) |
| 12 | `test(routing): add Saturator routing integration tests` | integration test file | flutter test (all) |

---

## Success Criteria

### Verification Commands
```bash
flutter analyze  # Expected: 0 issues
flutter test     # Expected: All tests pass
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent (no debug logging, no UI changes, width=0 not handled)
- [ ] All 7 commits made with passing tests
- [ ] Saturator algorithm shows virtual outputs in routing visualization
- [ ] Physical output as input source works for all algorithms (general feature)
