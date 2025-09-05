# Spec Requirements Document

> Spec: Port Metadata Refactor
> Created: 2025-09-04
> Status: Planning

## Overview

Refactor the Port model to remove the generic metadata field and collapse it into direct typesafe properties on the Port class instead of using a Map<String, dynamic> field.

## User Stories

### Better Developer Experience

As a developer working with the routing system, I want to access port properties directly (e.g., `port.isPolyVoice`) instead of using string-based metadata access (`port.metadata?['isPolyVoice'] == true`), so that I get compile-time validation, IDE autocomplete, and type safety.

The current pattern requires manual type casting and runtime checks, making the code brittle and hard to refactor.

## Spec Scope

1. **Port Model Refactoring** - Add direct typesafe properties to Port class for all metadata fields
2. **Routing Implementation Updates** - Update PolyAlgorithmRouting, MultiChannelAlgorithmRouting, and ConnectionDiscoveryService to use direct property access
3. **Remove Generic Metadata** - Delete the metadata field and any unused PortMetadata/ConnectionMetadata classes
4. **Documentation Updates** - Update CLAUDE.md to remove "rich metadata support" language
5. **Testing Updates** - Simplify test construction with direct property access

## Out of Scope

- Connection model changes (focusing only on Port model first)
- Database schema changes (JSON serialization preserved)
- Breaking changes to MCP API (internal refactoring only)

## Expected Deliverable

1. Port model has direct typesafe properties instead of generic metadata field
2. All routing implementations use direct property access (e.g., `port.isPolyVoice` vs `port.metadata?['isPolyVoice']`)
3. All tests pass with simplified property-based test construction

## Spec Documentation

- Tasks: @.agent-os/specs/2025-09-04-port-metadata-refactor/tasks.md
- Technical Specification: @.agent-os/specs/2025-09-04-port-metadata-refactor/sub-specs/technical-spec.md