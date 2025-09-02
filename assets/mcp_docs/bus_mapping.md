# Bus Mapping Reference

## IO to Bus Conversion Rules

The Disting NT uses a bus-based internal routing system. Physical inputs/outputs map to internal buses as follows:

### Mapping Rules
- **Input N** = Bus N (e.g., Input 1 = Bus 1, Input 2 = Bus 2)
- **Output N** = Bus N+12 (e.g., Output 1 = Bus 13, Output 2 = Bus 14)  
- **Aux N** = Bus N+20 (e.g., Aux 1 = Bus 21, Aux 2 = Bus 22)
- **None** = Bus 0 (used for unused/disconnected signals)

### Bus Range Summary
- **Bus 0**: None/unused
- **Buses 1-12**: Physical inputs (Input 1-12)
- **Buses 13-20**: Physical outputs (Output 1-8) - Current implementation
- **Buses 13-24**: Physical outputs (Output 1-12) - Hardware capability  
- **Buses 21-28**: Aux inputs/outputs (Aux 1-8)

### Important Notes
- Always use physical names (Input N, Output N, Aux N) when communicating with users
- Bus numbers are internal implementation details and should not be exposed to users
- **UI Implementation**: Current routing editor displays outputs 1-8 (buses 13-20); hardware supports up to outputs 1-12 (buses 13-24)
- Use the `get_routing` tool to see current bus assignments for loaded algorithms