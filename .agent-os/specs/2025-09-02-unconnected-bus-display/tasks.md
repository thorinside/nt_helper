# Spec Tasks

## Tasks

- [ ] 1. Enhance Connection Model
  - [ ] 1.1 Write tests for partial connection representation
  - [ ] 1.2 Add simple partial connection flag to Connection model
  - [ ] 1.3 Ensure connection can represent bus label endpoint
  - [ ] 1.4 Verify all tests pass

- [ ] 2. Integrate Partial Connection Discovery
  - [ ] 2.1 Write tests for integrated connection discovery
  - [ ] 2.2 Modify ConnectionDiscoveryService.discoverConnections() to track unmatched ports
  - [ ] 2.3 Create partial connections for ports with non-zero bus values that don't match
  - [ ] 2.4 Ensure zero-value ports are skipped (no partial connections)
  - [ ] 2.5 Verify all tests pass

- [ ] 3. Update Connection Rendering
  - [ ] 3.1 Write tests for partial connection rendering
  - [ ] 3.2 Modify RoutingEditorWidget to handle partial connection flag
  - [ ] 3.3 Render bus labels at partial connection endpoints
  - [ ] 3.4 Apply visual styling to indicate partial state (dashed/opacity)
  - [ ] 3.5 Verify all tests pass

- [ ] 4. Integration Testing
  - [ ] 4.1 Test with various routing configurations
  - [ ] 4.2 Verify partial connections appear for all unmatched bus assignments
  - [ ] 4.3 Confirm zero-value ports don't create partial connections
  - [ ] 4.4 Test visual clarity and performance
  - [ ] 4.5 Verify all tests pass