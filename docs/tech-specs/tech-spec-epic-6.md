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
- `lib/ui/widgets/section_parameter_list_view.dart` - Hide inline performance page dropdown on mobile screens (desktop only)
- `lib/ui/widgets/mapping_editor_bottom_sheet.dart` - Pass algorithmIndex and parameterNumber to enable direct cubit calls

**No Changes Required**
- `lib/models/packed_mapping_data.dart` - Already has `perfPageIndex` field with `copyWith` support
- `lib/cubit/disting_cubit.dart` - Already has `setPerformancePageMapping` method with optimistic updates and hardware sync
- `lib/domain/sysex/requests/set_performance_page_message.dart` - Already handles SysEx encoding for performance page assignments
- `lib/ui/performance_screen.dart` - No changes needed (already reads from `perfPageIndex`)

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
2. **Match Inline Dropdown Behavior**: Call `DistingCubit.setPerformancePageMapping()` directly (same as inline dropdown) for optimistic updates and hardware sync
3. **Desktop-Only Inline Dropdown**: Hide the inline performance page dropdown on mobile screens using responsive layout checks
4. **Zero New Dependencies**: Use existing Flutter Material widgets and state management patterns
5. **Dual Input Methods**: Desktop users can continue using the inline dropdown; mobile users can use the mapping editor
6. **Minimal Changes**: Add one tab, hide inline dropdown on mobile, zero architectural changes

### Implementation Strategy

**1. Hide Inline Dropdown on Mobile**
- Modify `section_parameter_list_view.dart` to conditionally show performance page dropdown
- Use `MediaQuery` to detect narrow screens (width < 600px = mobile)
- Desktop: Show inline dropdown as before
- Mobile: Hide inline dropdown (use mapping editor instead)

**2. Update Mapping Editor Bottom Sheet**
- Pass `algorithmIndex` and `parameterNumber` to `PackedMappingDataEditor`
- Remove `onSave` callback pattern (no longer needed)
- Editor will call `DistingCubit.setPerformancePageMapping()` directly

**3. Add Fourth Tab to TabController**
- Change `TabController` length from 3 to 4
- Add "Performance" label to tab bar
- Add initial index logic to select Performance tab if `perfPageIndex > 0`

**4. Build Performance Tab UI**
- Create `_buildPerformanceEditor()` method following same pattern as `_buildCvEditor()`
- Add single `DropdownMenu<int>` for page selection
- Dropdown options: "None" (0), "P1" (1), "P2" (2), ..., "P15" (15)
- Call `DistingCubit.setPerformancePageMapping()` on selection (matches inline dropdown behavior)

**5. State Management**
- Read current `perfPageIndex` from `DistingCubit` state (NOT from local `_data`)
- Call `context.read<DistingCubit>().setPerformancePageMapping(algorithmIndex, parameterNumber, newValue)`
- This triggers optimistic state update + hardware sync + verification (same as inline dropdown)
- DistingCubit emits new state with updated mapping
- Widget rebuilds automatically via BLoC pattern

**6. Visual Design**
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
   - Bottom sheet creates `PackedMappingDataEditor` with `algorithmIndex` and `parameterNumber`
   - Editor reads current `perfPageIndex` from `DistingCubit` state via `BlocBuilder`
   - Initial tab is selected based on which mapping types are active (including Performance if `perfPageIndex > 0`)

2. **User Selects Performance Tab**
   - Tab view switches to `_buildPerformanceEditor()`
   - Dropdown shows current assignment from cubit state (0 = "None", 1-15 = "P1" through "P15")

3. **User Selects Performance Page**
   - Dropdown `onSelected` callback fires
   - Immediately calls `context.read<DistingCubit>().setPerformancePageMapping(algorithmIndex, parameterNumber, newValue)`
   - **EXACT SAME PATTERN AS INLINE DROPDOWN** in `section_parameter_list_view.dart:278`

