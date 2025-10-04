# Story ES5.007: Clock/Euclidean ES-5 Connections

## Status
Ready for Done

## Story
**As a** user of Clock or Euclidean algorithms with ES-5 expander,
**I want** direct output routing to ES-5 ports when ES-5 Expander is configured,
**so that** my clock and pattern signals bypass normal outputs and go directly to specific ES-5 expander ports.

## Acceptance Criteria
1. When ES-5 Expander = Off (0), normal Output parameter determines bus routing
2. When ES-5 Expander ≠ Off (1-6), Output parameter is completely ignored
3. When ES-5 active, ES-5 Output parameter (1-8) determines which ES-5 port receives signal
4. Clock algorithm channels correctly route to ES-5 ports when configured
5. Euclidean algorithm channels correctly route to ES-5 ports when configured
6. Visual connections show algorithm → ES-5 port with clear labeling

## Tasks / Subtasks
- [x] Create Clock Algorithm Routing Class (AC: 1, 2, 3, 4)
  - [x] Create lib/core/routing/clock_algorithm_routing.dart
  - [x] Extend MultiChannelAlgorithmRouting class
  - [x] Implement canHandle() method checking for guid='clck'
  - [x] Implement createFromSlot() factory method
  - [x] Add slot property to store algorithm data

- [x] Implement Clock Output Port Generation (AC: 1, 2, 3, 4)
  - [x] Override generateOutputPorts() method
  - [x] For each channel, check ES-5 Expander parameter value
  - [x] If ES-5 Expander > 0: create ES-5 direct output port
  - [x] If ES-5 Expander = 0: create normal output port using Output parameter
  - [x] Set busParam='es5_direct' for ES-5 outputs as marker
  - [x] Store ES-5 Output value in channelNumber property

- [x] Create Euclidean Algorithm Routing Class (AC: 1, 2, 3, 5)
  - [x] Create lib/core/routing/euclidean_algorithm_routing.dart
  - [x] Follow identical pattern as Clock routing
  - [x] Check for guid='eucp'
  - [x] Same ES-5 logic for output generation

- [x] Update Algorithm Routing Factory (AC: 4, 5)
  - [x] Modify lib/core/routing/algorithm_routing.dart
  - [x] In fromSlot() factory, add Clock check before fallback
  - [x] In fromSlot() factory, add Euclidean check before fallback
  - [x] Import new routing classes

- [x] Add ES-5 Direct Connection Discovery (AC: 3, 6)
  - [x] Modify connection_discovery_service.dart
  - [x] Create _createEs5DirectConnections() method
  - [x] Check for busParam='es5_direct' outputs
  - [x] Create connections to es5_${channelNumber} ports
  - [x] Add to discoverConnections() main method

- [x] Implement Parameter Helper Methods (AC: 1, 2, 3)
  - [x] Create _getChannelParameter() method
  - [x] Find parameter by name for specific channel
  - [x] Extract value from slot.values
  - [x] Handle missing parameters gracefully

## Dev Notes

### Relevant Source Tree
- `lib/core/routing/algorithm_routing.dart` - Factory to update
- `lib/core/routing/multi_channel_algorithm_routing.dart` - Base class to extend
- `lib/core/routing/connection_discovery_service.dart` - Connection logic
- New files: clock_algorithm_routing.dart, euclidean_algorithm_routing.dart

### Key Implementation Details
Clock/Euclidean Routing Logic:
```dart
@override
List<Port> generateOutputPorts() {
  final ports = <Port>[];

  for (int channel = 1; channel <= config.channelCount; channel++) {
    // Get ES-5 Expander value (0=Off, 1-6=Active)
    final es5ExpanderValue = _getChannelParameter(channel, 'ES-5 Expander');

    if (es5ExpanderValue != null && es5ExpanderValue > 0) {
      // ES-5 MODE: Ignore Output parameter completely
      final es5OutputValue = _getChannelParameter(channel, 'ES-5 Output') ?? channel;

      ports.add(Port(
        id: '${algorithmUuid}_channel_${channel}_es5_output',
        name: 'Ch$channel → ES-5 $es5OutputValue',
        type: PortType.gate,
        direction: PortDirection.output,
        description: 'Direct to ES-5 Output $es5OutputValue',
        busParam: 'es5_direct',  // Special marker
        channelNumber: es5OutputValue,  // ES-5 port number
      ));
    } else {
      // NORMAL MODE: Use Output parameter
      final outputBus = _getChannelParameter(channel, 'Output') ?? 0;

      if (outputBus > 0) {
        ports.add(Port(
          id: '${algorithmUuid}_channel_${channel}_output',
          name: 'Channel $channel',
          type: PortType.gate,
          direction: PortDirection.output,
          busValue: outputBus,
          // Standard output properties
        ));
      }
    }
  }

  return ports;
}
```

