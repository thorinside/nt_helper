# Mobile Bottom Bar Optimization - Product Requirements Document (PRD)

**Author:** Neal
**Date:** 2025-11-16
**Project Level:** 2 (Single feature, multiple stories)
**Target Scale:** Mobile & Desktop platforms

---

## Goals and Background Context

### Goals

- Eliminate bottom navigation bar squashing on mobile devices in connected mode
- Maintain desktop power-user workflow (no regression)
- Provide clear, accessible display mode options for musicians on mobile
- Use platform-adaptive design patterns that scale for future feature additions

### Background Context

- Current implementation shows 6+ interactive controls in bottom bar on mobile (connected mode)
- Controls include: mode switcher (2 segments) + 4 display mode buttons + FAB spacer
- Musicians report difficulty tapping accurately on mobile devices
- Display mode buttons control **hardware NT device display**, not app UI - quick access is important
- Desktop users have adequate horizontal space and should maintain current one-tap workflow
- Offline and demo modes already work well with single-button layout (no changes needed)

---

## Requirements

### Functional Requirements

**FR1: Platform Detection**
- System SHALL use existing `PlatformInteractionService.isMobilePlatform()` to detect mobile vs desktop platforms
- Detection SHALL determine which bottom bar layout to render

**FR2: Desktop Layout (No Change)**
- When `!isMobilePlatform()` AND connected mode:
  - System SHALL render current 4 icon buttons for display modes (Parameter View, Algorithm UI, Overview UI, Overview VU Meters)
  - System SHALL maintain existing tooltip behavior on icon hover
  - System SHALL maintain one-tap hardware display mode switching

**FR3: Mobile Layout (New)**
- When `isMobilePlatform()` AND connected mode:
  - System SHALL render single "View Options" icon button in place of 4 display mode buttons
  - System SHALL use `Icons.view_list` or `Icons.visibility` for button icon
  - Button SHALL have tooltip "View Options"

**FR4: Bottom Sheet Component**
- Tapping "View Options" button SHALL open modal bottom sheet
- Bottom sheet SHALL contain:
  - Header: "Hardware Display Mode"
  - Four options using ListTile components:
    - Parameter View (icon: `Icons.list_alt_rounded`, subtitle: "Hardware parameter list")
    - Algorithm UI (icon: `Icons.line_axis_rounded`, subtitle: "Custom algorithm interface")
    - Overview UI (icon: `Icons.line_weight_rounded`, subtitle: "All slots overview")
    - Overview VU Meters (icon: `Icons.leaderboard_rounded`, subtitle: "VU meter display")
- Each option SHALL call `context.read<DistingCubit>().setDisplayMode(mode)` when tapped
- Bottom sheet SHALL auto-dismiss after option selection
- Bottom sheet SHALL be dismissible via swipe-down gesture or tap outside

**FR5: Mode Preservation**
- Offline mode bottom bar SHALL remain unchanged (single "Offline Data" button)
- Demo mode bottom bar SHALL remain unchanged
- All other bottom bar elements (mode switcher, MCP status, version, CPU monitor, FAB spacer) SHALL maintain current behavior

### Non-Functional Requirements

**NFR1: Touch Targets**
- Bottom sheet options SHALL meet minimum 56px height (Material 3 guideline)
- Touch targets SHALL exceed WCAG minimum 44x44dp requirement

**NFR2: Accessibility**
- "View Options" button SHALL have semantic label for screen readers
- Bottom sheet options SHALL use proper ListTile semantics
- Each option SHALL announce: "[Title], [Subtitle]" to screen readers
- Keyboard navigation SHALL support tab focus and enter-to-select

**NFR3: Performance**
- Bottom sheet open animation SHALL complete within 300ms
- Platform detection SHALL add negligible overhead (<1ms)
- No impact to hardware display mode change latency

**NFR4: Visual Consistency**
- Bottom sheet SHALL use Material 3 design system components
- Colors, typography, and spacing SHALL match existing app theme
- Bottom bar height SHALL remain consistent (no layout shift)

---

## User Journeys

### Journey 1: Desktop User Changes Display Mode (Unchanged)
1. User sees 4 icon buttons in bottom bar
2. User hovers over desired display mode button (sees tooltip)
3. User clicks button
4. Hardware display immediately changes
5. **Total: 1 click**

### Journey 2: Mobile User Changes Display Mode (New)
1. User sees "View Options" button in bottom bar
2. User taps "View Options" button
3. Bottom sheet slides up with 4 labeled options
4. User taps desired display mode option
5. Bottom sheet auto-dismisses
6. Hardware display changes
7. **Total: 2 taps**

### Journey 3: Mobile User Dismisses Bottom Sheet (New)
1. User taps "View Options" button
2. Bottom sheet opens
3. User changes mind, swipes down OR taps outside
4. Bottom sheet dismisses
5. No state change

