# Spec Tasks

These are the tasks to be completed for the spec detailed in @.agent-os/specs/2025-09-04-port-metadata-refactor/spec.md

> Created: 2025-09-04
> Status: Ready for Implementation

## Tasks

- [ ] 1. Port Model Refactoring - Add Direct Properties
  - [ ] 1.1 Write tests for Port model with direct properties in `test/core/routing/models/port_test.dart`
  - [ ] 1.2 Add direct typesafe properties to Port class (isPolyVoice, voiceNumber, busValue, etc.)
  - [ ] 1.3 Update Port constructor to accept direct property parameters alongside existing metadata field
  - [ ] 1.4 Update port creation in routing implementations to populate both metadata and direct properties
  - [ ] 1.5 Verify all tests pass with dual property support

- [ ] 2. Routing Implementations Migration - Use Direct Properties
  - [ ] 2.1 Write tests for routing implementations using direct property access in `test/core/routing/routing_implementations_test.dart`
  - [ ] 2.2 Update PolyAlgorithmRouting to use `port.isPolyVoice` instead of `port.metadata?['isPolyVoice']`
  - [ ] 2.3 Update MultiChannelAlgorithmRouting to use `port.isMultiChannel` instead of metadata access
  - [ ] 2.4 Update ConnectionDiscoveryService to use `port.busValue` instead of `port.metadata?['busValue']`
  - [ ] 2.5 Verify all routing implementation tests pass with direct property access

- [ ] 3. Remove Generic Metadata - Clean Up Port Model
  - [ ] 3.1 Write tests to verify metadata field removal doesn't break serialization in `test/core/routing/models/port_serialization_test.dart`
  - [ ] 3.2 Remove `metadata` field from Port class
  - [ ] 3.3 Update Port serialization (toJson/fromJson) to use direct properties
  - [ ] 3.4 Delete unused PortMetadata and ConnectionMetadata classes if they exist
  - [ ] 3.5 Verify all tests pass after metadata field removal

- [ ] 4. Documentation and Final Cleanup
  - [ ] 4.1 Write tests to verify no remaining metadata access patterns in codebase in `test/core/routing/no_metadata_access_test.dart`
  - [ ] 4.2 Update CLAUDE.md to remove "rich metadata support" language and add direct property examples
  - [ ] 4.3 Update routing architecture documentation to reflect direct property access patterns
  - [ ] 4.4 Run `flutter analyze` to ensure zero warnings after complete refactoring
  - [ ] 4.5 Verify entire test suite passes and routing visualization works correctly