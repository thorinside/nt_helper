# Spec Tasks

## Tasks

- [x] 1. Write Failing Test for Duplicate Algorithm Bug (Red Phase)
  - [x] 1.1 Create test file for ConnectionDiscoveryService with duplicate algorithms
  - [x] 1.2 Set up test preset with two slots using the same algorithm GUID
  - [x] 1.3 Create AlgorithmRouting instances with stable IDs for both slots
  - [x] 1.4 Test that connection discovery currently fails due to hashCode fallback
  - [x] 1.5 Verify test fails and reproduces the "Initializing routing editor..." issue

- [x] 2. Add Stable ID Storage to AlgorithmRouting
  - [x] 2.1 Add `algorithmUuid` field to AlgorithmRouting abstract base class
  - [x] 2.2 Update AlgorithmRouting.fromSlot() to store the algorithmUuid parameter
  - [x] 2.3 Update all routing subclasses to pass algorithmUuid to super constructor
  - [x] 2.4 Run tests to ensure no regressions

- [x] 3. Fix ConnectionDiscoveryService ID Extraction
  - [x] 3.1 Modify _extractAlgorithmId() to use routing.algorithmUuid first
  - [x] 3.2 Keep hashCode as fallback only for backward compatibility
  - [x] 3.3 Verify the failing test from Task 1 now passes (Green Phase)
  - [x] 3.4 Run all ConnectionDiscoveryService tests

- [x] 4. Verify Port ID Generation Uses Stable IDs
  - [x] 4.1 Check PolyAlgorithmRouting port ID generation
  - [x] 4.2 Check MultiChannelAlgorithmRouting port ID generation  
  - [x] 4.3 Check UsbFromAlgorithmRouting port ID generation
  - [x] 4.4 Update any port ID generation that doesn't use stable algorithm UUID
  - [x] 4.5 Write tests to verify port IDs are stable across instances

- [x] 5. Integration Testing and Final Verification
  - [x] 5.1 Test with real preset containing duplicate algorithms
  - [x] 5.2 Verify routing editor loads without freezing
  - [x] 5.3 Test that connections are properly isolated between duplicates
  - [x] 5.4 Verify performance meets criteria (<100ms for 8 duplicates)
  - [x] 5.5 Run flutter analyze and fix any issues
  - [x] 5.6 Verify all tests pass