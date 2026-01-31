# Saturator Routing Implementation Decisions

## [2026-01-17T05:30:00Z] Physical Output as Input Source

### Decision
Made physical output buses (13-20) available as input sources for ALL algorithms, not just Saturator.

### Rationale
- This is a general hardware capability that benefits all algorithms
- Saturator was the motivating use case, but the feature is universally applicable
- Implemented in `ConnectionDiscoveryService` as a general feature

### Implementation
- Added `_createPhysicalOutputAsInputConnections()` helper method
- Uses same `ConnectionType.hardwareInput` as physical input buses (1-12)
- Maps bus 13 → `hw_out_1`, bus 14 → `hw_out_2`, ..., bus 20 → `hw_out_8`
- Aux buses (21-28) and ES-5 buses (29-30) remain unchanged

### Impact
- Any algorithm can now read from physical output buses
- Enables feedback loops and complex routing scenarios
- No breaking changes to existing functionality
