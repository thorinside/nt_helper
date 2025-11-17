# nt_helper UX Design Specification

_Created on 2025-11-16 by Neal_
_Generated using BMad Method - Create UX Design Workflow v1.0_

---

## Executive Summary

**Project:** Mobile UI Bottom Bar Optimization
**Problem:** Bottom navigation bar is squashed on mobile devices in connected mode, preventing all display mode icons from being shown clearly
**Solution:** Adaptive bottom bar that shows full controls on desktop, compact bottom sheet pattern on mobile
**Impact:** Clean mobile experience while preserving desktop power-user workflow

---

## 1. Current State Analysis

### 1.1 Problem Statement

The bottom navigation bar (`_buildBottomAppBar()`) contains multiple controls that become squashed on mobile devices:

**Connected Mode Bottom Bar Contents:**
- **Left**: Parameters/Routing mode switcher (SegmentedButton - 2 segments)
- **Middle**: Display mode controls (4 IconButtons)
  - Parameter View
  - Algorithm UI
  - Overview UI
  - Overview VU Meters
- **Right**: Platform-conditional elements
  - MCP Status (desktop only)
  - Disting Version (tablet/desktop only)
  - CPU Monitor (wide screen only)
  - 80px FAB spacer

**Total on Mobile**: 6 interactive controls competing for horizontal space

### 1.2 Context: Display Mode Controls

Critical understanding: These 4 display mode buttons **control the hardware NT device's display**, not the app UI. Musicians need quick access to switch the hardware display during patching/performance.

### 1.3 Bottom Bar State Variations

The bottom bar has conditional layouts based on connection mode:

| Mode | Controls Shown | Mobile Issues? |
|------|---------------|----------------|
| **Connected** | 6+ controls (mode switcher + 4 display buttons + platform conditionals) | ✗ **Squashed** |
| **Offline** | 1 control (Offline Data button) | ✓ Works fine |
| **Demo** | (Same as offline) | ✓ Works fine |

**Conclusion**: Only connected mode requires UX optimization.

---

## 2. Design System Foundation

### 2.1 Design System Choice

**Current**: Flutter Material 3 design system (already established in app)
**Approach**: Use Material 3 bottom sheet components for mobile optimization
**Rationale**: Maintains consistency with existing app design language

---

## 3. Core User Experience Design

### 3.1 Design Approach: Adaptive Bottom Bar

**Strategy**: Platform-adaptive layout using existing `PlatformInteractionService`

**Desktop Experience** (`!isMobilePlatform()`):
- Maintain current 4 icon buttons for display modes
- One-tap hardware display switching
- Optimized for power users and mouse/keyboard interaction

**Mobile Experience** (`isMobilePlatform()`):
- Single "View" button replaces 4 icon buttons
- Opens modal bottom sheet with display mode options
- Optimized for touch, large targets, clarity over speed

**Rationale**:
- Desktop users (primary platform) maintain fast workflow
- Mobile users get clean, uncluttered bottom bar
- Musicians can still quickly control hardware display, just with one extra tap on mobile
- Scales better for future display mode additions

### 3.2 Bottom Sheet Interaction Design

**Trigger**: Single IconButton with "View Options" icon (e.g., `Icons.view_list` or `Icons.visibility`)

**Bottom Sheet Characteristics**:
- **Modal**: Dims background, focuses user attention
- **Dismissible**: Swipe down or tap outside to close
- **Auto-dismiss**: Automatically closes after selection
- **Total interaction**: Tap button → Tap mode → Done (2 taps)

**Content Layout**:
```
┌─────────────────────────────────┐
│  Hardware Display Mode          │  ← Header
├─────────────────────────────────┤
│  🗂️  Parameter View              │  ← Large touch target
│     Hardware parameter list     │     with icon + label + description
├─────────────────────────────────┤
│  📊  Algorithm UI                │
│     Custom algorithm interface  │
├─────────────────────────────────┤
│  📋  Overview UI                 │
│     All slots overview          │
├─────────────────────────────────┤
│  📈  Overview VU Meters          │
│     VU meter display            │
└─────────────────────────────────┘
```

**Touch Target Specs**:
- Minimum height: 56px (Material 3 guideline)
- Full-width tappable area
- Clear visual feedback on tap

**Accessibility**:
- Screen reader announces: "View Options button, opens display mode menu"
- Each option properly labeled for TalkBack/VoiceOver
- Keyboard accessible (tab navigation, enter to select)

---

## 4. Component Specifications

### 4.1 Bottom Bar Component (Modified)

**File**: `lib/ui/synchronized_screen.dart` - `_buildBottomAppBar()`

**Current Implementation** (lines 509-646):
- Conditional layout based on `isOffline` state
- Platform-conditional elements (MCP status, version, CPU monitor)

