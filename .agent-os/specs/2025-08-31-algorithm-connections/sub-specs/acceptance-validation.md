# Acceptance Validation Criteria

## Connection Discovery Validation

### Test Case 1: Basic Connection Discovery
**Setup**: Load preset with 2 algorithms, Algorithm 0 output on bus 15, Algorithm 1 input on bus 15
**Expected**: Single connection displayed from Algo 0 → Algo 1
**Pass Criteria**: Connection visible, labeled "Bus 15"

### Test Case 2: Multiple Bus Connections
**Setup**: Load preset with 3 algorithms sharing buses 5, 10, 15
**Expected**: All matching bus connections displayed
**Pass Criteria**: Each unique bus match creates exactly one connection

### Test Case 3: Maximum Slot Configuration
**Setup**: Load preset with 32 algorithms, various bus connections
**Expected**: All connections discovered and rendered
**Pass Criteria**: Performance remains acceptable (< 200ms render time)

### Test Case 4: No Connections
**Setup**: Load preset with algorithms using unique buses
**Expected**: No algorithm connections shown
**Pass Criteria**: Only physical connections visible

## Execution Order Validation

### Test Case 5: Valid Execution Order
**Setup**: Algorithm 5 output → Algorithm 10 input (same bus)
**Expected**: Connection shown in normal color
**Pass Criteria**: Connection color follows the source output port type color

### Test Case 6: Invalid Execution Order
**Setup**: Algorithm 10 output → Algorithm 5 input (same bus)
**Expected**: Connection shown in red with dashed line
**Pass Criteria**: Connection clearly marked as invalid

### Test Case 7: Self-Connection
**Setup**: Algorithm 5 output and input on same bus
**Expected**: No connection shown
**Pass Criteria**: Self-connections excluded

## Bus Type Validation

### Test Case 8: Input Bus Connections (1-12)
**Setup**: Algorithms connected via bus 5 (input range)
**Expected**: Connection labeled as input bus type
**Pass Criteria**: Correct color/styling for input bus

### Test Case 9: Output Bus Connections (13-20)
**Setup**: Algorithms connected via bus 15 (output range)
**Expected**: Connection labeled as output bus type
**Pass Criteria**: Correct color/styling (output-port type color, solid line)

### Test Case 10: AUX Bus Connections (21-28)
**Setup**: Algorithms connected via bus 25 (aux range)
**Expected**: Connection labeled as aux bus type
**Pass Criteria**: Correct handling (treated as internal; color still follows output port)

## Real-time Update Validation

### Test Case 11: Parameter Change Updates
**Setup**: Change algorithm output bus from 10 to 15
**Expected**: Connection updates immediately
**Pass Criteria**: Update occurs within 100ms

### Test Case 12: Algorithm Removal
**Setup**: Remove algorithm from slot
**Expected**: All connections to/from that algorithm disappear
**Pass Criteria**: Canvas updates correctly

### Test Case 13: Bus Unassignment
**Setup**: Change bus from 15 to 0 (None)
**Expected**: Connection removed
**Pass Criteria**: No ghost connections remain

## Visual Clarity Validation

### Test Case 14: Connection Distinction
**Setup**: Mix of valid and invalid connections
**Expected**: Clear visual difference
**Pass Criteria**: Red/dashed for invalid, colored/solid for valid

### Test Case 15: Bus Label Visibility
**Setup**: Connections at various angles and lengths
**Expected**: All bus labels readable
**Pass Criteria**: Labels don't overlap, remain visible

### Test Case 16: Complex Routing
**Setup**: 10+ algorithms with 20+ connections
**Expected**: Connections remain distinguishable
**Pass Criteria**: No visual artifacts, maintains clarity

## Performance Validation

### Test Case 17: Preset Switching Speed
**Setup**: Switch between complex presets
**Expected**: Fast rendering
**Pass Criteria**: < 200ms to display all connections

### Test Case 18: Continuous Updates (Non-gating)
**Setup**: Rapidly change parameters
**Expected**: Smooth updates
**Pass Criteria**: Smooth updates during normal interaction

### Test Case 19: Memory Stability
**Setup**: Switch presets 100 times
**Expected**: No memory leaks
**Pass Criteria**: Memory usage stable (< 10MB increase)

## Integration Validation

### Test Case 20: Physical Connection Coexistence
**Setup**: Preset with both physical and algorithm connections
**Expected**: Both types visible, no duplication
**Pass Criteria**: Clear distinction between connection types

### Test Case 21: Existing Features
**Setup**: Use all existing routing features
**Expected**: No regressions
**Pass Criteria**: All previous functionality intact

### Test Case 22: State Persistence (Derived)
**Setup**: Save and reload routing state
**Expected**: Algorithm connections recomputed on load
**Pass Criteria**: Derived connections match the recomputed state after reload

## Edge Case Validation

### Test Case 23: Boundary Values
**Setup**: Use bus 1, 28, and 0
**Expected**: Correct handling
**Pass Criteria**: Bus 1 and 28 work, bus 0 creates no connection

### Test Case 24: Rapid Slot Changes
**Setup**: Quickly add/remove algorithms
**Expected**: Stable behavior
**Pass Criteria**: No crashes or visual glitches

### Test Case 25: Feedback Algorithm
**Setup**: Use Feedback Send/Receive algorithms
**Expected**: Normal connection rules apply
**Pass Criteria**: No special handling needed

## Validation Summary

| Category | Tests | Pass Criteria |
|----------|-------|---------------|
| Discovery | 1-4 | All connections found correctly |
| Execution Order | 5-7 | Invalid connections marked properly |
| Bus Types | 8-10 | Correct bus type identification |
| Real-time Updates | 11-13 | Updates within 100ms |
| Visual Clarity | 14-16 | Clear, distinguishable connections |
| Performance | 17-19 | < 200ms render, 60fps, stable memory |
| Integration | 20-22 | No regressions, proper coexistence |
| Edge Cases | 23-25 | Robust handling of boundaries |

## Automated Validation Script

```dart
// Example validation test structure
void runAcceptanceTests() {
  group('Algorithm Connection Acceptance Tests', () {
    test('Basic Connection Discovery', () async {
      // Load test preset
      final preset = loadTestPreset('two_algorithms_connected.json');
      await cubit.loadPreset(preset);
      
      // Verify connection
      final state = cubit.state as RoutingEditorStateLoaded;
      expect(state.algorithmConnections, hasLength(1));
      expect(state.algorithmConnections.first.busNumber, equals(15));
    });
    
    // Additional tests...
  });
}
```

## Manual Testing Protocol

1. **Setup Test Environment**
   - Load NT Helper with test presets
   - Enable debug visualization if available
   - Prepare performance monitoring

2. **Execute Test Suite**
   - Run through each test case systematically
   - Document any deviations
   - Capture screenshots for visual tests

3. **Performance Profiling**
   - Use Flutter DevTools
   - Monitor frame rendering
   - Check memory allocation

4. **User Experience Review**
   - Have non-developer test the feature
   - Gather feedback on clarity
   - Identify any confusion points

## Sign-off Requirements

- [ ] All 25 test cases pass
- [ ] Performance metrics met
- [ ] No regressions identified
- [ ] Visual clarity confirmed
- [ ] Documentation complete
- [ ] Code review approved
