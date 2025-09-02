# Spec Tasks

## Tasks

- [x] 1. Add OutputMode enum and enhance Port model
  - [x] 1.1 Write tests for OutputMode enum and Port model changes
  - [x] 1.2 Define OutputMode enum in models/port.dart
  - [x] 1.3 Add optional outputMode field to Port model
  - [x] 1.4 Update Port factory constructors and JSON serialization
  - [x] 1.5 Verify all tests pass

- [x] 2. Implement mode parameter extraction (parallel to ioParameter pattern)
  - [x] 2.1 Write tests for extractModeParameters() method
  - [x] 2.2 Create extractModeParameters() method mirroring extractIOParameters() pattern
  - [x] 2.3 Update AlgorithmRouting.fromSlot() to call both extraction methods
  - [x] 2.4 Pass both parameter maps to subclass factory methods
  - [x] 2.5 Add inline documentation explaining the parallel pattern
  - [x] 2.6 Verify all tests pass

- [x] 3. Integrate mode parameters into routing subclasses
  - [x] 3.1 Write tests for PolyAlgorithmRouting mode parameter handling
  - [x] 3.2 Update PolyAlgorithmRouting.createFromSlot() to accept modeParameters
  - [x] 3.3 Apply OutputMode to generated output ports in PolyAlgorithmRouting
  - [x] 3.4 Update MultiChannelAlgorithmRouting.createFromSlot() similarly
  - [x] 3.5 Apply OutputMode to generated output ports in MultiChannelAlgorithmRouting
  - [x] 3.6 Verify all tests pass

- [x] 4. Enhance label formatting system
  - [x] 4.1 Write tests for BusLabelFormatter mode-aware formatting
  - [x] 4.2 Add formatBusLabelWithMode() method to BusLabelFormatter
  - [x] 4.3 Extend ConnectionData to include OutputMode from source port
  - [x] 4.4 Update ConnectionPainter to use mode-aware formatting
  - [x] 4.5 Test visual output shows "R" suffix for replace mode
  - [x] 4.6 Verify all tests pass

- [x] 5. End-to-end validation
  - [x] 5.1 Test with algorithm having output mode parameters
  - [x] 5.2 Verify labels update when mode parameter changes
  - [x] 5.3 Confirm "O1 R" format displays correctly in UI
  - [x] 5.4 Run full test suite and fix any regressions