---

## UX Design Principles

- **Platform-Appropriate**: Each platform gets optimal UX for its interaction paradigm (mouse vs touch)
- **Clarity Over Speed**: On mobile, prioritize clear labels and descriptions over absolute tap efficiency
- **Progressive Disclosure**: Hide complexity behind single button on mobile, reveal with context when needed
- **Consistency Within Platform**: Use Material 3 bottom sheet pattern (standard mobile UX)
- **No Regression**: Desktop power users maintain existing fast workflow

---

## User Interface Design Goals

- Clean, uncluttered mobile bottom bar with breathing room between controls
- Large, tappable targets for musicians who may be holding cables or instruments
- Clear text labels that explain what each display mode does (not just icons)
- Smooth, fast animations that feel responsive
- Zero desktop impact - desktop users should notice no difference

---

## Epic List

### Epic 9: Mobile Bottom Bar Optimization
**Goal:** Implement platform-adaptive bottom bar that solves mobile squashing while maintaining desktop workflow

**Scope:**
- Platform detection integration
- Mobile bottom sheet component
- Desktop layout preservation
- Testing across all platforms and modes

**Stories (est. 3-4):**
1. **Story 1: Platform Detection and Layout Switching**
   - Add `isMobilePlatform()` detection to bottom bar builder
   - Implement conditional rendering (desktop = 4 buttons, mobile = 1 button)
   - Verify offline/demo modes unchanged
   - Test on iOS, Android, macOS, Windows, Linux

2. **Story 2: Bottom Sheet Component Implementation**
   - Create `_showDisplayModeBottomSheet()` method
   - Create `_buildDisplayModeOption()` helper
   - Create `_buildBottomSheetHeader()` helper
   - Implement auto-dismiss on selection
   - Wire up display mode changes to DistingCubit
   - Add swipe-to-dismiss and tap-outside-to-dismiss

3. **Story 3: Accessibility and Polish**
   - Add semantic labels for screen readers
   - Verify keyboard navigation support
   - Test with TalkBack (Android) and VoiceOver (iOS)
   - Verify WCAG touch target requirements
   - Add haptic feedback on mobile (if not already present)

4. **Story 4: Cross-Platform Testing and Validation**
   - Test on real iOS and Android devices (not just simulators)
   - Verify desktop platforms show no regression
   - Test all three modes: connected, offline, demo
   - Verify display mode changes propagate to hardware correctly
   - Performance testing (animation smoothness, no jank)

**Estimated Effort:** 2-3 days (assuming experienced Flutter dev)

**Dependencies:** None (uses existing services and components)

**Risks:**
- Low risk: Bottom sheet is isolated new code path
- Low risk: Desktop code path unchanged
- Testing risk: Need real mobile devices for accurate touch target validation

---

## Out of Scope

- Adding new display modes beyond the existing 4
- Implementing keyboard shortcuts for display mode switching
- Custom bottom sheet styling beyond Material 3 defaults
- Animated transitions between display modes on hardware
- Saving user's preferred display mode (if not already implemented)
- Tablet-specific layout (tablets will use desktop layout per `!isMobilePlatform()`)

---

## Success Metrics

**Pre-Launch Validation:**
- ✓ Zero regressions on desktop (4 buttons visible, one-tap switching works)
- ✓ Mobile bottom bar has adequate spacing (no squashing)
- ✓ All 4 display modes accessible on mobile via bottom sheet
- ✓ Bottom sheet animation smooth (60fps)
- ✓ Accessibility audit passes (screen reader, keyboard nav, touch targets)

**Post-Launch Metrics:**
- Monitor support requests for mobile UI issues (should decrease)
- Track display mode usage on mobile (understand frequency of switching)
- Gather user feedback on mobile UX improvement

---

## Technical Architecture Notes

**Files to Modify:**
- `lib/ui/synchronized_screen.dart` (lines ~509-646)
  - `_buildBottomAppBar()` method
  - Add 3 new private methods

**Dependencies:**
- `PlatformInteractionService` (already exists)
- `DistingCubit.setDisplayMode()` (already exists)
- Material 3 `showModalBottomSheet()` (Flutter framework)

**Design System:**
- Material 3 components
- Existing app theme and colors
- No new design tokens required

---

## Appendix

### Related Documents
- UX Design Specification: `docs/ux-design-specification.md`
- Interactive Mockup: `docs/mobile-bottom-bar-mockup.html`
- Main Screen Implementation: `lib/ui/synchronized_screen.dart`

### Reference Implementations
- See UX spec Section 4.2 for bottom sheet code examples
- See mockup HTML for visual design reference

---

**Document Version:** 1.0
**Status:** Ready for Development
**Next Step:** Epic breakdown into detailed stories with acceptance criteria
