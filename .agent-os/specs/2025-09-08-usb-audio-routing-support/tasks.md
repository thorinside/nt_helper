# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-09-08-usb-audio-routing-support/spec.md

> Created: 2025-09-08
> Status: Ready for Implementation

## Tasks

- [ ] 1. Remove fallback port generation
  - [ ] 1.1 Write tests for algorithms with no ports being excluded from routing
  - [ ] 1.2 Locate and remove "Main 1" fallback port generation code in AlgorithmRouting base class
  - [ ] 1.3 Update RoutingEditorCubit to filter out algorithms with no ports
  - [ ] 1.4 Verify 'note' algorithm no longer appears in routing visualization
  - [ ] 1.5 Verify all tests pass

- [ ] 2. Implement UsbFromAlgorithmRouting class
  - [ ] 2.1 Write tests for UsbFromAlgorithmRouting port extraction
  - [ ] 2.2 Create UsbFromAlgorithmRouting class extending AlgorithmRouting
  - [ ] 2.3 Implement extractPorts() to extract 8 outputs from 'to' parameters
  - [ ] 2.4 Add support for extended bus value range (0-30) and ES-5 destinations
  - [ ] 2.5 Include mode (Add/Replace) extraction from parameters 9-16
  - [ ] 2.6 Verify all tests pass

- [ ] 3. Integrate UsbFromAlgorithmRouting into factory
  - [ ] 3.1 Write tests for factory method detecting 'usbf' GUID
  - [ ] 3.2 Update AlgorithmRouting.fromSlot() factory to detect 'usbf' GUID
  - [ ] 3.3 Return UsbFromAlgorithmRouting instance for USB Audio algorithms
  - [ ] 3.4 Verify USB Audio algorithm displays correctly in routing editor
  - [ ] 3.5 Verify all tests pass

- [ ] 4. Update ConnectionDiscoveryService for extended bus values
  - [ ] 4.1 Write tests for ES-5 L/R bus value handling (29-30)
  - [ ] 4.2 Update ConnectionDiscoveryService to handle bus values 29-30
  - [ ] 4.3 Verify connections to ES-5 destinations are properly discovered
  - [ ] 4.4 Verify all tests pass

- [ ] 5. End-to-end verification
  - [ ] 5.1 Test USB Audio algorithm with all 8 channels configured
  - [ ] 5.2 Verify ES-5 L/R destinations display correctly
  - [ ] 5.3 Verify no fallback ports appear anywhere
  - [ ] 5.4 Run flutter analyze and ensure zero warnings
  - [ ] 5.5 Verify all tests pass