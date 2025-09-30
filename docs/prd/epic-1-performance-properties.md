# Epic: Performance Properties Integration - Brownfield Enhancement

## Epic Goal

Enable nt_helper to display firmware-managed performance properties instead of mapped properties on the Performance page, allowing musicians to control which parameters appear during live performance directly from the hardware.

## Epic Description

**Existing System Context:**

- **Current relevant functionality:** nt_helper currently displays "Mapped" properties on the Performance page. The app communicates with Disting NT hardware via MIDI SysEx protocol with separate implementations for demo/offline/live modes.
- **Technology stack:** Flutter with Cubit state management, Drift ORM database, interface-based MIDI layer (lib/domain/sysex/), property/parameter system
- **Integration points:** SysEx message handlers, property editor UI components, Performance screen (lib/ui/), DistingCubit state management, database layer for offline caching

**Enhancement Details:**

- **What's being added/changed:**
  - Extend existing mapping data structures to include performance page index (mapping version 5)
  - Add SysEx 0x54 handler for setting performance page assignments (parameter to page index 0-15)
  - Property editor integration to display and manage performance page assignments
  - Performance page rewrite to filter and display parameters assigned to performance pages

- **How it integrates:**
  - Extends existing SysEx 0x4B (mapping request/response) to parse performance page index from version 5 mapping data
  - Adds new SysEx 0x54 request handler for setting performance page assignments
  - Updates `PackedMappingData` model to include `perfPageIndex` field
  - Replaces Performance page data source from "mapped properties" to "parameters with perfPageIndex > 0"
  - Follows existing Cubit state management patterns
  - Maintains offline/demo mode compatibility through database caching

- **Success criteria:**
  - Performance page displays parameters assigned to performance pages (perfPageIndex > 0)
  - Property editor shows and allows setting performance page index (0-15) for each parameter
  - Mapping data correctly stores and retrieves performance page assignments
  - Offline mode caches performance page assignments in database
  - Zero disruption to existing mapped property functionality (CV, MIDI, I2C mappings)
  - All three operation modes (demo, offline, connected) work correctly

## Stories

1. **Story 1.1:** Extend mapping data model to include performance page index - Update `PackedMappingData` model and existing SysEx 0x4B handler to parse and store performance page index (mapping version 5), ensuring database schema supports the new field

2. **Story 1.2:** Add SysEx 0x54 handler for setting performance page assignments - Implement SysEx 0x54 request/response for assigning parameters to performance page indices (0-15), add to all three IDistingMidiManager implementations (live, mock, offline)

3. **Story 1.3:** Performance page with side-nav page selector - Add side navigation to Performance page with pages 1-15, filter and display parameters assigned to selected page, maintaining existing UI patterns and offline/demo mode compatibility

4. **Story 1.4:** Display performance parameters at top of algorithm property editor - Add collapsible "Performance Parameters" section at top of algorithm property editor in synchronized screen, showing quick access to parameters assigned to performance pages

## Compatibility Requirements

- [x] Existing APIs remain unchanged (SysEx 0x54 is addition, 0x4B is extended for version 5)
- [x] Database schema changes are backward compatible (add perfPageIndex field to mapping table)
- [x] Existing CV/MIDI/I2C mapping functionality remains unchanged
- [x] UI changes follow existing patterns (property editor and Performance page patterns)
- [x] Performance impact is minimal (extends existing mapping data flow)

## Risk Mitigation

- **Primary Risk:** Breaking existing CV/MIDI/I2C mapping functionality when extending mapping data structure
- **Mitigation:**
  - Add perfPageIndex as optional field (nullable or default 0)
  - Existing mapping version 4 and earlier remain fully functional
  - Version 5 is backward compatible - older data parses correctly
  - Test all mapping types (CV, MIDI, I2C) in all three operation modes (demo, offline, connected)
- **Rollback Plan:** Performance page can revert to displaying mapped properties; perfPageIndex field ignored if not used; SysEx 0x54 handler can be disabled without affecting core mapping functionality

## Definition of Done

- [ ] All four stories completed with acceptance criteria met
- [ ] Existing CV/MIDI/I2C mapping functionality verified through testing (no regressions)
- [ ] All operation modes (demo, offline, connected) work correctly
- [ ] Property editor displays performance page index field and allows setting (0-15)
- [ ] Performance page has side-nav page selector (Pages 1-15)
- [ ] Performance page filters and displays only parameters assigned to selected page
- [ ] Algorithm property editor shows performance parameters at top (collapsible section)
- [ ] SysEx 0x54 correctly sets performance page assignments
- [ ] SysEx 0x4B correctly parses version 5 mapping data with perfPageIndex
- [ ] Database schema updated with backward compatibility (perfPageIndex field added)
- [ ] Mapping version 4 and earlier data still works correctly
- [ ] No regression in existing features
- [ ] `flutter analyze` returns zero warnings

## Story Manager Handoff

"Please develop detailed user stories for this brownfield epic. Key considerations:

- This is an enhancement to an existing Flutter app (nt_helper) communicating with Disting NT hardware via MIDI SysEx
- **Technology stack:** Flutter, Cubit state management, Drift ORM, interface-based MIDI layer (mock/offline/live implementations)
- **Integration points:**
  - Existing SysEx 0x4B (mapping request/response) handlers - extend for version 5
  - New SysEx 0x54 (set performance page) handlers - implement from scratch
  - `PackedMappingData` model in lib/models/ - add perfPageIndex field
  - Property editor UI components - add performance page index input
  - Performance screen (lib/ui/performance_screen.dart) - add side-nav page selector, filter by perfPageIndex
  - Algorithm property editor (lib/ui/synchronized_screen.dart area) - add performance parameters section at top
  - DistingCubit state management
  - Database layer (Drift ORM) - add perfPageIndex to mapping table
- **Existing patterns to follow:**
  - Mapping data structure already exists - performance page is additional field in version 5
  - SysEx message handler patterns from existing protocol implementations (especially 0x4B mapping handlers)
  - Cubit state management patterns
  - Property/parameter display patterns
  - Three-mode operation (demo, offline, connected)
- **Technical Implementation Notes:**
  - Performance properties are NOT a separate enumeration system
  - They are assignments of existing parameters to performance page indices (0-15)
  - Stored in existing mapping data structure as version 5 extension
  - SysEx 0x4B already exists - extend response parser for version 5 perfPageIndex field
  - SysEx 0x54 is NEW - implement request to set performance page assignment
- **Critical compatibility requirements:**
  - Must maintain existing CV/MIDI/I2C mapping functionality (version 4 and earlier)
  - Version 5 mapping data must be backward compatible
  - Must support all three operation modes
  - Database schema must be backward compatible (perfPageIndex nullable or default 0)
  - Must pass `flutter analyze` with zero warnings (project standard)
- Each story must include verification that existing mapping functionality remains intact (CV, MIDI, I2C mappings)

The epic should maintain system integrity while extending the existing mapping system to include performance page assignments."
