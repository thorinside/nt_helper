# Routing Special Cases Documentation

This document describes special cases in the routing system for the Disting NT helper application.

## 1. Width-Aware Algorithms (Multi-Channel Connections)

### Overview
Some algorithms support multiple channel widths (mono, stereo, multi-channel). When connecting to these algorithms, the system automatically handles the appropriate number of bus assignments.

### Detection
Algorithms with a "Width", "Channels", or "Channel Count" parameter are considered width-aware.

### Connection Rules

#### Width=2 (Stereo) Connections
- When connecting to a stereo algorithm (width=2):
  - Two consecutive buses are automatically assigned
  - Bus N → Input L (channel 1)
  - Bus N+1 → Input R (channel 2)
  - Both connections are created atomically

#### Width Mismatch Handling
- **Mono → Stereo**: Mono signal is duplicated to both channels
- **Stereo → Mono**: Only the first channel is used (with potential warning)
- **Multi → Different Multi**: Channels are matched up to the minimum available

#### Bus Assignment Strategy
- Consecutive buses are reserved for multi-channel connections
- Preference order:
  1. Aux buses (21-28) for internal routing
  2. Output buses (13-20) if aux buses unavailable
  3. Input buses (1-12) as last resort
- Validation ensures sufficient consecutive buses are available before connection

### Visual Representation
- Multi-channel connections show multiple connection lines
- Channel labels:
  - Stereo: L/R suffixes
  - Multi-channel: Numeric suffixes (1, 2, 3...)
- Edge labels indicate bus and channel (e.g., "A1 A L", "A2 A R")

### Example: VCF Stereo Connection
```
Source (Mono Oscillator) → VCF (Width=2)
Result:
- Bus 21: Oscillator Output → VCF Input L
- Bus 22: Oscillator Output → VCF Input R
```

## 2. Feedback Loop Handling

### Overview
Feedback Send/Receive pairs create "teleport tunnels" using identifier parameters instead of bus routing.

### Rules
1. Feedback Receive must be in an earlier slot than Feedback Send
2. Matching identifiers link the pair
3. Channel count must match between Send and Receive
4. Default safety gain of -40dB prevents runaway feedback

### Connection Process
1. Validate slot ordering (Receive before Send)
2. Set matching identifier parameters
3. Configure channel count
4. Apply safety gain settings

## 3. Physical I/O Connections

### Fixed Bus Assignments
- **Physical Inputs (I1-I12)**: Use buses 1-12
- **Physical Outputs (O1-O8)**: Use buses 13-20
- These assignments are fixed and cannot be changed

### Bidirectional Support
- Physical inputs can be sources or targets
- Physical outputs can be sources or targets
- Appropriate fixed bus is used based on the physical port

## 4. Modulation Routing

### Ordering Constraints
- Modulation sources must be in earlier slots than targets
- This ensures proper signal flow in the processing chain

### Connection Validation
- System validates slot ordering before allowing modulation connections
- Invalid orderings are rejected with appropriate error messages

## 5. Poly Algorithm Connections

### Gate + CV Pattern
Poly algorithms use a special pattern:
- Gate input parameter controls the gate bus
- CV count parameter determines number of CV inputs
- When gate is connected, CV ports are dynamically created

### Port Generation
For each active gate:
1. Create gate input port
2. Create N CV input ports based on CV count parameter
3. All ports are available for connection

## 6. Bus Optimization and Tidying

### Automatic Optimization
The system can automatically optimize bus usage to:
- Free up auxiliary buses
- Reduce total bus count
- Consolidate connections sharing the same source

### Tidy Rules
1. Connections from the same source can share a bus
2. Physical I/O buses are never reassigned
3. Feedback pairs are excluded from optimization
4. Processing order is maintained

## 7. Connection Modes

### Replace Mode (R)
- New signal replaces existing bus content
- Default for most connections

### Add Mode (A)
- New signal is mixed with existing bus content
- Used for feedback algorithms and mixing scenarios
- Unity gain mixing prevents clipping

## 8. Error Handling

### Insufficient Buses
- System validates bus availability before connection
- Multi-channel connections require consecutive buses
- Clear error message when buses exhausted

### Circular Dependencies
- System detects and prevents circular signal paths
- Topological sorting ensures valid processing order

### Connection Conflicts
- Target ports can only have one input connection
- Existing connections are replaced or user is warned
- Source ports can feed multiple targets

## Implementation Notes

### Atomic Operations
- Multi-channel connections are created/removed atomically
- All channels succeed or all fail together
- Prevents partial connection states

### Optimistic Updates
- Visual state updates immediately on user action
- Hardware updates happen asynchronously
- Rollback on failure maintains consistency

### Parameter Updates
- Width-aware algorithms use base bus parameter
- Hardware interprets base bus as starting point for consecutive buses
- Individual channel parameters not directly exposed

## Testing Considerations

### Width-Aware Algorithm Tests
- Test mono to stereo expansion
- Test stereo to mono reduction  
- Test consecutive bus allocation
- Test bus exhaustion scenarios

### Connection Validation Tests
- Test circular dependency detection
- Test modulation ordering constraints
- Test physical I/O fixed assignments

### Visual State Tests
- Test multi-channel visual representation
- Test connection preview for width-aware targets
- Test atomic update/rollback behavior