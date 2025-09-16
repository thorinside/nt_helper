# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-09-16-preserve-parameter-prefixes/spec.md

## Technical Requirements

- Remove or disable the parameter prefix stripping logic in `MetadataSyncService._syncInstantiatedAlgorithmParams()`
- Preserve the full parameter name from `paramInfo.name` when creating `ParameterEntry` objects
- Ensure the regex pattern `_parameterPrefixRegex` is either removed or its usage is eliminated
- Store complete parameter names in the database including channel prefixes (1:, 2:, A:, B:, etc.)
- Verify that parameter lookup and matching continues to function with full names
- Test with multi-channel algorithms to ensure each channel's parameters are distinguishable

## Implementation Details

The issue is in `lib/services/metadata_sync_service.dart` at lines 711-716 where the code currently:
1. Extracts a base name by stripping prefixes matching the pattern `^([0-9]+|A|B|C|D):\s*`
2. Stores only the base name in the database

The fix involves:
- Line 725: Change from `name: baseName` to `name: paramInfo.name` to preserve the original name
- Lines 712-716: Remove or comment out the prefix stripping logic
- Line 23: Consider removing the `_parameterPrefixRegex` if no longer needed

No external dependencies are required for this fix.