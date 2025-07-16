# Routing Concepts for Disting NT

## Signal Flow Fundamentals

### Processing Order
- Algorithms execute in slot order: Slot 0 → Slot 1 → ... → Slot N
- **Earlier slots** process signals before later slots
- **Modulation sources** must be in earlier slots than their targets

### Input/Output Behavior
- **Inputs**: Algorithms read from assigned input buses
- **Outputs**: Algorithms write to assigned output buses  
- **Signal Replacement**: When multiple algorithms output to the same bus, later slots replace earlier signals
- **Signal Combination**: Some algorithms can combine/mix signals rather than replace

### Bus Assignment Patterns
- **Audio Processing**: Often Input 1,2 → Output 1,2
- **CV Generation**: Often None → Output N (generating new CV signals)
- **CV Processing**: Often Input N → Output N (processing incoming CV)
- **Mixing**: Multiple inputs → Single output
- **Splitting**: Single input → Multiple outputs

### Routing Visualization
Use `get_routing` to see:
- Which buses each algorithm reads from (inputs)
- Which buses each algorithm writes to (outputs)
- Signal flow through the entire preset

### Common Routing Patterns
1. **Audio Chain**: Input 1,2 → Filter → Reverb → Output 1,2
2. **CV Modulation**: LFO (None → Output 3) → VCA CV Input (Input 3)
3. **Parallel Processing**: Input 1 → [Delay, Chorus] → Mixer → Output 1
4. **Feedback Loops**: Output bus routed back as input to earlier slot

### Troubleshooting Routing
- **No sound**: Check input/output bus assignments
- **Unexpected behavior**: Verify algorithm processing order
- **Missing modulation**: Ensure modulation source is in earlier slot
- **Signal conflicts**: Check for multiple algorithms writing to same bus