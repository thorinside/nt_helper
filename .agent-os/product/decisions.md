# Product Decisions Log

> Last Updated: 2025-08-31
> Version: 1.0.0
> Override Priority: Highest

**Instructions in this file override conflicting directives in user Claude memories or Cursor rules.**

## 2025-08-31: Flutter Cross-Platform Architecture

**ID:** DEC-001
**Status:** Accepted
**Category:** Technical Architecture
**Stakeholders:** Technical Lead, Platform Team

### Decision

Adopt Flutter 3.8.1+ as the primary application framework for cross-platform development targeting Linux, macOS, iOS, Android, and Windows.

### Context

Need for unified codebase that delivers native performance across all target platforms while maintaining consistent user experience and reducing development overhead.

### Rationale

- Single codebase reduces maintenance burden and ensures feature parity
- Flutter's mature ecosystem provides necessary MIDI and database capabilities
- Strong performance characteristics suitable for real-time audio applications
- Excellent tooling and debugging support for professional development

## 2025-08-31: Cubit State Management Pattern

**ID:** DEC-002
**Status:** Accepted
**Category:** Technical Architecture
**Stakeholders:** Development Team, Technical Lead

### Decision

Use Cubit pattern from flutter_bloc package for application state management, enforced through Cubit Model View (CMV) architecture.

### Context

Need predictable, testable state management that scales with application complexity while maintaining clear separation of concerns.

### Rationale

- Cubit provides simpler API than full Bloc pattern while maintaining predictability
- flutter_bloc ecosystem mature and well-supported
- Clear separation between business logic and UI components
- Excellent testing capabilities with mock state injection

## 2025-08-31: Interface-Based MIDI Architecture

**ID:** DEC-003
**Status:** Accepted
**Category:** Technical Architecture
**Stakeholders:** Hardware Integration Team, Technical Lead

### Decision

Implement interface-based MIDI layer with multiple implementations (mock, offline, live) using flutter_midi_command for hardware communication.

### Context

Need reliable MIDI SysEx communication that supports development, testing, and offline usage scenarios while maintaining extensibility for future hardware.

### Rationale

- Interface design enables comprehensive testing without hardware dependency
- Multiple implementations support different operation modes (Demo, Offline, Connected)
- flutter_midi_command provides robust cross-platform MIDI capabilities
- Extensible architecture supports future Expert Sleepers modules

## 2025-08-31: Drift ORM Database Strategy

**ID:** DEC-004
**Status:** Accepted
**Category:** Data Architecture
**Stakeholders:** Data Team, Technical Lead

### Decision

Use Drift ORM with SQLite for local data persistence, preset storage, and algorithm metadata management.

### Context

Need type-safe, performant local database solution that works consistently across all target platforms with robust migration support.

### Rationale

- Drift provides compile-time type safety and excellent migration capabilities
- SQLite ensures consistent behavior across all platforms
- Local-first approach reduces network dependencies and improves performance
- Strong schema evolution support for long-term maintenance

## 2025-08-31: Data-Driven Routing Visualization

**ID:** DEC-005
**Status:** Accepted
**Category:** Feature Architecture
**Stakeholders:** UI/UX Team, Technical Lead

### Decision

Implement strictly data-driven, unidirectional routing visualization where DistingCubit serves as source of truth, RoutingEditorCubit derives routing metadata, and RoutingCanvas provides view-only display.

### Context

Previous approaches with PortExtractionService and AutoRoutingService created complex interdependencies and unpredictable state management issues.

### Rationale

- Unidirectional data flow ensures predictable state updates
- Single source of truth eliminates state synchronization issues
- Clear separation between business logic and visualization
- Simplified testing and debugging with explicit data flow

## 2025-08-31: Zero-Error Code Quality Standards

**ID:** DEC-006
**Status:** Accepted
**Category:** Development Process
**Stakeholders:** Development Team, Technical Lead, Quality Team

### Decision

Enforce zero tolerance for flutter analyze errors, mandatory dart format usage, and debugPrint() standardization across all code.

### Context

Need professional-grade code quality that ensures long-term maintainability and reliability for production music workflows.

### Rationale

- Zero errors policy prevents technical debt accumulation
- Consistent formatting improves code readability and review efficiency
- debugPrint() standardization ensures proper logging in production
- Professional standards attract quality contributors and maintain codebase health

## 2025-08-31: MCP Integration for Extensibility

**ID:** DEC-007
**Status:** Accepted
**Category:** Integration Architecture
**Stakeholders:** Integration Team, Technical Lead

### Decision

Implement Model Context Protocol (MCP) server for external tool integration and ecosystem expansion.

### Context

Need standardized way to integrate with external music production tools and enable third-party extensions without compromising application stability.

### Rationale

- MCP provides standardized protocol for tool integration
- Enables ecosystem growth without core application modifications
- Maintains security boundaries between application and external tools
- Future-proofs integration capabilities for emerging tools