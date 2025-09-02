# Spec Tasks

## Tasks

- [ ] 1. Add OutputMode enum and enhance Port model
  - [ ] 1.1 Write tests for OutputMode enum and Port model changes
  - [ ] 1.2 Define OutputMode enum in models/port.dart
  - [ ] 1.3 Add optional outputMode field to Port model
  - [ ] 1.4 Update Port factory constructors and JSON serialization
  - [ ] 1.5 Verify all tests pass

- [ ] 2. Implement mode parameter extraction (parallel to ioParameter pattern)
  - [ ] 2.1 Write tests for extractModeParameters() method
  - [ ] 2.2 Create extractModeParameters() method mirroring extractIOParameters() pattern
  - [ ] 2.3 Update AlgorithmRouting.fromSlot() to call both extraction methods
  - [ ] 2.4 Pass both parameter maps to subclass factory methods
  - [ ] 2.5 Add inline documentation explaining the parallel pattern
  - [ ] 2.6 Verify all tests pass

- [ ] 3. Integrate mode parameters into routing subclasses
  - [ ] 3.1 Write tests for PolyAlgorithmRouting mode parameter handling
  - [ ] 3.2 Update PolyAlgorithmRouting.createFromSlot() to accept modeParameters
  - [ ] 3.3 Apply OutputMode to generated output ports in PolyAlgorithmRouting
  - [ ] 3.4 Update MultiChannelAlgorithmRouting.createFromSlot() similarly
  - [ ] 3.5 Apply OutputMode to generated output ports in MultiChannelAlgorithmRouting
  - [ ] 3.6 Verify all tests pass

- [ ] 4. Enhance label formatting system
  - [ ] 4.1 Write tests for BusLabelFormatter mode-aware formatting
  - [ ] 4.2 Add formatBusLabelWithMode() method to BusLabelFormatter
  - [ ] 4.3 Extend ConnectionData to include OutputMode from source port
  - [ ] 4.4 Update ConnectionPainter to use mode-aware formatting
  - [ ] 4.5 Test visual output shows "R" suffix for replace mode
  - [ ] 4.6 Verify all tests pass

- [ ] 5. End-to-end validation
  - [ ] 5.1 Test with algorithm having output mode parameters
  - [ ] 5.2 Verify labels update when mode parameter changes
  - [ ] 5.3 Confirm "O1 R" format displays correctly in UI
  - [ ] 5.4 Run full test suite and fix any regressions