# Epic 9: Mobile Bottom Bar Optimization

**Epic ID:** Epic-9
**Status:** Ready for Development
**Priority:** High
**Estimated Effort:** 2-3 days
**Created:** 2025-11-16
**Owner:** Development Team

---

## Epic Overview

**Problem Statement:**
The bottom navigation bar on mobile devices is squashed in connected mode, displaying 6+ interactive controls that compete for limited horizontal space. This makes it difficult for musicians to accurately tap display mode buttons while using the app during performances or patching sessions.

**Solution:**
Implement platform-adaptive bottom bar using existing `PlatformInteractionService`:
- **Desktop**: Maintain current 4 icon buttons (no change)
- **Mobile**: Single "View Options" button that opens Material 3 bottom sheet with labeled display mode options

**Business Value:**
- Improved mobile user experience (primary pain point reported by users)
- Maintains desktop power-user workflow (no regression)
- Scalable pattern for future feature additions
- Demonstrates platform-appropriate design thinking

---

## Stories

### Story 1: Platform Detection and Conditional Layout

**Story ID:** Epic-9-S1
**Priority:** P0 (Blocker for other stories)
**Estimated Effort:** 4-6 hours

**As a** developer
**I want** the bottom bar to conditionally render based on platform
**So that** mobile and desktop users each get optimal layouts

#### Acceptance Criteria

**AC1: Platform Detection**
- [ ] Bottom bar builder calls `_platformService.isMobilePlatform()` to detect platform
- [ ] Platform detection result stored in local boolean variable `isMobile`
- [ ] Detection happens on every rebuild (no caching issues)

**AC2: Desktop Layout (Connected Mode)**
- [ ] When `!isMobile` AND connected mode (`!isOffline`):
  - [ ] Row with 4 icon buttons renders (existing code path)
  - [ ] All 4 display mode buttons visible: Parameter View, Algorithm UI, Overview UI, Overview VU Meters
  - [ ] Each button has correct icon and tooltip
  - [ ] Clicking button triggers `setDisplayMode()` correctly

**AC3: Mobile Layout (Connected Mode)**
- [ ] When `isMobile` AND connected mode (`!isOffline`):
  - [ ] Single IconButton with "View Options" label renders
  - [ ] Button uses `Icons.view_list` icon
  - [ ] Button has tooltip: "View Options"
  - [ ] Button `onPressed` handler defined (can be no-op for this story)

**AC4: Other Modes Unchanged**
- [ ] Offline mode shows "Offline Data" button on both mobile and desktop
- [ ] Demo mode shows appropriate button on both mobile and desktop
- [ ] No layout regressions in offline/demo modes

**AC5: No Visual Regression**
- [ ] Bottom bar height remains consistent
- [ ] Mode switcher (Parameters/Routing) still renders correctly
- [ ] Platform-conditional elements (MCP status, version, CPU) still render correctly
- [ ] FAB spacer (80px) still present

#### Implementation Notes

**File:** `lib/ui/synchronized_screen.dart`
**Method:** `_buildBottomAppBar()` (lines ~509-646)

**Changes:**
1. Add platform detection after existing variables:
   ```dart
   bool isMobile = _platformService.isMobilePlatform();
   ```

2. Update connected mode section (currently lines ~573-614) to use conditional:
   ```dart
   if (isOffline) {
     // Existing offline button (unchanged)
     return IconButton(/* Offline Data */);
   } else {
     // New conditional for mobile vs desktop
     return isMobile
       ? IconButton(
           tooltip: "View Options",
           icon: const Icon(Icons.view_list),
           onPressed: () {}, // Will be implemented in Story 2
         )
       : Row(
           children: [
             // Existing 4 icon buttons
             IconButton(/* Parameter View */),
             IconButton(/* Algorithm UI */),
             IconButton(/* Overview UI */),
             IconButton(/* Overview VU Meters */),
           ],
         );
   }
   ```

#### Testing Checklist

**Manual Testing:**
- [ ] Run on macOS - verify 4 buttons visible
- [ ] Run on iOS simulator - verify single "View Options" button
- [ ] Run on Android emulator - verify single "View Options" button
- [ ] Test offline mode on desktop - verify unchanged
- [ ] Test offline mode on mobile - verify unchanged
- [ ] Verify no console errors or warnings

**Automated Testing:**
- [ ] Widget test: Verify desktop layout renders 4 buttons
- [ ] Widget test: Verify mobile layout renders 1 button
- [ ] Widget test: Verify offline mode renders correctly

---

### Story 2: Bottom Sheet Component Implementation

**Story ID:** Epic-9-S2
**Priority:** P0
**Estimated Effort:** 6-8 hours
**Depends On:** Epic-9-S1

**As a** mobile user
**I want** to tap "View Options" and see clearly labeled display mode choices
**So that** I can easily select the hardware display mode I need

