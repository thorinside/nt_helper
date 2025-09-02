# Algorithm-to-Algorithm Connection Visualization Specification

## Overview
This specification defines the implementation of algorithm-to-algorithm connection visualization for the NT Helper routing editor, enabling users to see complete signal flow between algorithm slots.

## Specification Documents

### Core Specifications
- **[spec.md](spec.md)** - Main requirements document with functional and non-functional requirements
- **[spec-lite.md](spec-lite.md)** - Condensed summary for quick reference and AI context
- **[tasks.md](tasks.md)** - Detailed task breakdown organized by implementation phases

### Technical Specifications
- **[technical-spec.md](sub-specs/technical-spec.md)** - Complete technical implementation details, architecture, and code samples
- **[tests.md](sub-specs/tests.md)** - Comprehensive testing strategy with unit, integration, and visual tests
- **[acceptance-validation.md](sub-specs/acceptance-validation.md)** - 25 test cases for validating implementation meets requirements

### Implementation Guides
- **[implementation-checklist.md](implementation-checklist.md)** - Day-by-day implementation checklist with 100+ items

## Key Technical Details

### System Constraints
- **Maximum Slots**: 32 algorithms (0–31)
- **Total Buses**: 28 buses
  - Buses 1–12: Physical inputs
  - Buses 13–20: Physical outputs (hardware jacks; will not change)
  - Buses 21–28: AUX (internal routing)
- **Bus Value 0**: Means "None" (no connection)
- **Execution Order**: Strict slot order processing (lower → higher)

### Implementation Highlights
- **Data Model**: New `AlgorithmConnection` immutable model with freezed
- **Service Layer**: `AlgorithmConnectionService` for connection discovery (1–28 bus support)
- **Performance**: Simple last-hash caching (optional)
- **Visual Design**:
  - Valid connections: Color follows source output port type (no per-port hue changes)
  - Invalid connections: Red dashed lines
  - Bus labels at connection midpoints

### Success Metrics
- **Discovery**: 100% of connections correctly identified
- **Quality**: > 90% test coverage, zero regressions
- **Performance**: Reasonable responsiveness with typical presets (non-gating)

## Implementation Timeline
- **Phase 1** (Day 1-2): Data model creation
- **Phase 2** (Day 3-5): Connection discovery service
- **Phase 3** (Day 6-7): Cubit integration
- **Phase 4** (Day 8-10): UI implementation
- **Phase 5** (Day 11-12): Testing and validation
- **Phase 6** (Day 13-14): Documentation and polish

## Development Notes
- Work continues on `feature/routing_editor` branch
- Reuses existing bus resolution logic from `RoutingEditorCubit`
- No special handling needed for Feedback Send/Receive algorithms
- Physical connections remain separate (no duplication)

## Quick Start for Developers
1. Review [spec-lite.md](spec-lite.md) for overview
2. Check [implementation-checklist.md](implementation-checklist.md) for tasks
3. Reference [technical-spec.md](sub-specs/technical-spec.md) for implementation details
4. Use [acceptance-validation.md](sub-specs/acceptance-validation.md) to verify work

## Questions or Clarifications
If any aspect of the specification needs clarification:
1. Check the detailed technical spec first
2. Review the acceptance validation criteria
3. Ask for clarification rather than making assumptions

---
*Specification Version: 1.0*  
*Date: 2025-08-31*  
*Status: Ready for Development*
