# Physical I/O Node Redesign - Lite Summary

Create a universal port_widget with 24px circular ports and configurable label positioning used by both algorithm nodes and physical I/O nodes for complete routing system design unification. Input nodes (I1-I12) will have left-positioned labels, output nodes (O1-O8) will have right-positioned labels, using 24px spacing and 16px content margins. Remove JackConnectionWidget and simplify for future connection dragging implementation.

## Key Points
- Universal port_widget used by both algorithm nodes and physical I/O nodes
- Complete routing system design unification with consistent Material Design styling
- Physical I/O: Input nodes (I1-I12) labels left, Output nodes (O1-O8) labels right  
- Algorithm nodes: Use port_widget with appropriate label positioning for inputs/outputs
- 24px vertical spacing with 16px margin around entire content area
- Global coordinate reporting for connection line anchoring to port centers
- Maintain stable port IDs (hw_in_X/hw_out_X for physical, existing format for algorithm)