**Required Changes**:

**Add platform detection**:
```dart
bool isMobile = _platformService.isMobilePlatform();
```

**Desktop layout** (`!isMobile` && `!isOffline`):
```dart
// Keep existing Row with 4 IconButtons:
Row(
  children: [
    IconButton(/* Parameter View */),
    IconButton(/* Algorithm UI */),
    IconButton(/* Overview UI */),
    IconButton(/* Overview VU Meters */),
  ],
)
```

**Mobile layout** (`isMobile` && `!isOffline`):
```dart
IconButton(
  tooltip: "View Options",
  icon: const Icon(Icons.view_list),
  onPressed: () => _showDisplayModeBottomSheet(context),
)
```

### 4.2 New Component: Display Mode Bottom Sheet

**Purpose**: Mobile-optimized display mode selector

**Implementation**:
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
```

**Helper Component - Bottom Sheet Option**:
```dart
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
      Navigator.pop(context); // Auto-dismiss
      context.read<DistingCubit>().setDisplayMode(mode);
    },
    contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
  );
}

Widget _buildBottomSheetHeader() {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Text(
      'Hardware Display Mode',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
```

---

## 5. User Journey Flows

### 5.1 Display Mode Change - Desktop
1. User clicks desired display mode icon button
2. Hardware display immediately changes
3. **Total**: 1 tap

### 5.2 Display Mode Change - Mobile
1. User taps "View Options" button in bottom bar
2. Bottom sheet slides up with 4 options
3. User taps desired display mode
4. Bottom sheet auto-dismisses
5. Hardware display changes
6. **Total**: 2 taps

### 5.3 Edge Cases
- **Rapid mode switching**: Desktop maintains advantage with direct buttons
- **Accidental dismissal**: User can tap button again, no state lost
- **Offline/Demo mode**: No changes, existing single-button layout works

---

## 6. UX Pattern Decisions

### 6.1 Platform Adaptivity Pattern

**Decision**: Use `PlatformInteractionService.isMobilePlatform()` for layout switching
**Rationale**:
- Consistent with existing codebase patterns
- More reliable than width-based breakpoints
- Accounts for platform interaction paradigms (touch vs mouse)

### 6.2 Modal Interaction Pattern

**Decision**: Modal bottom sheet with auto-dismiss on selection
**Rationale**:
- Standard Material Design pattern for mobile
- Clear focus, no ambiguity about interaction state
- Auto-dismiss reduces tap count vs manual close button

### 6.3 Icon Selection

**Desktop icons**: Maintain existing icons (already familiar to users)
**Mobile button icon**: `Icons.view_list` or `Icons.visibility`
**Rationale**: Suggests "view options" without being overly specific

---

## 7. Responsive Design & Accessibility

### 7.1 Platform Strategy

**Platform Detection**: `PlatformInteractionService.isMobilePlatform()`

**Desktop Platforms** (macOS, Windows, Linux):
- Full icon button layout
- Mouse hover tooltips
- Keyboard shortcuts possible

**Mobile Platforms** (iOS, Android):
- Compact bottom sheet layout
- Touch-optimized (56px minimum touch targets)
- Swipe gestures (dismiss bottom sheet)

### 7.2 Accessibility

**Desktop**:
- Tooltips on icon buttons (already implemented)
- Keyboard navigation support
- Screen reader announces icon button purposes

**Mobile**:
- "View Options" button has clear semantic label
- Bottom sheet options use ListTile with proper semantics
- Each option announces: "Parameter View, Hardware parameter list"
- Swipe-to-dismiss gesture discoverable

**WCAG Compliance**:
- Touch targets meet minimum 44x44dp (we use 56px)
- Color contrast maintained from existing design
- Focus indicators visible on all interactive elements

---

## 8. Implementation Guidance

### 8.1 Development Approach

**Phase 1: Extract Display Mode Controls**
1. Extract the 4 display mode icon buttons into a separate method
2. Keeps code DRY, used by both desktop and bottom sheet

**Phase 2: Add Bottom Sheet Components**
1. Create `_showDisplayModeBottomSheet()` method
2. Create `_buildDisplayModeOption()` helper
3. Create `_buildBottomSheetHeader()` helper

**Phase 3: Update Bottom Bar Logic**
1. Add `isMobile` detection using `_platformService.isMobilePlatform()`
2. Update conditional logic in connected mode section:
   - Desktop: Show existing Row with 4 buttons
   - Mobile: Show single "View Options" button

**Phase 4: Testing**
1. Test on iOS simulator/device
2. Test on Android emulator/device
3. Test on desktop platforms (verify no regression)
4. Test offline/demo modes (verify unchanged)
5. Test accessibility with screen readers

### 8.2 Files to Modify

**Primary**:
- `lib/ui/synchronized_screen.dart` (lines 509-646)
  - `_buildBottomAppBar()` - Add platform detection and conditional layout
  - Add new methods: `_showDisplayModeBottomSheet()`, `_buildDisplayModeOption()`, `_buildBottomSheetHeader()`

**No new files required** - all changes within existing component

### 8.3 Risk Assessment

**Low Risk Changes**:
- Bottom sheet is new code path, doesn't affect desktop
- Platform detection already used elsewhere in codebase
- Material bottom sheet is well-tested Flutter component

**Testing Focus**:
- Verify desktop behavior unchanged
- Verify offline/demo modes unchanged
- Test bottom sheet dismissal (tap outside, swipe, back button)
- Verify display mode changes propagate to hardware correctly

### 8.4 Success Criteria

✓ Desktop users see no change in behavior (4 icon buttons visible)
✓ Mobile users see single "View Options" button
✓ Bottom sheet opens on mobile with 4 clearly labeled options
✓ Selecting an option dismisses sheet and changes hardware display mode
✓ Bottom bar no longer squashed on mobile devices
✓ All 4 display modes accessible on mobile
✓ Offline/demo modes unchanged
✓ Screen readers can navigate bottom sheet options

---

## 9. Completion Summary

### 9.1 What We Designed

**Problem Solved**: Mobile bottom navigation bar squashing due to 6+ controls competing for horizontal space

**Solution Implemented**: Platform-adaptive bottom bar
- **Desktop**: Maintain current 4 icon buttons (no change)
- **Mobile**: Single "View Options" button → modal bottom sheet with labeled options

**Key Decisions**:
1. Use existing `PlatformInteractionService.isMobilePlatform()` for detection
2. Material 3 modal bottom sheet pattern for mobile
3. Auto-dismiss on selection for efficiency
4. Large touch targets (56px) with icon + label + description
5. Only modify connected mode (offline/demo unchanged)

### 9.2 Impact

**Desktop Users**: No impact, workflow unchanged
**Mobile Users**: Clean bottom bar, clear display mode options, one extra tap
**Codebase**: Minimal changes, stays within existing patterns
**Future**: Scalable pattern for adding more display modes

### 9.3 Deliverables

- ✅ UX Design Specification: `/Users/nealsanche/nosuch/nt_helper/docs/ux-design-specification.md`
- ✅ Interactive Visual Mockup: `/Users/nealsanche/nosuch/nt_helper/docs/mobile-bottom-bar-mockup.html`
- ✅ Component specifications with code examples
- ✅ User journey flows documented
- ✅ Accessibility requirements defined
- ✅ Implementation guidance provided

### 9.4 Next Steps

**Ready for Implementation**:
This UX specification contains sufficient detail for development:
- Exact component structure
- Code examples for new methods
- Platform detection strategy
- Testing criteria

**Recommended Next Actions**:
1. Review specification with Neal for approval
2. Create epic/PRD document based on this UX spec
3. Break down into development stories
4. Implement Phase 1-4 as outlined
5. Test on all platforms
6. Gather user feedback post-launch

---

## Appendix

### Related Documents

- Product Requirements: `{{prd_file}}`
- Product Brief: `{{brief_file}}`
- Brainstorming: `{{brainstorm_file}}`

### Core Interactive Deliverables

This UX Design Specification was created through visual collaboration:

- **Color Theme Visualizer**: {{color_themes_html}}
  - Interactive HTML showing all color theme options explored
  - Live UI component examples in each theme
  - Side-by-side comparison and semantic color usage

- **Design Direction Mockups**: {{design_directions_html}}
  - Interactive HTML with 6-8 complete design approaches
  - Full-screen mockups of key screens
  - Design philosophy and rationale for each direction

### Optional Enhancement Deliverables

_This section will be populated if additional UX artifacts are generated through follow-up workflows._

<!-- Additional deliverables added here by other workflows -->

### Next Steps & Follow-Up Workflows

This UX Design Specification can serve as input to:

- **Wireframe Generation Workflow** - Create detailed wireframes from user flows
- **Figma Design Workflow** - Generate Figma files via MCP integration
- **Interactive Prototype Workflow** - Build clickable HTML prototypes
- **Component Showcase Workflow** - Create interactive component library
- **AI Frontend Prompt Workflow** - Generate prompts for v0, Lovable, Bolt, etc.
- **Solution Architecture Workflow** - Define technical architecture with UX context

### Version History

| Date     | Version | Changes                         | Author        |
| -------- | ------- | ------------------------------- | ------------- |
| 2025-11-16 | 1.0     | Initial UX Design Specification | Neal |

---

_This UX Design Specification was created through collaborative design facilitation, not template generation. All decisions were made with user input and are documented with rationale._
