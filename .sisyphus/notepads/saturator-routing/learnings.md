# Saturator Routing Implementation Learnings

## [2026-01-17T04:45:00Z] Tasks 1-9: Core Implementation

### Discovered Patterns

**Multi-channel logic was already working**: The implementation loop `for (int channel = 1; channel <= channelCount; channel++)` already handled multiple channels correctly. TODO 7 (RED) and TODO 8 (GREEN) both passed immediately because the width logic naturally extended to multi-channel scenarios.

**Width parameter handling**: Width=1 requires NO numeric suffix (`1:Input`, `1:Output`), while width>1 requires numbered ports (`1:Input 1`, `1:Input 2`, etc.). This is handled with a simple conditional.

**Port ID generation**: For width>1, use unique IDs like `${algorithmUuid}_channel_${channel}_input_$w` to avoid collisions.

**Parameter number for virtual ports**: Use negative numbers to indicate virtual ports. For width>1, use `-(channel * 100 + w)` to ensure uniqueness across channels and width indices.

### Successful Approaches

**TDD RED-GREEN pattern**: Writing failing tests first (RED) then implementing (GREEN) caught issues early and ensured complete coverage.

**Incremental complexity**: Building mono → width → multi-channel in stages made debugging easier.

**Factory registration placement**: Inserted `SaturatorAlgorithmRouting.canHandle()` check BEFORE `PolyAlgorithmRouting` to ensure Saturator is handled by its specialized routing class.

### Technical Details

**Channel counting**: Use regex `r'^(\d+):'` to extract channel numbers from parameter names like `1:Input`, `2:Width`.

**Bus value calculation**: For width>1, consecutive buses are `inputBusValue + (w - 1)` where w is 1-indexed.

**Output mode**: ALL virtual outputs must have `outputMode: 'replace'` (string in port map, becomes `OutputMode.replace` enum in Port model).

### File Structure

- `lib/core/routing/saturator_algorithm_routing.dart` - Main implementation (117 lines)
- `test/core/routing/saturator_algorithm_routing_test.dart` - Comprehensive tests (12 tests, all passing)
- Factory registration in `lib/core/routing/algorithm_routing.dart` (lines 422-429)