4. **DistingCubit Optimistic Update** (from `setPerformancePageMapping`)
   - Creates optimistic `Mapping` with updated `perfPageIndex` (lines 1701-1707)
   - **Emits new state immediately** with updated mapping (lines 1710-1722)
   - All widgets listening to `DistingCubit` rebuild instantly
   - Performance tab dropdown updates to show new selection
   - Inline dropdown (if visible on desktop) updates to show new selection
   - Performance screen updates to show new assignment

5. **Hardware Synchronization** (from `setPerformancePageMapping`)
   - Sends `SetPerformancePageMessage` to hardware via SysEx (line 1726)
   - Verifies by reading back mapping from hardware with exponential backoff retries (lines 1731-1779)
   - If hardware value differs from optimistic value, hardware wins and cubit emits corrected state
   - All widgets automatically update to hardware's actual value

6. **UI Consistency**
   - Both inline dropdown (desktop) and Performance tab (mobile) read from same cubit state
   - Both call same `setPerformancePageMapping()` method
   - Changes from either source are instantly reflected in both UIs
   - Performance screen always shows current cubit state

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

### Step 1: Hide Inline Performance Dropdown on Mobile

**File:** `lib/ui/widgets/section_parameter_list_view.dart`

**Location:** Around lines 265-295 (performance page dropdown section)

**Wrap the dropdown Row with conditional visibility:**
```dart
// Only show inline dropdown on desktop (width >= 600)
if (MediaQuery.of(context).size.width >= 600)
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // ... existing dropdown code ...
    ],
  ),
```

**Rationale:** Mobile users will use the Performance tab in the mapping editor instead.

### Step 2: Update Mapping Editor Bottom Sheet

**File:** `lib/ui/widgets/mapping_editor_bottom_sheet.dart`

**Pass `algorithmIndex` and `parameterNumber` to editor:**
```dart
PackedMappingDataEditor(
  initialData: data,
  slots: slots,
  algorithmIndex: algorithmIndex,  // ADD THIS
  parameterNumber: parameterNumber, // ADD THIS
  // REMOVE onSave callback - no longer needed
),
```

### Step 3: Update PackedMappingDataEditor Constructor

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Add new required parameters:**
```dart
class PackedMappingDataEditor extends StatefulWidget {
  final PackedMappingData initialData;
  final List<Slot> slots;
  final int algorithmIndex;     // ADD THIS
  final int parameterNumber;    // ADD THIS
  // REMOVE: final Function(PackedMappingData) onSave;

  const PackedMappingDataEditor({
    super.key,
    required this.initialData,
    required this.slots,
    required this.algorithmIndex,     // ADD THIS
    required this.parameterNumber,    // ADD THIS
    // REMOVE: required this.onSave,
  });
}
```

### Step 4: Update TabController Length

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `initState()` method

**Change:**
```dart
_tabController = TabController(
  length: 4, // CHANGE FROM 3 TO 4
  vsync: this,
  initialIndex: initialIndex,
);
```

### Step 5: Add Performance Tab to Initial Index Logic

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `initState()` method, initial index calculation

**Add this condition before the final `else`:**
```dart
} else if (_data.perfPageIndex > 0) {
  // Performance page is assigned
  initialIndex = 3;
```

### Step 6: Add Performance Tab to TabBar

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `build()` method, TabBar widget

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

### Step 7: Add Performance Tab to TabBarView

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** `build()` method, TabBarView widget

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

### Step 8: Add _buildPerformanceEditor() Method

**File:** `lib/ui/widgets/packed_mapping_data_editor.dart`

**Location:** After `_buildI2cEditor()` method, before the end of class

**Add this complete method (uses BlocBuilder to read cubit state):**
```dart
Widget _buildPerformanceEditor() {
  return BlocBuilder<DistingCubit, DistingState>(
    builder: (context, state) {
      if (state is! DistingStateSynchronized) {
        return const Center(child: Text('Not synchronized'));
      }

      final slot = state.slots[widget.algorithmIndex];
      final currentPerfPageIndex = slot.mappings[widget.parameterNumber].packedMappingData.perfPageIndex;

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
              initialSelection: currentPerfPageIndex,
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
                // Call cubit directly - SAME AS INLINE DROPDOWN
                context.read<DistingCubit>().setPerformancePageMapping(
                  widget.algorithmIndex,
                  widget.parameterNumber,
                  newValue,
                );
              },
            ),

            const SizedBox(height: 16),

            // Help text
            Text(
              currentPerfPageIndex == 0
                  ? 'Not assigned to any performance page'
                  : 'Assigned to Performance Page $currentPerfPageIndex',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      );
    },
  );
}
```