#### Acceptance Criteria

**AC1: Bottom Sheet Method**
- [ ] Method `_showDisplayModeBottomSheet(BuildContext context)` created
- [ ] Uses `showModalBottomSheet()` from Material
- [ ] Returns bottom sheet with SafeArea wrapper
- [ ] Bottom sheet has handle indicator at top
- [ ] Bottom sheet has header: "Hardware Display Mode"

**AC2: Display Mode Options**
- [ ] Bottom sheet contains 4 options using ListTile:
  - [ ] Parameter View - icon: `Icons.list_alt_rounded`, subtitle: "Hardware parameter list"
  - [ ] Algorithm UI - icon: `Icons.line_axis_rounded`, subtitle: "Custom algorithm interface"
  - [ ] Overview UI - icon: `Icons.line_weight_rounded`, subtitle: "All slots overview"
  - [ ] Overview VU Meters - icon: `Icons.leaderboard_rounded`, subtitle: "VU meter display"
- [ ] Each option has leading icon, title, and subtitle
- [ ] Options have horizontal padding: 24px, vertical: 8px

**AC3: Interaction Behavior**
- [ ] Tapping "View Options" button opens bottom sheet
- [ ] Tapping an option calls `context.read<DistingCubit>().setDisplayMode(mode)` with correct mode
- [ ] Tapping an option auto-dismisses bottom sheet (`Navigator.pop(context)`)
- [ ] Tapping outside bottom sheet dismisses it (Material default)
- [ ] Swiping down dismisses bottom sheet (Material default)
- [ ] Android back button dismisses bottom sheet (Material default)

**AC4: Visual Polish**
- [ ] Bottom sheet animates smoothly (Material default slide-up)
- [ ] Background dims when bottom sheet opens (Material default)
- [ ] Option tiles show hover/tap feedback
- [ ] Options have adequate touch targets (56px height minimum)

**AC5: Integration**
- [ ] "View Options" button `onPressed` now calls `_showDisplayModeBottomSheet(context)`
- [ ] Display mode changes propagate to hardware correctly (same as desktop)
- [ ] No errors in debug console when opening/closing bottom sheet

#### Implementation Notes

**Add three new methods to `_SynchronizedScreenState`:**

```dart
void _showDisplayModeBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBottomSheetHeader(),
            _buildDisplayModeOption(
              context,
              icon: Icons.list_alt_rounded,
              title: 'Parameter View',
              subtitle: 'Hardware parameter list',
              mode: DisplayMode.parameters,
            ),
            _buildDisplayModeOption(
              context,
              icon: Icons.line_axis_rounded,
              title: 'Algorithm UI',
              subtitle: 'Custom algorithm interface',
              mode: DisplayMode.algorithmUI,
            ),
            _buildDisplayModeOption(
              context,
              icon: Icons.line_weight_rounded,
              title: 'Overview UI',
              subtitle: 'All slots overview',
              mode: DisplayMode.overview,
            ),
            _buildDisplayModeOption(
              context,
              icon: Icons.leaderboard_rounded,
              title: 'Overview VU Meters',
              subtitle: 'VU meter display',
              mode: DisplayMode.overviewVUs,
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildDisplayModeOption(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required DisplayMode mode,
}) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: () {
      Navigator.pop(context);
      context.read<DistingCubit>().setDisplayMode(mode);
    },
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  );
}

Widget _buildBottomSheetHeader() {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hardware Display Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
```

**Update Story 1's "View Options" button:**
```dart
IconButton(
  tooltip: "View Options",
  icon: const Icon(Icons.view_list),
  onPressed: () => _showDisplayModeBottomSheet(context),
)
```

#### Testing Checklist

**Manual Testing - iOS:**
- [ ] Tap "View Options" - bottom sheet opens
- [ ] Tap "Parameter View" - sheet closes, hardware display changes
- [ ] Tap "View Options" - tap "Algorithm UI" - verify correct mode
- [ ] Tap "View Options" - tap outside - sheet closes, no mode change
- [ ] Tap "View Options" - swipe down - sheet closes, no mode change
- [ ] Verify smooth animation (60fps)
- [ ] Verify touch targets feel comfortable

**Manual Testing - Android:**
- [ ] Repeat all iOS tests
- [ ] Press back button while sheet open - sheet closes
- [ ] Verify Material ripple effects on options

**Manual Testing - Desktop:**
- [ ] Click each of 4 icon buttons - verify modes change
- [ ] Verify no bottom sheet appears on desktop
- [ ] Verify desktop behavior unchanged from before

**Edge Cases:**
- [ ] Rapid tapping "View Options" - no crashes
- [ ] Open sheet, switch to offline mode - no crashes
- [ ] Open sheet, navigate away - sheet properly disposed

---

### Story 3: Accessibility and Polish