Parameter Access Pattern:
```dart
int? _getChannelParameter(int channel, String paramName) {
  // Find parameter in slot structure
  // Clock: May be in per-output pages
  // Euclidean: May be in per-channel pages
  // Return value or null if not found
}
```

Connection Discovery:
```dart
static List<Connection> _createEs5DirectConnections(
  AlgorithmRouting routing,
) {
  final connections = <Connection>[];

  for (final outputPort in routing.outputPorts) {
    if (outputPort.busParam == 'es5_direct' &&
        outputPort.channelNumber != null) {

      connections.add(
        Connection(
          id: 'conn_${outputPort.id}_to_es5_${outputPort.channelNumber}',
          sourcePortId: outputPort.id,
          destinationPortId: 'es5_${outputPort.channelNumber}',
          connectionType: ConnectionType.algorithmToAlgorithm,
          algorithmId: routing.algorithmUuid!,
          signalType: SignalType.gate,
        ),
      );
    }
  }

  return connections;
}
```

Critical Behavior:
- ES-5 Expander = 0 (Off) → Use normal Output parameter
- ES-5 Expander = 1-6 → COMPLETELY IGNORE Output parameter
- This is intentional - when ES-5 is active, the Output bus is bypassed
- Both algorithms follow identical pattern

### Testing Standards
- Unit test ES-5 vs normal routing logic
- Test parameter value extraction
- Test with missing parameters
- Integration test with actual Clock/Euclidean presets
- Verify Output parameter truly ignored when ES-5 active
- Visual inspection of connections in routing editor

## Change Log
| Date | Version | Description | Author |
|------|---------|-------------|--------|
| 2025-10-03 | 1.0 | Initial story creation | Bob (SM) |
| 2025-10-03 | 1.1 | Approved for development | Bob (SM) |
| 2025-10-04 | 1.2 | QA follow-up: Eliminated code duplication by creating Es5DirectOutputAlgorithmRouting base class | James (Dev) |

## Dev Agent Record

### Agent Model Used
claude-sonnet-4-5-20250929

### Implementation Notes
Successfully implemented ES-5 direct routing for Clock and Euclidean algorithms. Both algorithms now support two output modes:
1. Normal mode (ES-5 Expander = 0): Routes to standard output buses
2. ES-5 mode (ES-5 Expander > 0): Routes directly to ES-5 expander ports, completely bypassing Output parameter

Key implementation details:
- Created ClockAlgorithmRouting and EuclideanAlgorithmRouting classes extending MultiChannelAlgorithmRouting
- Both classes use identical pattern with different page name conventions (Clock: "Output N", Euclidean: "Channel N")
- Used busParam='es5_direct' marker for connection discovery service
- ES-5 Output value stored in Port.channelNumber property for routing to specific ES-5 ports
- Connection discovery creates direct connections to es5_${channelNumber} hardware nodes

### Completion Notes
- All acceptance criteria met and verified through unit tests
- flutter analyze: Zero warnings/errors
- All tests passing: 571 tests (10 new tests specifically for Clock/Euclidean ES-5 routing)
- Test coverage includes: normal mode, ES-5 mode, mixed mode, parameter extraction, connection discovery
- Code follows existing patterns from ES5EncoderAlgorithmRouting
- **QA Review Follow-up (2025-10-04):** Refactored to eliminate ~99% code duplication between Clock and Euclidean routing classes by creating Es5DirectOutputAlgorithmRouting base class. Reduced each class from 209 lines to 52 lines (75% reduction). All tests continue to pass.

### File List
**Created:**
- lib/core/routing/clock_algorithm_routing.dart
- lib/core/routing/euclidean_algorithm_routing.dart
- lib/core/routing/es5_direct_output_algorithm_routing.dart (QA follow-up: base class)
- test/core/routing/clock_euclidean_es5_test.dart

**Modified:**
- lib/core/routing/algorithm_routing.dart (added Clock and Euclidean to factory)
- lib/core/routing/connection_discovery_service.dart (added _createEs5DirectConnections method)
- lib/core/routing/clock_algorithm_routing.dart (QA follow-up: refactored to extend base class)
- lib/core/routing/euclidean_algorithm_routing.dart (QA follow-up: refactored to extend base class)

## QA Results

### Review Date: 2025-10-04

