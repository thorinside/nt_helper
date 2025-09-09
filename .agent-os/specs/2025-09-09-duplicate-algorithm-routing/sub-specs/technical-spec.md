# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-09-duplicate-algorithm-routing/spec.md

## Technical Requirements

- Add `algorithmUuid` field to the `AlgorithmRouting` abstract base class to store the stable ID
- Store the `algorithmUuid` parameter in the `AlgorithmRouting.fromSlot()` factory method (already being passed but not stored)
- Modify `ConnectionDiscoveryService._extractAlgorithmId()` to return the stored `algorithmUuid` instead of using `routing.hashCode` as fallback
- Verify all routing implementations (PolyAlgorithmRouting, MultiChannelAlgorithmRouting, UsbFromAlgorithmRouting) use the stable UUID when generating port IDs
- Write a failing test first that reproduces the duplicate algorithm bug before implementing the fix (red-green test strategy)
- Ensure port ID generation in all routing implementations incorporates the stable algorithm UUID for consistency

## Implementation Details

### Current Problem (Line 275 in connection_discovery_service.dart)
```dart
// Fallback
return 'algo_${routing.hashCode}';  // Unstable, causes duplicate algorithm issues
```

### Solution
```dart
// Use stable ID stored in routing instance
return routing.algorithmUuid ?? 'algo_${routing.hashCode}';  // Fallback only if UUID not set
```

## Performance Criteria

- Connection discovery should complete in under 100ms for presets with up to 8 duplicate algorithm instances
- No observable UI freezing when switching between presets with duplicate algorithms
- Stable IDs must remain consistent across preset reloads to prevent UI flickering