# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-04-port-metadata-refactor/spec.md

> Created: 2025-09-04
> Version: 1.0.0

## Technical Requirements

### Migration from Generic Metadata to Direct Properties

**Current State:**
- Ports use `port.metadata?['key']` pattern for accessing properties
- Generic `Map<String, dynamic>` metadata field allows any key-value pairs
- No compile-time safety for metadata access
- Manual type casting required (e.g., `as int?`, `as bool?`)

**Target State:**
- Replace with direct property access (e.g., `port.isPolyVoice`, `port.voiceNumber`)
- Add typesafe properties directly to Port class
- Compile-time safety for all property access
- Remove generic metadata field entirely

### Direct Property Implementation

**Properties to Add (from metadata usage analysis):**

**Polyphonic Properties:**
- `bool isPolyVoice` - replaces `metadata?['isPolyVoice'] == true`
- `int? voiceNumber` - replaces `metadata?['voiceNumber'] as int?`
- `bool isVirtualCV` - replaces `metadata?['isVirtualCV'] == true`
- `int? gateNumber`, `int? gateBus`, `bool isGateInput`

**Multi-Channel Properties:**
- `bool isMultiChannel` - replaces `metadata?['isMultiChannel'] == true`
- `bool isStereoChannel` - replaces `metadata?['isStereoChannel'] == true`
- `bool isMasterMix` - replaces `metadata?['isMasterMix'] == true`
- `int? channelNumber` - replaces `metadata?['channelNumber'] as int?`
- `String? stereoSide` - replaces `metadata?['stereoSide'] as String?`

**Connection Properties:**
- `int? busValue` - replaces `metadata?['busValue'] as int?`
- `String? busParam` - replaces `metadata?['busParam'] as String?`
- `int? parameterNumber` - replaces `metadata?['parameterNumber'] as int?`

**Implementation Pattern:**
```dart
// Before (unsafe)
final busNumber = port.metadata?['busNumber'] as int?;
final isInput = port.metadata?['isInput'] as bool? ?? false;

// After (typesafe)
final busNumber = port.busValue;
final isInput = port.isGateInput;
```

### Routing Implementation Updates

**Files Requiring Updates:**
- `lib/core/routing/models/port.dart` - add direct properties, remove metadata field
- `lib/core/routing/poly_algorithm_routing.dart` - use direct property access
- `lib/core/routing/multi_channel_algorithm_routing.dart` - use direct property access
- `lib/core/routing/connection_discovery_service.dart` - use direct property access

**Migration Pattern:**
1. Add direct properties to Port class alongside metadata field
2. Update port creation to populate both metadata and direct properties
3. Replace all `port.metadata?['key']` access with `port.property`
4. Remove metadata field and unused PortMetadata/ConnectionMetadata classes
5. Clean up all metadata-related helper methods

### JSON Serialization Compatibility

**Requirement:**
- Preserve existing JSON serialization format for Port model
- Ensure database migrations work seamlessly
- Maintain API compatibility for any external consumers
- No breaking changes to stored routing data

**Implementation:**
- Update `fromJson`/`toJson` methods in Port to handle direct properties
- Map metadata keys to direct properties during deserialization
- Ensure serialized format includes all necessary properties
- Test round-trip serialization to verify compatibility

### Generic Metadata Field Removal

**Phase 1: Add Direct Properties**
- Add direct properties to Port class alongside existing `metadata` field
- Update port creation to populate both metadata and direct properties
- Update all access patterns to use direct properties
- Ensure both approaches work during transition

**Phase 2: Remove Metadata**
- Remove `metadata` field from Port model
- Remove all metadata access patterns
- Delete unused PortMetadata/ConnectionMetadata classes
- Update unit tests to use direct property patterns

### Documentation Pattern Updates

**CLAUDE.md Updates:**
- Remove reference to "rich metadata support" language that encouraged generic metadata
- Update architecture documentation to reflect direct property access patterns
- Add examples of proper direct property usage
- Update visualization flow diagrams to show direct property access

**Code Documentation:**
- Add comprehensive dartdoc comments for direct properties in Port model
- Document the properties and their intended usage
- Provide clear examples of before/after patterns
- Update inline comments to reflect new direct property approach

## Approach

### Implementation Strategy

**Gradual Migration:**
1. Add direct properties alongside existing `metadata` field
2. Update creation logic to populate both metadata and direct properties
3. Migrate access patterns implementation by implementation
4. Add comprehensive tests for direct property patterns
5. Remove deprecated `metadata` field and unused classes in final phase

**Testing Strategy:**
- Unit tests for each routing implementation
- Integration tests for connection discovery
- JSON serialization round-trip tests
- Performance comparison before/after migration
- Backward compatibility validation tests

**Quality Assurance:**
- Zero `flutter analyze` warnings during and after migration
- All existing routing tests must continue passing
- Performance benchmarks to ensure no regression
- Code review for each routing implementation update