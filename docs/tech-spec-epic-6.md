# nt_helper - Technical Specification: Epic 6 Mobile Performance Page Support

**Author:** Neal
**Date:** 2025-10-29
**Project Level:** 1
**Project Type:** software
**Development Context:** brownfield

---

## Overview

**Epic 6: Mobile Performance Page Support**

**Problem:** Desktop users can assign parameters to performance pages using a dropdown on each parameter row (`section_parameter_list_view.dart` lines 272-295). On mobile devices with narrow screens, this dropdown doesn't fit alongside the parameter controls, making it impossible for mobile users to assign performance pages.

**Solution:** Add a fourth "Performance" tab to the existing Packed Mapping Data Editor bottom sheet (accessible via the mapping edit button on each parameter row). This tab will contain a single dropdown selector for assigning performance pages (0-15), providing mobile users an alternative, space-efficient way to configure performance page assignments.

**Value:** Mobile users gain full access to performance page functionality without UI cramping. The mapping editor bottom sheet is already the central location for all parameter mapping configuration (CV/MIDI/I2C), so adding Performance here creates a unified, consistent editing experience across all platforms.

---

## Source Tree Structure

### Modified Files

**Primary Changes**
- `lib/ui/widgets/packed_mapping_data_editor.dart` - Add fourth "Performance" tab with performance page dropdown selector

**No Changes Required**
- `lib/models/packed_mapping_data.dart` - Already has `perfPageIndex` field with `copyWith` support
- `lib/cubit/disting_cubit.dart` - Already has `saveMapping` method that handles performance page updates
- `lib/domain/sysex/requests/set_performance_page_message.dart` - Already handles SysEx encoding for performance page assignments
- `lib/ui/performance_screen.dart` - No changes needed (already reads from `perfPageIndex`)
- `lib/ui/widgets/section_parameter_list_view.dart` - No changes needed (desktop dropdown remains functional)

### New Files

None required - all changes are contained within the existing `PackedMappingDataEditor` widget.

### Test Files

**Modified**
- `test/ui/widgets/packed_mapping_data_editor_test.dart` - Add tests for Performance tab rendering and dropdown selection

**New**
- None required

---

## Technical Approach

### Overview

Extend the existing 3-tab `PackedMappingDataEditor` widget to include a fourth "Performance" tab. This tab will contain a single dropdown menu allowing users to assign the parameter to a performance page (1-15) or select "None" (0) to unassign it. This provides an alternative to the existing inline dropdown on desktop parameter rows.

### Key Principles

1. **Consistent Tab Pattern**: Follow the exact same pattern as CV/MIDI/I2C tabs for UI consistency
2. **Optimistic Updates**: Leverage the existing optimistic auto-save mechanism (1-second debounce) already implemented in the editor
3. **Zero New Dependencies**: Use existing Flutter Material widgets and state management patterns
4. **Dual Input Methods**: Desktop users can continue using the inline dropdown; mobile users can use the mapping editor
5. **Minimal Changes**: Add one tab, one dropdown, zero architectural changes

### Implementation Strategy

**1. Add Fourth Tab to TabController**
- Change `TabController` length from 3 to 4
- Add "Performance" label to tab bar
- Add initial index logic to select Performance tab if `perfPageIndex > 0`

**2. Build Performance Tab UI**
- Create `_buildPerformanceEditor()` method following same pattern as `_buildCvEditor()`
- Add single `DropdownMenu<int>` for page selection
- Dropdown options: "None" (0), "P1" (1), "P2" (2), ..., "P15" (15)
- Use optimistic save trigger on dropdown selection

**3. State Management**
- Leverage existing `_data.perfPageIndex` field (already in `PackedMappingData`)
- Use `_data.copyWith(perfPageIndex: newValue)` on dropdown change
- Call `_triggerOptimisticSave()` to auto-persist after 1 second

**4. Visual Design**
- Match styling of existing dropdowns (CV Input, MIDI Channel, etc.)
- Use colored page badges (P1-P15) to match Performance screen and inline dropdown visual language
- Show "None" option clearly for unassigned state

