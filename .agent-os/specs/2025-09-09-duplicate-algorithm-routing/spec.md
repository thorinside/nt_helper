# Spec Requirements Document

> Spec: Duplicate Algorithm Routing Support
> Created: 2025-09-09

## Overview

Fix the routing canvas connection discovery to properly use the stable algorithm IDs that are already being generated, resolving the "Initializing routing editor..." freeze when duplicate algorithms exist. This minimal fix connects the existing stable ID infrastructure to the connection discovery service.

## User Stories

### Duplicate Algorithm Visualization

As a Disting NT user, I want to use multiple instances of the same algorithm in my preset, so that I can create complex patches with layered effects or parallel processing chains.

When I load a preset with multiple slots using the same algorithm (e.g., two Stereo Reverb instances), the routing editor should display each instance separately with its own connections and parameters. Each instance should maintain its independent state and routing configuration, allowing me to route signals differently through each one. The visualization should clearly show which connections belong to which instance, making it easy to understand the signal flow even with duplicate algorithms.

## Spec Scope

1. **Store Stable IDs** - Add field to AlgorithmRouting to store the already-passed algorithmUuid
2. **Fix Connection Discovery** - Replace unstable hashCode fallback with stored stable ID
3. **Verify Port ID Generation** - Ensure all routing implementations use stable IDs in port IDs
4. **Test Coverage** - Write failing test first (red-green strategy) to reproduce and verify fix

## Out of Scope

- Modifying the stable ID generation (already working correctly in RoutingEditorCubit)
- Changing AlgorithmRouting.fromSlot() logic (already accepts stable IDs)
- Modifying the core routing framework architecture
- Adding special visual indicators for duplicate algorithms

## Expected Deliverable

1. ConnectionDiscoveryService uses stable algorithm IDs instead of hashCode fallback
2. Routing canvas displays all algorithm instances without getting stuck
3. Failing test reproduces the bug, then passes after the fix (red-green test)