### Reviewed By: Quinn (Test Architect)

### Code Quality Assessment

Excellent implementation that successfully extends the ES-5 direct routing pattern to Clock and Euclidean algorithms. The code is clean, well-documented, and follows established patterns from ES5EncoderAlgorithmRouting. Key strengths:

- Proper OO design extending MultiChannelAlgorithmRouting base class
- Clear separation of concerns between routing logic and visualization
- Comprehensive use of debugPrint() throughout (coding standards compliant)
- Graceful error handling with null checks and appropriate fallbacks
- Good documentation explaining the dual-mode behavior (normal vs ES-5)

**Minor Observation:** There is ~99% code duplication between ClockAlgorithmRouting and EuclideanAlgorithmRouting classes. The only differences are class name, GUID check, and debug messages. This is acceptable given the existing codebase patterns, but could be refactored in future to use a shared base class or more generic implementation.

### Refactoring Performed

None. Code quality is high and no immediate refactoring was required.

### Compliance Check

- Coding Standards: ✓ (debugPrint used consistently, proper import ordering, good documentation)
- Project Structure: ✓ (follows lib/core/routing/ pattern, proper test location)
- Testing Strategy: ✓ (10 comprehensive tests covering all modes and edge cases)
- All ACs Met: ✓ (all 6 acceptance criteria validated through tests and code review)

### Requirements Traceability

| AC | Requirement | Test Coverage | Status |
|----|------------|---------------|--------|
| 1 | ES-5 Expander = Off → use Output parameter | "creates normal output ports using Output parameter" + connection tests | ✓ COVERED |
| 2 | ES-5 Expander ≠ Off → ignore Output parameter | "Output parameter is completely ignored when ES-5 active" | ✓ COVERED |
| 3 | ES-5 Output parameter determines ES-5 port | "uses ES-5 Output parameter to determine ES-5 port" | ✓ COVERED |
| 4 | Clock channels route to ES-5 correctly | All Clock test groups (normal, ES-5, mixed modes) | ✓ COVERED |
| 5 | Euclidean channels route to ES-5 correctly | "follows identical pattern as Clock" + ES-5 connection tests | ✓ COVERED |
| 6 | Visual connections clearly labeled | Port naming verified: 'Ch$channel → ES-5 $es5OutputValue' | ✓ COVERED |

### Test Architecture Assessment

**Coverage:** Excellent - 10 new tests providing full coverage of:
- Normal mode (ES-5 Expander = 0) with Output parameter routing
- ES-5 mode (ES-5 Expander > 0) with direct ES-5 routing
- Mixed mode (some channels normal, some ES-5)
- Output parameter correctly ignored when ES-5 active
- ES-5 Output parameter determining correct ES-5 port
- Connection discovery for both normal and ES-5 modes
- Edge cases (Output=0, missing parameters)

**Test Quality:** High
- Descriptive test names following behavioral patterns
- Good use of test helpers to reduce duplication
- Tests validate both positive and negative scenarios
- Edge cases properly covered

**Test Execution:** All 10 tests passing, zero failures

### Improvements Checklist

- [x] Verified coding standards compliance (debugPrint usage, imports)
- [x] Confirmed test coverage for all acceptance criteria
- [x] Validated error handling and null safety
- [x] Reviewed connection discovery integration
- [x] Consider creating base class to eliminate Clock/Euclidean duplication (completed 2025-10-04)

### Security Review

✓ PASS - No security concerns. This is routing visualization logic with no auth, data persistence, or external communications.

### Performance Considerations

✓ PASS - Efficient implementation using:
- Direct parameter lookups (O(n) for channel parameters)
- Proper iteration patterns
- No unnecessary allocations
- Follows same performance profile as existing routing classes

### Files Modified During Review

**QA Follow-up (2025-10-04):**
- Created: lib/core/routing/es5_direct_output_algorithm_routing.dart (base class for ES-5 direct output algorithms)
- Refactored: lib/core/routing/clock_algorithm_routing.dart (now extends Es5DirectOutputAlgorithmRouting)
- Refactored: lib/core/routing/euclidean_algorithm_routing.dart (now extends Es5DirectOutputAlgorithmRouting)

### Gate Status

Gate: PASS → docs/qa/gates/ES5.007-clock-euclidean-connections.yml
Quality Score: 90/100

### Recommended Status

✓ Ready for Done

Code is production-ready with excellent test coverage. Minor code duplication between Clock and Euclidean classes is acceptable technical debt given existing codebase patterns. Consider refactoring to shared base class in future cleanup sprint.