**Story ID:** Epic-9-S3
**Priority:** P1
**Estimated Effort:** 3-4 hours
**Depends On:** Epic-9-S2

**As a** user with accessibility needs
**I want** the bottom sheet to work with screen readers and keyboard
**So that** I can access all display mode options regardless of my abilities

#### Acceptance Criteria

**AC1: Screen Reader Support**
- [ ] "View Options" button has semantic label: "View Options button, opens display mode menu"
- [ ] Each bottom sheet option announces: "[Title]. [Subtitle]" (e.g., "Parameter View. Hardware parameter list")
- [ ] Screen reader announces when bottom sheet opens
- [ ] Screen reader announces when bottom sheet closes

**AC2: Keyboard Navigation (Desktop)**
- [ ] Tab key moves focus through bottom bar controls
- [ ] "View Options" button focusable via tab (if shown on desktop in future)
- [ ] Enter/Space on focused button opens bottom sheet
- [ ] Escape key closes bottom sheet

**AC3: Touch Target Compliance**
- [ ] Measure ListTile heights - verify >= 56px
- [ ] Verify WCAG 2.1 Level AA compliance (44x44dp minimum)
- [ ] No overlap between tappable areas

**AC4: Visual Accessibility**
- [ ] Text contrast ratios meet WCAG AA (4.5:1 for normal text)
- [ ] Icon colors meet contrast requirements
- [ ] Focus indicators visible when keyboard navigating

**AC5: Haptic Feedback (Mobile)**
- [ ] Opening bottom sheet triggers light haptic feedback (if `haptic_feedback` package already used elsewhere)
- [ ] Selecting option triggers selection haptic (if `haptic_feedback` package already used elsewhere)
- [ ] If haptics not currently used, skip this criterion

#### Implementation Notes

**Semantic Labels:**
```dart
// "View Options" button
Semantics(
  label: 'View Options',
  hint: 'Opens display mode menu',
  child: IconButton(
    tooltip: "View Options",
    icon: const Icon(Icons.view_list),
    onPressed: () => _showDisplayModeBottomSheet(context),
  ),
)

// ListTile already has good semantics by default
// But can enhance if needed:
Semantics(
  label: '$title. $subtitle',
  button: true,
  child: ListTile(/* ... */),
)
```

**Haptic Feedback (if applicable):**
```dart
// In _showDisplayModeBottomSheet
if (await Haptics.canVibrate()) {
  await Haptics.vibrate(HapticsType.light);
}

// In option onTap
if (await Haptics.canVibrate()) {
  await Haptics.vibrate(HapticsType.selection);
}
```

#### Testing Checklist

**Screen Reader Testing:**
- [ ] iOS VoiceOver: Enable, navigate to "View Options", verify announcement
- [ ] iOS VoiceOver: Open sheet, verify each option announcement
- [ ] Android TalkBack: Enable, verify same functionality
- [ ] Test double-tap to activate on mobile

**Keyboard Testing (Desktop):**
- [ ] Tab through bottom bar controls
- [ ] Focus reaches all interactive elements
- [ ] Focus indicators visible
- [ ] Escape closes modals

**Contrast Testing:**
- [ ] Use browser dev tools to measure contrast ratios
- [ ] Verify text meets 4.5:1 minimum
- [ ] Verify icons meet 3:1 minimum (large elements)

**Touch Target Testing:**
- [ ] Use Android layout bounds debugging
- [ ] Measure actual tappable area heights
- [ ] Verify no gaps or overlaps

---

### Story 4: Cross-Platform Testing and Validation

**Story ID:** Epic-9-S4
**Priority:** P0 (Must complete before release)
**Estimated Effort:** 4-6 hours
**Depends On:** Epic-9-S1, Epic-9-S2, Epic-9-S3

**As a** QA engineer / developer
**I want** to thoroughly test the implementation across all platforms and modes
**So that** we can confidently release without regressions

#### Acceptance Criteria

**AC1: Real Device Testing**
- [ ] Test on physical iPhone (not just simulator)
- [ ] Test on physical Android phone (not just emulator)
- [ ] Test on macOS desktop
- [ ] Test on Windows desktop (if applicable)
- [ ] Test on Linux desktop (if applicable)

**AC2: Mode Testing**
- [ ] Test connected mode on all platforms
- [ ] Test offline mode on all platforms
- [ ] Test demo mode on all platforms
- [ ] Verify mode transitions don't cause issues

**AC3: Display Mode Verification**
- [ ] Verify "Parameter View" actually changes hardware display
- [ ] Verify "Algorithm UI" actually changes hardware display
- [ ] Verify "Overview UI" actually changes hardware display
- [ ] Verify "Overview VU Meters" actually changes hardware display
- [ ] Verify same behavior on mobile and desktop

