# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-09-08-usb-audio-routing-support/spec.md

> Created: 2025-09-08
> Status: Ready for Implementation

## Tasks

- [x] 1. Remove fallback port generation
  - [x] 1.1 Write tests for algorithms with no ports being excluded from routing
  - [x] 1.2 Locate and remove "Main 1" fallback port generation code in AlgorithmRouting base class
  - [x] 1.3 Update RoutingEditorCubit to filter out algorithms with no ports
  - [x] 1.4 Verify 'note' algorithm no longer appears in routing visualization
  - [x] 1.5 Verify all tests pass

- [x] 2. Implement UsbFromAlgorithmRouting class
  - [x] 2.1 Write tests for UsbFromAlgorithmRouting port extraction
  - [x] 2.2 Create UsbFromAlgorithmRouting class extending AlgorithmRouting
  - [x] 2.3 Implement extractPorts() to extract 8 outputs from 'to' parameters
  - [x] 2.4 Add support for extended bus value range (0-30) and ES-5 destinations
  - [x] 2.5 Include mode (Add/Replace) extraction from parameters 9-16
  - [x] 2.6 Verify all tests pass

- [x] 3. Integrate UsbFromAlgorithmRouting into factory
  - [x] 3.1 Write tests for factory method detecting 'usbf' GUID
  - [x] 3.2 Update AlgorithmRouting.fromSlot() factory to detect 'usbf' GUID
  - [x] 3.3 Return UsbFromAlgorithmRouting instance for USB Audio algorithms
  - [x] 3.4 Verify USB Audio algorithm displays correctly in routing editor
  - [x] 3.5 Verify all tests pass

- [x] 4. Update ConnectionDiscoveryService for extended bus values
  - [x] 4.1 Write tests for ES-5 L/R bus value handling (29-30)
  - [x] 4.2 Update ConnectionDiscoveryService to handle bus values 29-30
  - [x] 4.3 Verify connections to ES-5 destinations are properly discovered
  - [x] 4.4 Verify all tests pass

- [x] 5. End-to-end verification
  - [x] 5.1 Test USB Audio algorithm with all 8 channels configured
  - [x] 5.2 Verify ES-5 L/R destinations display correctly
  - [x] 5.3 Verify no fallback ports appear anywhere
  - [x] 5.4 Run flutter analyze and ensure zero warnings
  - [x] 5.5 Verify all tests pass