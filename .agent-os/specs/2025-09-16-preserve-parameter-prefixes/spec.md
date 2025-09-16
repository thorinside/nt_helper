# Spec Requirements Document

> Spec: Preserve Parameter Prefixes During Metadata Import
> Created: 2025-09-16

## Overview

Fix the metadata import process to preserve channel and identifier prefixes in parameter names (e.g., "1:Input", "2:Output") that are currently being stripped during import. These prefixes are essential for matching the actual parameter naming convention used by the Disting NT hardware module.

## User Stories

### Accurate Parameter Identification

As a Disting NT user, I want parameter names to exactly match what appears on my hardware module, so that I can correctly identify and control multi-channel parameters.

When working with algorithms that have multiple channels (like poly or multi-channel algorithms), each channel's parameters are prefixed with the channel number (1:, 2:, etc.) or letter (A:, B:, etc.). Currently, these prefixes are being stripped during metadata import, causing all channels to appear to have the same parameter name "Input" instead of "1:Input", "2:Input", etc. This makes it impossible to distinguish between channels when viewing or editing parameters.

## Spec Scope

1. **Preserve Parameter Prefixes** - Stop stripping channel prefixes (1:, 2:, A:, B:, etc.) from parameter names during metadata import
2. **Database Storage** - Store the complete parameter name including prefixes in the database
3. **Backward Compatibility** - Ensure existing functionality continues to work with the preserved prefixes
4. **Metadata Sync Update** - Modify the metadata sync service to handle full parameter names

## Out of Scope

- Changing the database schema structure
- Modifying how parameters are displayed in the UI (they should already handle full names)
- Altering the MIDI communication protocol

## Expected Deliverable

1. Parameter names with prefixes are fully preserved during metadata import and stored in the database
2. Multi-channel algorithms display distinct parameter names for each channel (e.g., "1:Input", "2:Input")
3. Existing parameter matching and lookup functionality continues to work with full names