**AC4: Performance Testing**
- [ ] Bottom sheet animation smooth (60fps) on older devices
- [ ] No jank when opening/closing sheet
- [ ] No memory leaks (open/close 20+ times)
- [ ] No impact to app startup time

**AC5: Regression Testing**
- [ ] Desktop users: 4 buttons visible, one-tap switching works
- [ ] Mode switcher (Parameters/Routing) still works
- [ ] FAB still functions correctly
- [ ] MCP status indicator still shows (desktop)
- [ ] Version display still shows (desktop/tablet)
- [ ] CPU monitor still shows (wide screen)
- [ ] All existing bottom bar behavior unchanged

**AC6: Edge Case Testing**
- [ ] Rotate device while bottom sheet open (mobile)
- [ ] Switch between apps while sheet open
- [ ] Memory pressure scenarios
- [ ] Rapid opening/closing of sheet
- [ ] Multiple quick taps on options
- [ ] Sheet open during preset change
- [ ] Sheet open during algorithm change

#### Testing Checklist

**Platform Matrix:**

| Platform | Connected | Offline | Demo | Result |
|----------|-----------|---------|------|--------|
| iOS Physical | [ ] | [ ] | [ ] | |
| Android Physical | [ ] | [ ] | [ ] | |
| macOS | [ ] | [ ] | [ ] | |
| Windows | [ ] | [ ] | [ ] | |
| Linux | [ ] | [ ] | [ ] | |

**Performance Metrics:**
- [ ] Bottom sheet open time: < 300ms
- [ ] Animation frame rate: 60fps
- [ ] Memory stable after 20 open/close cycles
- [ ] No console warnings or errors

**Regression Checklist:**
- [ ] Desktop: All 4 buttons visible
- [ ] Desktop: Tooltips show on hover
- [ ] Desktop: One-tap mode switching works
- [ ] Mobile: No squashing in bottom bar
- [ ] Mobile: Adequate spacing between controls
- [ ] All modes: FAB functions correctly
- [ ] All modes: Mode switcher works
- [ ] Offline: "Offline Data" button works
- [ ] Demo: Appropriate button shows

**Issue Log:**
Track any bugs found during testing:

| Issue # | Description | Severity | Status | Resolution |
|---------|-------------|----------|--------|------------|
| | | | | |

---

## Epic Completion Criteria

**Definition of Done:**
- [ ] All 4 stories completed and accepted
- [ ] All acceptance criteria met
- [ ] Code reviewed and approved
- [ ] No P0 or P1 bugs outstanding
- [ ] Documentation updated (if needed)
- [ ] UX design spec archived for reference
- [ ] Release notes drafted

**Success Metrics:**
- [ ] Zero desktop regressions detected
- [ ] Mobile bottom bar no longer squashed
- [ ] All display modes accessible on mobile
- [ ] Accessibility audit passes
- [ ] Performance targets met

---

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Bottom sheet conflicts with FAB | Low | Medium | Test thoroughly, ensure proper z-index layering |
| Platform detection fails on some devices | Low | High | Use well-tested PlatformInteractionService, extensive device testing |
| Display mode changes don't propagate | Low | High | Wire up to same DistingCubit methods as desktop |
| Animation performance on old devices | Medium | Medium | Test on older hardware, optimize if needed |
| Screen reader support inconsistent | Low | Medium | Test with VoiceOver and TalkBack, iterate as needed |

---

## Dependencies

**Internal:**
- PlatformInteractionService (already exists)
- DistingCubit.setDisplayMode() (already exists)
- DisplayMode enum (already exists)

**External:**
- Flutter Material 3 components (framework)
- haptic_feedback package (if adding haptics)

**None of these require new work** - all dependencies already satisfied.

---

## Rollout Plan

**Phase 1: Internal Testing**
- Dev team tests on available devices
- Fix any critical issues

**Phase 2: Beta Release**
- Include in next beta build
- Gather feedback from beta testers
- Monitor for issues

**Phase 3: Production Release**
- Include in next production release
- Monitor crash reports
- Gather user feedback
- Track success metrics

**Rollback Plan:**
If critical issues discovered:
- Feature can be disabled by forcing desktop layout on mobile (quick hotfix)
- Full rollback possible by reverting Story 1 changes

---

## Appendix

### Reference Documents
- PRD: `docs/mobile-bottom-bar-prd.md`
- UX Specification: `docs/ux-design-specification.md`
- Interactive Mockup: `docs/mobile-bottom-bar-mockup.html`

### Code References
- Main implementation: `lib/ui/synchronized_screen.dart`
- Platform service: `lib/core/platform/platform_interaction_service.dart`
- Display modes: `lib/domain/disting_nt_sysex.dart` (DisplayMode enum)
- State management: `lib/cubit/disting_cubit.dart`

---

**Epic Version:** 1.0
**Last Updated:** 2025-11-16
**Status:** Ready for Development