**Key Changes from Original Tech Spec:**
- Wraps entire widget in `BlocBuilder` to read cubit state
- Reads `currentPerfPageIndex` from cubit state, NOT from local `_data`
- Dropdown `initialSelection` uses cubit state value
- `onSelected` calls `context.read<DistingCubit>().setPerformancePageMapping()` directly
- NO `setState`, NO `_triggerOptimisticSave()` - cubit handles everything
- Widget auto-rebuilds when cubit emits new state

### Step 9: Add _getPageColor() Helper Method

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

### Step 10: Verification Checklist

After implementation, verify:
- [ ] Inline dropdown hidden on mobile (width < 600px) in `section_parameter_list_view.dart`
- [ ] `MappingEditorBottomSheet` passes `algorithmIndex` and `parameterNumber` to editor
- [ ] `PackedMappingDataEditor` constructor has `algorithmIndex` and `parameterNumber` parameters
- [ ] `PackedMappingDataEditor` NO LONGER has `onSave` callback
- [ ] TabController length is 4
- [ ] Initial index logic includes Performance tab case (`perfPageIndex > 0`)
- [ ] TabBar has 4 tabs (CV, MIDI, I2C, Performance)
- [ ] TabBarView has 4 children
- [ ] `_buildPerformanceEditor()` uses `BlocBuilder<DistingCubit, DistingState>`
- [ ] Dropdown reads `currentPerfPageIndex` from cubit state
- [ ] Dropdown calls `context.read<DistingCubit>().setPerformancePageMapping()`
- [ ] `_getPageColor()` helper method is implemented
- [ ] Dropdown shows "None" and "P1" through "P15"
- [ ] Help text updates when cubit emits new state

---

## Testing Approach

### Unit Tests

**File**: `test/ui/widgets/packed_mapping_data_editor_test.dart`

#### Test Coverage Areas

1. **Tab Rendering**
   - Verify that 4 tabs are rendered (CV, MIDI, I2C, Performance)
   - Verify that Performance tab is selectable
   - Verify that Performance tab content is rendered correctly with BlocBuilder

2. **Initial Tab Selection**
   - Verify Performance tab is selected if `perfPageIndex > 0` and no other mappings active
   - Verify other tabs take precedence if their mappings are active

3. **Dropdown Rendering**
   - Verify dropdown shows "None" option with value 0
   - Verify dropdown shows P1-P15 options with values 1-15
   - Verify dropdown `initialSelection` matches cubit state `perfPageIndex`
   - Verify page badges are color-coded correctly

4. **Dropdown Selection and Cubit Integration** (CRITICAL)
   - Verify selecting a page calls `DistingCubit.setPerformancePageMapping()` with correct parameters
   - Verify cubit emits new state with updated `perfPageIndex`
   - Verify widget rebuilds with new cubit state
   - Verify help text updates to reflect new cubit state

5. **Help Text**
   - Verify "Not assigned" text when cubit state `perfPageIndex == 0`
   - Verify "Assigned to Performance Page N" text when cubit state `perfPageIndex > 0`

6. **Cubit State Management** (NEW - REQUIRED)
   - Verify widget reads `perfPageIndex` from `DistingCubit` state via `BlocBuilder`
   - Verify widget does NOT maintain local `perfPageIndex` state
   - Verify widget rebuilds when cubit emits new state
   - Verify both inline dropdown (desktop) and Performance tab (mobile) stay synchronized via cubit

#### Test Implementation Examples

**IMPORTANT:** All tests must use `MockDistingCubit` or real `DistingCubit` wrapped in `BlocProvider` since the Performance tab reads state from the cubit.