---

## Implementation Stack

### Language & Framework
- **Dart**: 3.x (as specified in project's pubspec.yaml)
- **Flutter**: 3.x (as specified in project's pubspec.yaml)

### Core Dependencies
- **flutter/material.dart**: UI components (already imported)
- **flutter_bloc**: 8.x (already in use for state management)

### Architecture Patterns
- **Stateful Widget**: `PackedMappingDataEditor` already uses `StatefulWidget`
- **Optimistic Updates**: Existing debounce pattern will be reused for Performance tab
- **Cubit Pattern**: Existing `DistingCubit.saveMapping` will handle persistence

### State Management
- **Local State**: Widget-level state via `setState` (existing pattern)
- **Global State**: BLoC pattern via `DistingCubit.saveMapping` (existing pattern)

### No New Dependencies Required
All required functionality is available in existing dependencies.

---

## Technical Details

### PackedMappingDataEditor Widget Modifications

#### Update initState() Method

**Change TabController length:**
```dart
_tabController = TabController(
  length: 4, // CHANGE FROM 3 TO 4
  vsync: this,
  initialIndex: initialIndex,
);
```

**Update initial index logic:**
```dart
int initialIndex;
if (_data.cvInput != 0) {
  initialIndex = 0; // CV tab
} else if (_data.isMidiEnabled) {
  initialIndex = 1; // MIDI tab
} else if (_data.isI2cEnabled) {
  initialIndex = 2; // I2C tab
} else if (_data.perfPageIndex > 0) {
  initialIndex = 3; // Performance tab - ADD THIS
} else {
  initialIndex = 0; // Default to CV tab
}
```

#### Update build() Method - Add Performance Tab

**In the `TabBar` widget, add fourth tab:**
```dart
TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: 'CV'),
    Tab(text: 'MIDI'),
    Tab(text: 'I2C'),
    Tab(text: 'Performance'), // ADD THIS
  ],
),
```

**In the `TabBarView` widget, add fourth child:**
```dart
TabBarView(
  controller: _tabController,
  children: [
    _buildCvEditor(),
    _buildMidiEditor(),
    _buildI2cEditor(),
    _buildPerformanceEditor(), // ADD THIS
  ],
),
```

#### New Method: Build Performance Tab

```dart
Widget _buildPerformanceEditor() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info text explaining performance pages
        Text(
          'Assign this parameter to a performance page for quick access.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),

        // Performance page dropdown
        DropdownMenu<int>(
          initialSelection: _data.perfPageIndex,
          label: const Text('Performance Page'),
          expandedInsets: EdgeInsets.zero,
          dropdownMenuEntries: [
            // "None" option
            const DropdownMenuEntry<int>(
              value: 0,
              label: 'None',
            ),
            // P1 through P15
            for (int i = 1; i <= 15; i++)
              DropdownMenuEntry<int>(
                value: i,
                label: 'P$i',
                leadingIcon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPageColor(i),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'P$i',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
          onSelected: (newValue) {
            if (newValue == null) return;
            setState(() {
              _data = _data.copyWith(perfPageIndex: newValue);
            });
            _triggerOptimisticSave();
          },
        ),

        const SizedBox(height: 16),

        // Help text
        Text(
          _data.perfPageIndex == 0
              ? 'Not assigned to any performance page'
              : 'Assigned to Performance Page ${_data.perfPageIndex}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    ),
  );
}

// Helper method to get color for page badges (reuse color scheme from section_parameter_list_view.dart)
Color _getPageColor(int pageIndex) {
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
  ];
  return colors[(pageIndex - 1) % colors.length];
}
```

### Data Flow

1. **User Opens Parameter Editor**
   - User taps mapping edit button on a parameter row
   - `MappingEditButton` shows `MappingEditorBottomSheet`
   - Bottom sheet creates `PackedMappingDataEditor` with `initialData` containing current `perfPageIndex`
   - Initial tab is selected based on which mapping types are active (including Performance if `perfPageIndex > 0`)

2. **User Selects Performance Tab**
   - Tab view switches to `_buildPerformanceEditor()`
   - Dropdown shows current assignment (0 = "None", 1-15 = "P1" through "P15")

3. **User Selects Performance Page**
   - Dropdown `onSelected` callback fires
   - `setState` updates local `_data.perfPageIndex`
   - `_triggerOptimisticSave()` starts 1-second debounce timer

4. **Auto-Save Triggers**
   - After 1 second of no changes, `_attemptSave()` is called
   - `widget.onSave(_data)` is invoked with updated `PackedMappingData`
   - Parent widget (`MappingEditorBottomSheet`) calls `DistingCubit.saveMapping()`
   - `DistingCubit` encodes and sends `SetPerformancePageMessage` via SysEx

5. **Hardware Synchronization**
   - Disting NT hardware receives SysEx message and updates parameter's performance page assignment
   - Performance screen automatically reflects the change (reads from same `perfPageIndex` field)
   - Desktop parameter row dropdown also reflects the change (both read from the same source)

---

## Development Setup

### Prerequisites
- Flutter SDK 3.x installed
- Dart SDK 3.x installed
- macOS development environment (as indicated by project structure)
- Disting NT hardware (for end-to-end testing) or mock MIDI setup

### Development Environment
```bash
# Verify Flutter installation
flutter doctor

# Get dependencies (if needed)
flutter pub get

# Run tests
flutter test

# Run app for development
flutter run -d macos --print-dtd
```

### No Additional Setup Required
This feature uses existing dependencies and architecture patterns. No new packages, tools, or configuration changes are needed.

---

## Implementation Guide

### Step 1: Update TabController Length

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `initState()` method, around line 72

**Change:**
```dart
_tabController = TabController(
  length: 4, // CHANGE FROM 3 TO 4
  vsync: this,
  initialIndex: initialIndex,
);
```

### Step 2: Add Performance Tab to Initial Index Logic

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `initState()` method, around line 56-69

**Add this condition before the final `else`:**
```dart
} else if (_data.perfPageIndex > 0) {
  // Performance page is assigned
  initialIndex = 3;
```

### Step 3: Add Performance Tab to TabBar

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `build()` method, TabBar widget, around line 140

**Change:**
```dart
TabBar(
  controller: _tabController,
  tabs: const [
    Tab(text: 'CV'),
    Tab(text: 'MIDI'),
    Tab(text: 'I2C'),
    Tab(text: 'Performance'), // ADD THIS LINE
  ],
),
```

### Step 4: Add Performance Tab to TabBarView

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `build()` method, TabBarView widget, around line 150

**Change:**
```dart
TabBarView(
  controller: _tabController,
  children: [
    _buildCvEditor(),
    _buildMidiEditor(),
    _buildI2cEditor(),
    _buildPerformanceEditor(), // ADD THIS LINE
  ],
),
```

### Step 5: Add _buildPerformanceEditor() Method

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** After `_buildI2cEditor()` method, before the end of class

**Add this complete method:**
```dart
Widget _buildPerformanceEditor() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info text explaining performance pages
        Text(
          'Assign this parameter to a performance page for quick access.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),

        // Performance page dropdown
        DropdownMenu<int>(
          initialSelection: _data.perfPageIndex,
          label: const Text('Performance Page'),
          expandedInsets: EdgeInsets.zero,
          dropdownMenuEntries: [
            // "None" option
            const DropdownMenuEntry<int>(
              value: 0,
              label: 'None',
            ),
            // P1 through P15
            for (int i = 1; i <= 15; i++)
              DropdownMenuEntry<int>(
                value: i,
                label: 'P$i',
                leadingIcon: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPageColor(i),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'P$i',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
          onSelected: (newValue) {
            if (newValue == null) return;
            setState(() {
              _data = _data.copyWith(perfPageIndex: newValue);
            });
            _triggerOptimisticSave();
          },
        ),

        const SizedBox(height: 16),

        // Help text
        Text(
          _data.perfPageIndex == 0
              ? 'Not assigned to any performance page'
              : 'Assigned to Performance Page ${_data.perfPageIndex}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    ),
  );
}
```

### Step 6: Add _getPageColor() Helper Method

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** After `_buildPerformanceEditor()` method

**Add this helper method:**
```dart
// Helper method to get color for page badges (matches section_parameter_list_view.dart and performance_screen.dart)
Color _getPageColor(int pageIndex) {
  final colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
  ];
  return colors[(pageIndex - 1) % colors.length];
}
```

### Step 7: Verification Checklist

After implementation, verify:
- [ ] TabController length is 4
- [ ] Initial index logic includes Performance tab case
- [ ] TabBar has 4 tabs (CV, MIDI, I2C, Performance)
- [ ] TabBarView has 4 children
- [ ] `_buildPerformanceEditor()` method is implemented
- [ ] `_getPageColor()` helper method is implemented
- [ ] Dropdown shows "None" and "P1" through "P15"
- [ ] Dropdown selection triggers optimistic save
- [ ] Help text updates when selection changes

---

## Testing Approach

### Unit Tests

**File**: `test/ui/widgets/packed_mapping_data_editor_test.dart`

#### Test Coverage Areas

1. **Tab Rendering**
   - Verify that 4 tabs are rendered (CV, MIDI, I2C, Performance)
   - Verify that Performance tab is selectable
   - Verify that Performance tab content is rendered correctly

2. **Initial Tab Selection**
   - Verify Performance tab is selected if `perfPageIndex > 0` and no other mappings active
   - Verify other tabs take precedence if their mappings are active

3. **Dropdown Rendering**
   - Verify dropdown shows "None" option with value 0
   - Verify dropdown shows P1-P15 options with values 1-15
   - Verify dropdown initial selection matches `_data.perfPageIndex`
   - Verify page badges are color-coded correctly

4. **Dropdown Selection**
   - Verify selecting a page updates `_data.perfPageIndex`
   - Verify selection triggers optimistic save after 1 second
   - Verify help text updates to reflect selection

5. **Help Text**
   - Verify "Not assigned" text when `perfPageIndex == 0`
   - Verify "Assigned to Performance Page N" text when `perfPageIndex > 0`

6. **Integration with Auto-Save**
   - Verify that changing performance page triggers `_triggerOptimisticSave()`
   - Verify that rapid changes trigger only one save after 1 second
   - Verify that `onSave` callback receives updated `PackedMappingData` with correct `perfPageIndex`

#### Test Implementation Examples

```dart
testWidgets('Performance tab is rendered', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PackedMappingDataEditor(
          initialData: PackedMappingData.filler(),
          slots: [],
          onSave: (_) {},
        ),
      ),
    ),
  );

  // Verify 4 tabs exist
  expect(find.text('CV'), findsOneWidget);
  expect(find.text('MIDI'), findsOneWidget);
  expect(find.text('I2C'), findsOneWidget);
  expect(find.text('Performance'), findsOneWidget);
});

testWidgets('Performance tab shows correct dropdown options', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PackedMappingDataEditor(
          initialData: PackedMappingData.filler(),
          slots: [],
          onSave: (_) {},
        ),
      ),
    ),
  );

  // Tap Performance tab
  await tester.tap(find.text('Performance'));
  await tester.pumpAndSettle();

  // Tap dropdown to expand
  await tester.tap(find.byType(DropdownMenu<int>));
  await tester.pumpAndSettle();

  // Verify "None" option exists
  expect(find.text('None'), findsOneWidget);

  // Verify P1-P15 options exist
  for (int i = 1; i <= 15; i++) {
    expect(find.text('P$i'), findsWidgets);
  }
});

testWidgets('Selecting performance page triggers optimistic save', (tester) async {
  int saveCount = 0;
  PackedMappingData? savedData;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PackedMappingDataEditor(
          initialData: PackedMappingData.filler(),
          slots: [],
          onSave: (data) {
            saveCount++;
            savedData = data;
          },
        ),
      ),
    ),
  );

  // Tap Performance tab
  await tester.tap(find.text('Performance'));
  await tester.pumpAndSettle();

  // Open dropdown and select P5
  await tester.tap(find.byType(DropdownMenu<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('P5').last);
  await tester.pumpAndSettle();

  expect(saveCount, 0); // No save yet

  // Wait for debounce timer
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();

  expect(saveCount, 1); // Save triggered
  expect(savedData?.perfPageIndex, 5); // Correct value saved
});

testWidgets('Initial tab selection prefers Performance when perfPageIndex > 0', (tester) async {
  final data = PackedMappingData.filler().copyWith(
    perfPageIndex: 3, // P3 assigned
    cvInput: 0,        // No CV
    isMidiEnabled: false, // No MIDI
    isI2cEnabled: false,  // No I2C
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: PackedMappingDataEditor(
          initialData: data,
          slots: [],
          onSave: (_) {},
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  // Verify Performance tab is selected (index 3)
  final tabController = tester.widget<PackedMappingDataEditor>(
    find.byType(PackedMappingDataEditor),
  ).createState()._tabController;

  expect(tabController.index, 3);
});
```

### Integration Tests

**Objective**: Verify end-to-end performance page assignment flow with real BLoC

1. **Full Assignment Flow via Mapping Editor**
   - User opens parameter mapping editor (clicks mapping button on parameter row)
   - User selects Performance tab
   - User selects "P7" from dropdown
   - Wait 1 second for auto-save
   - Verify `DistingCubit.saveMapping` is called with `perfPageIndex: 7`
   - Verify hardware state is updated
   - Verify Performance screen shows parameter in P7
   - Verify desktop parameter row dropdown shows P7

2. **Unassignment Flow**
   - Parameter is assigned to P3
   - User opens mapping editor
   - Performance tab is auto-selected
   - User selects "None" from dropdown
   - Wait 1 second for auto-save
   - Verify parameter is removed from Performance screen
   - Verify desktop parameter row dropdown shows "Not Assigned"

3. **Consistency Between Desktop and Mobile Methods**
   - Assign parameter to P2 via desktop inline dropdown
   - Open mapping editor
   - Verify Performance tab shows P2 selected
   - Change to P5 via mapping editor
   - Close mapping editor
   - Verify desktop inline dropdown now shows P5

### Manual Testing Checklist

**Test Environment**: macOS with Disting NT hardware connected

1. **Basic Assignment via Mapping Editor**
   - [ ] Open mapping editor for any parameter (click mapping button)
   - [ ] Select Performance tab
   - [ ] Select "P1" from dropdown
   - [ ] Wait 1 second without closing editor
   - [ ] Close editor
   - [ ] Navigate to Performance screen
   - [ ] Verify parameter appears in P1
   - [ ] Return to main screen
   - [ ] Verify desktop inline dropdown shows "Page 1"

2. **Changing Assignment**
   - [ ] Assign parameter to P2 via desktop dropdown
   - [ ] Open mapping editor
   - [ ] Verify Performance tab shows "P2" selected
   - [ ] Change to P5
   - [ ] Wait 1 second
   - [ ] Close editor
   - [ ] Verify parameter moved from P2 to P5 in Performance screen
   - [ ] Verify desktop inline dropdown shows "Page 5"

3. **Unassignment**
   - [ ] Assign parameter to P3
   - [ ] Open mapping editor
   - [ ] Select "None" from dropdown
   - [ ] Wait 1 second
   - [ ] Verify parameter removed from Performance screen
   - [ ] Verify desktop inline dropdown shows "Not Assigned"

4. **Visual Verification**
   - [ ] Verify colored page badges (P1-P15) match colors in Performance screen and desktop dropdown
   - [ ] Verify help text shows correct assignment status
   - [ ] Verify dropdown UI matches other dropdowns in the editor

5. **Tab Selection Priority**
   - [ ] Create parameter with only perfPageIndex set (no CV/MIDI/I2C)
   - [ ] Open mapping editor
   - [ ] Verify Performance tab is auto-selected

6. **Mobile Screen Testing** (if possible)
   - [ ] Test on narrow screen or resize window to mobile width
   - [ ] Verify desktop inline dropdown is hidden or cramped (current behavior)
   - [ ] Open mapping editor
   - [ ] Verify Performance tab is accessible and usable
   - [ ] Verify dropdown doesn't overflow or clip
   - [ ] Successfully assign performance page via mapping editor

### Performance Testing

1. **Memory**: Verify no widget leaks when opening/closing editor multiple times
2. **Responsiveness**: Verify UI remains smooth when scrolling dropdown options
3. **Debounce**: Verify rapid selections don't cause excessive save calls

### Regression Testing

After implementation:
- [ ] Run full test suite: `flutter test`
- [ ] Run static analysis: `flutter analyze` (must pass with zero warnings)
- [ ] Verify existing CV/MIDI/I2C tabs still function correctly
- [ ] Verify optimistic auto-save still works on other tabs
- [ ] Verify Performance screen still displays parameters correctly
- [ ] Verify desktop inline dropdown still functions correctly
- [ ] Verify both methods (desktop dropdown + mapping editor) stay synchronized

---

## Deployment Strategy

### Pre-Deployment

1. **Code Review**
   - Review all changes to `packed_mapping_data_editor.dart`
   - Verify TabController length is 4
   - Verify all 4 tabs are added to TabBar and TabBarView
   - Verify `_buildPerformanceEditor()` follows existing patterns
   - Verify optimistic save is triggered on dropdown selection

2. **Static Analysis**
   ```bash
   flutter analyze
   ```
   Must pass with zero warnings (per project requirements)

3. **Unit Tests**
   ```bash
   flutter test test/ui/widgets/packed_mapping_data_editor_test.dart
   ```
   All tests must pass

4. **Full Test Suite**
   ```bash
   flutter test
   ```
   All existing tests must continue to pass (no regressions)

### Deployment Steps

This is a Level 1 feature addition to an existing brownfield project. No special deployment procedures are required beyond standard development workflow.

1. **Local Testing**
   - Test on macOS development machine
   - Verify with real Disting NT hardware if available
   - Complete manual testing checklist
   - Test both desktop inline dropdown and mobile mapping editor methods

2. **Commit Changes**
   ```bash
   git add lib/ui/widgets/packed_mapping_data_editor.dart
   git add test/ui/widgets/packed_mapping_data_editor_test.dart
   git commit -m "feat: Add Performance tab to Packed Mapping Parameter editor for mobile support

   - Add fourth tab for performance page assignment
   - Add dropdown selector for P1-P15 or None
   - Use color-coded page badges matching Performance screen
   - Leverage existing optimistic auto-save mechanism
   - Provides mobile-friendly alternative to desktop inline dropdown
   - Both methods (inline dropdown + mapping editor) stay synchronized

   Epic 6: Mobile Performance Page Support

   🤖 Generated with [Claude Code](https://claude.com/claude-code)

   Co-Authored-By: Claude <noreply@anthropic.com>"
   ```

3. **Push to Remote**
   ```bash
   git push
   ```

4. **Version Bump** (if creating release)
   ```bash
   ./version patch && git push && git push --tags
   ```

### Post-Deployment

1. **Monitoring**
   - Monitor for any crash reports related to tab rendering
   - Watch for user feedback on Performance tab usability
   - Monitor for any synchronization issues between desktop dropdown and mapping editor

2. **User Communication** (if needed)
   - Update release notes to mention Performance tab addition in mapping editor
   - Note that performance page assignment now has two methods: desktop inline dropdown and mapping editor
   - Explain that both methods are synchronized and work interchangeably

3. **Rollback Plan**
   If issues arise, the feature can be rolled back by:
   - Reverting TabController length back to 3
   - Removing Performance tab from TabBar and TabBarView
   - Removing `_buildPerformanceEditor()` and `_getPageColor()` methods
   - Removing initial index logic for Performance tab
   - Original functionality is preserved (desktop inline dropdown still works)

### Risk Assessment

**Low Risk** - This is an additive feature that:
- Does not remove existing functionality (desktop inline dropdown unchanged)
- Uses well-established patterns (tabs, dropdowns, optimistic updates)
- Has isolated scope (single widget file)
- Reuses existing data model and persistence layer
- Both input methods use the same underlying data field (`perfPageIndex`)
- Can be easily rolled back if needed

### Success Metrics

Post-deployment, consider tracking:
- Mobile user adoption of Performance tab vs. desktop inline dropdown usage
- User feedback on mapping editor workflow
- Any reported synchronization issues between the two input methods
- Mobile user engagement with Performance pages

---

## Additional Notes

### Design Decisions

1. **Why add to mapping editor instead of creating a separate mobile UI?**
   - Mapping editor is already the central location for all parameter configuration
   - Maintains consistency: CV/MIDI/I2C/Performance all in one place
   - Users already know how to access mapping editor (mapping button on each parameter)
   - No need to introduce a new UI paradigm or navigation pattern

2. **Why keep the desktop inline dropdown?**
   - Desktop users benefit from quick, in-place editing without opening a modal
   - No need to change working desktop UX to fix mobile issue
   - Both methods serve different use cases: desktop = quick inline edit, mobile = detailed modal edit

3. **Why use colored badges in dropdown?**
   - Creates visual continuity with Performance screen and desktop inline dropdown
   - Helps users recognize pages by color (especially helpful on mobile)
   - Improves accessibility through both color and text labels

4. **Why not hide the desktop dropdown on mobile?**
   - Out of scope for Epic 6 (this tech spec focuses on adding the alternative method)
   - Responsive hiding could be added in a future enhancement if needed
   - Current approach is additive only (no changes to existing UI)

### Future Enhancements (Out of Scope for Epic 6)

- Conditionally hide desktop inline dropdown on narrow screens (responsive design)
- Add "quick assign" button directly on parameter rows in main screen
- Add bulk assignment tool for assigning multiple parameters to same page
- Add visual preview of current performance page layout in editor
- Add drag-and-drop reordering of parameters within performance pages

---

## Acceptance Criteria

Epic 6 is complete when:

1. **Performance Tab Exists**
   - PackedMappingDataEditor has fourth tab labeled "Performance"
   - Tab is selectable and displays performance page dropdown

2. **Dropdown Functions Correctly**
   - Dropdown shows "None" option (value 0)
   - Dropdown shows P1-P15 options (values 1-15)
   - Dropdown displays colored page badges matching Performance screen and desktop dropdown
   - Dropdown initial selection matches current `perfPageIndex`

3. **Assignment Works**
   - Selecting a page assigns parameter to that performance page
   - Selecting "None" unassigns parameter from all performance pages
   - Changes auto-save after 1 second (optimistic update)
   - Performance screen reflects assignments immediately after save
   - Desktop inline dropdown reflects assignments immediately after save

4. **Synchronization Works**
   - Changing performance page via desktop inline dropdown updates mapping editor Performance tab
   - Changing performance page via mapping editor Performance tab updates desktop inline dropdown
   - Both methods read from and write to the same `perfPageIndex` field

5. **Initial Tab Selection**
   - Performance tab auto-selects when `perfPageIndex > 0` and no other mappings active
   - Other tabs take precedence if their mappings are active

6. **Quality Requirements**
   - `flutter analyze` passes with zero warnings
   - All existing tests continue to pass
   - New tests verify Performance tab functionality
   - Manual testing checklist completed on macOS and mobile (if available)
   - No regressions in existing mapping editor tabs (CV/MIDI/I2C)
   - No regressions in desktop inline dropdown functionality

7. **Documentation**
   - Tech spec created and reviewed
   - Commit message follows project standards
   - Code comments explain Performance tab purpose and relationship to desktop inline dropdown
