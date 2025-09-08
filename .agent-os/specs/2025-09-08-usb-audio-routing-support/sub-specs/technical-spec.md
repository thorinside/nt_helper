# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-08-usb-audio-routing-support/spec.md

> Created: 2025-09-08
> Version: 1.0.0

## Technical Requirements

### UsbFromAlgorithmRouting Implementation

- Create new class `UsbFromAlgorithmRouting` extending `AlgorithmRouting` in `lib/core/routing/`
- Override `extractPorts()` method to handle the unique parameter structure:
  - No input ports (algorithm has no inputs)
  - 8 output ports extracted from parameters 1-8 (the 'to' parameters)
  - Port names derived from parameter pages: "USB Channel 1" through "USB Channel 8"
  - Each port includes the bus value from the corresponding 'to' parameter
  - Port mode (Add/Replace) extracted from corresponding 'mode' parameters (9-16)

### Bus Value Handling

- Support extended enum value range (0-30 instead of standard 0-28)
- Preserve original enum value strings without conversion:
  - "None", "Input 1-12", "Output 1-8", "Aux 1-8" 
  - "ES-5 L" and "ES-5 R" (keep verbatim, no conversion to shorthand)
- Map enum index directly to bus value for connection discovery

### Factory Method Integration

- Update `AlgorithmRouting.fromSlot()` factory method to detect 'usbf' GUID
- Return `UsbFromAlgorithmRouting` instance when algorithm GUID is 'usbf'
- Ensure factory method passes full Slot data including all parameters

### Port Model Properties

- Use direct Port properties for USB audio specific data:
  - `busValue`: The destination bus (0-30)
  - `busParam`: Set to channel name (e.g., "USB Channel 1")
  - `parameterNumber`: The corresponding 'to' parameter number (1-8)
  - `isReplaceMode`: Boolean derived from mode parameter (true if Replace, false if Add)

### Connection Discovery Compatibility

- Ensure ConnectionDiscoveryService handles bus values 29-30 (ES-5 L/R)
- These special buses should create connections but may need special handling in visualization
- Maintain compatibility with existing bus-based discovery for values 1-28

### Fallback Port Removal and Empty Node Handling

- Remove any code that automatically generates fallback ports when no ports are found
- Specifically eliminate generation of:
  - "Main 1 Audio Out" fallback output port
  - "Main 1 CV Out" fallback output port  
  - "Main 1 Audio In" fallback input port
  - "Main 1 CV In" fallback input port
- Allow `extractPorts()` to return empty lists for inputs and/or outputs
- Filter out algorithms with no ports from routing visualization:
  - Check if both input and output port lists are empty
  - Exclude these algorithms from `RoutingEditorCubit` state
  - This handles cases like the 'note' algorithm which has no routing purpose
- Update any base class methods that enforce minimum port requirements

## Approach

The implementation follows the existing OO routing framework patterns:

1. **Class Structure**: Extend `AlgorithmRouting` base class with USB-specific logic
2. **Port Extraction**: Override `extractPorts()` to handle 8 output-only ports from parameters
3. **Factory Integration**: Add detection logic in `AlgorithmRouting.fromSlot()` for 'usbf' GUID
4. **Bus Compatibility**: Extend bus value handling to support ES-5 outputs (29-30)

## External Dependencies

- Existing `AlgorithmRouting` base class
- `ConnectionDiscoveryService` for automatic connection discovery
- Port model with direct properties for type-safe access
- Factory method pattern in `AlgorithmRouting.fromSlot()`