```dart
testWidgets('Performance tab is rendered with BlocBuilder', (tester) async {
  final cubit = MockDistingCubit();
  final mockState = createMockSynchronizedState(
    slots: [createMockSlot(algorithmIndex: 0, perfPageIndex: 0)],
  );
  when(() => cubit.state).thenReturn(mockState);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: PackedMappingDataEditor(
            initialData: PackedMappingData.filler(),
            slots: mockState.slots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
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

testWidgets('Performance tab dropdown shows correct initial value from cubit', (tester) async {
  final cubit = MockDistingCubit();
  final mockState = createMockSynchronizedState(
    slots: [createMockSlot(algorithmIndex: 0, perfPageIndex: 7)], // P7 assigned
  );
  when(() => cubit.state).thenReturn(mockState);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: PackedMappingDataEditor(
            initialData: PackedMappingData.filler(),
            slots: mockState.slots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
        ),
      ),
    ),
  );

  // Tap Performance tab
  await tester.tap(find.text('Performance'));
  await tester.pumpAndSettle();

  // Verify help text shows P7 assignment
  expect(find.text('Assigned to Performance Page 7'), findsOneWidget);

  // Verify dropdown shows "None" and P1-P15 options
  await tester.tap(find.byType(DropdownMenu<int>));
  await tester.pumpAndSettle();
  expect(find.text('None'), findsOneWidget);
  for (int i = 1; i <= 15; i++) {
    expect(find.text('P$i'), findsWidgets);
  }
});

testWidgets('Selecting performance page calls cubit.setPerformancePageMapping', (tester) async {
  final cubit = MockDistingCubit();
  final mockState = createMockSynchronizedState(
    slots: [createMockSlot(algorithmIndex: 0, perfPageIndex: 0)],
  );
  when(() => cubit.state).thenReturn(mockState);
  when(() => cubit.setPerformancePageMapping(any(), any(), any()))
      .thenAnswer((_) async {});

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: PackedMappingDataEditor(
            initialData: PackedMappingData.filler(),
            slots: mockState.slots,
            algorithmIndex: 0,
            parameterNumber: 2,
          ),
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

  // Verify cubit method was called with correct parameters
  verify(() => cubit.setPerformancePageMapping(0, 2, 5)).called(1);
});

testWidgets('Widget rebuilds when cubit emits new state', (tester) async {
  final cubit = MockDistingCubit();
  final stateController = StreamController<DistingState>.broadcast();

  when(() => cubit.state).thenAnswer((_) => stateController.stream.value);
  when(() => cubit.stream).thenAnswer((_) => stateController.stream);

  // Initial state: perfPageIndex = 0
  final initialState = createMockSynchronizedState(
    slots: [createMockSlot(algorithmIndex: 0, perfPageIndex: 0)],
  );
  stateController.add(initialState);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(
          body: PackedMappingDataEditor(
            initialData: PackedMappingData.filler(),
            slots: initialState.slots,
            algorithmIndex: 0,
            parameterNumber: 0,
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Performance'));
  await tester.pumpAndSettle();

  // Verify initial state
  expect(find.text('Not assigned to any performance page'), findsOneWidget);

  // Cubit emits new state: perfPageIndex = 5
  final newState = createMockSynchronizedState(
    slots: [createMockSlot(algorithmIndex: 0, perfPageIndex: 5)],
  );
  stateController.add(newState);
  await tester.pumpAndSettle();

  // Verify widget rebuilt with new state
  expect(find.text('Assigned to Performance Page 5'), findsOneWidget);
  expect(find.text('Not assigned to any performance page'), findsNothing);

  stateController.close();
});
```

**Key Test Requirements:**
1. **MUST** use `BlocProvider` with mock or real cubit
2. **MUST** verify dropdown reads from cubit state (NOT local widget state)
3. **MUST** verify `setPerformancePageMapping()` is called with correct `algorithmIndex`, `parameterNumber`, `perfPageIndex`
4. **MUST** verify widget rebuilds when cubit emits new state
5. **MUST** test that both inline dropdown and Performance tab stay synchronized via cubit state

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
