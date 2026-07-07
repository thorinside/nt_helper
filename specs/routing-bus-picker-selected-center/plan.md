# Routing bus picker selected-center implementation plan

Total steps: 2

Each step is independently committable. Execute exactly one numbered step per fresh-context session. Read `specs/conventions.md` and `specs/routing-bus-picker-selected-center/spec.md` before editing.

Program-level verification after STEP 2:

```bash
cd /Users/nealsanche/nosuch/nt_helper
flutter analyze
flutter test
```

## STEP 1 of 2 — Center and mark the selected bus in the dialog

### Files to edit

- `lib/ui/widgets/routing/bus_picker_dialog.dart`
- Create `test/ui/widgets/routing/bus_picker_dialog_test.dart`

### Required implementation

1. In `BusPickerDialog`, keep the existing constructor and the `availableBuses` named parameter unchanged.
2. Update the `availableBuses` field doc comment to state that it is the complete bus list supplied for display and that the dialog inserts `currentBus` when needed.
3. In `_BusPickerDialogState`, add these fields:
   - `final ScrollController _scrollController = ScrollController();`
   - `final GlobalKey _currentBusKey = GlobalKey();`
4. In `_BusPickerDialogState.initState`, build the section lists from a deduped display set:
   - Start with `widget.availableBuses.where((b) => b > 0).toSet()`.
   - When `widget.currentBus > 0`, add `widget.currentBus` to that set.
   - Use this set, not `widget.availableBuses`, to populate `_inputs`, `_outputs`, `_aux`, and `_es5`.
   - `_inputs` contains `BusSpec.isPhysicalInput` buses sorted ascending.
   - `_outputs` contains `BusSpec.isPhysicalOutput` buses sorted ascending.
   - `_es5` contains ES-5 or extended ES-5 buses only when `widget.showEs5` is true.
   - `_aux` contains buses `>= BusSpec.auxMin` that are not in `_es5`, sorted ascending.
5. Still in `initState`, after the section lists are built, schedule exactly one `WidgetsBinding.instance.addPostFrameCallback` that calls a new private method `_centerCurrentBus`.
6. Add `_centerCurrentBus` to `_BusPickerDialogState` with this behavior:
   - Return immediately when `widget.currentBus <= 0`.
   - Read `_currentBusKey.currentContext` into a local variable.
   - Return immediately when that local context is null.
   - Call `Scrollable.ensureVisible(currentContext, alignment: 0.5, duration: Duration.zero);`.
7. Override `dispose` in `_BusPickerDialogState`, call `_scrollController.dispose()`, then call `super.dispose()`.
8. In `build`, wrap the bus sections in a `SingleChildScrollView` controlled by `_scrollController`.
9. Constrain the scrollable bus-section area with `ConstrainedBox` and `BoxConstraints(maxHeight: math.min(MediaQuery.sizeOf(context).height * 0.65, 420.0))`.
10. Add `import 'dart:math' as math;` at the top of `bus_picker_dialog.dart`.
11. Keep the header and footer outside the scroll view.
12. In `_section`, pass these new arguments to `_BusTile`:
    - `key: bus == widget.currentBus ? _currentBusKey : null`
    - `selected: bus == widget.currentBus`
    - `onTap: bus == widget.currentBus ? null : () => Navigator.of(context).pop(bus)`
13. Update `_BusTile` constructor and fields:
    - Add `final bool selected;`
    - Change `final VoidCallback onTap;` to `final VoidCallback? onTap;`
    - Accept `super.key`.
14. In `_BusTileState.build`, compute `final theme = Theme.of(context);` and keep `final isDark = theme.brightness == Brightness.dark;`.
15. Current-bus tile visual rules:
    - Border color is `theme.colorScheme.primary`.
    - Border width is `3.0`.
    - Fill alpha is `0.45`.
16. Non-current tile visual rules:
    - Border color is the existing `baseColor`.
    - Border width is `2.0` only when hovered and `1.5` otherwise.
    - Fill alpha is `0.35` only when hovered and `0.18` otherwise.
17. Wrap the tile with `Semantics` using these values:
    - `label: widget.selected ? 'Current bus ${widget.label}' : 'Route to ${widget.label}'`
    - `button: true`
    - `selected: widget.selected`
    - `enabled: widget.onTap != null`
18. Set `InkWell.onTap` to `widget.onTap`.
19. Keep `InkWell.onHover` unchanged except it must still update `_hovered` only when the value changes.
20. Do not add a used-bus badge, a success snackbar, debug logging, or persistence.

### Required tests

Create `test/ui/widgets/routing/bus_picker_dialog_test.dart` with these imports:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nt_helper/ui/widgets/routing/bus_picker_dialog.dart';
```

Add a top-level helper in the test file:

```dart
String testBusLabel(int bus) {
  if (bus <= 0) return 'None';
  if (bus <= 12) return 'I$bus';
  if (bus <= 20) return 'O${bus - 12}';
  return 'A${bus - 20}';
}
```

Add exactly these widget tests:

1. `bus picker displays all supplied buses and marks current bus selected`
   - Enable semantics with `final semantics = tester.ensureSemantics();` and dispose it at the end of the test.
   - Pump `MaterialApp(home: Scaffold(body: BusPickerDialog(...)))` with `portLabel: 'Output'`, `currentBus: 13`, `availableBuses: const [11, 12, 14]`, `showEs5: false`, and `busLabel: testBusLabel`.
   - Assert `find.text('I11')`, `find.text('I12')`, `find.text('O1')`, and `find.text('O2')` each find one widget.
   - Assert `find.bySemanticsLabel('Current bus O1')` finds one widget.
   - Read `tester.getSemantics(find.bySemanticsLabel('Current bus O1'))` and assert `node.hasFlag(SemanticsFlag.isSelected)` is true.
   - Assert `find.bySemanticsLabel('Route to O2')` finds one widget.
2. `bus picker scrolls current bus near vertical center`
   - Use `addTearDown(() => tester.binding.setSurfaceSize(null));`.
   - Call `await tester.binding.setSurfaceSize(const Size(440, 360));`.
   - Pump `MaterialApp(home: Scaffold(body: BusPickerDialog(...)))` with `portLabel: 'Output'`, `currentBus: 50`, `availableBuses: List<int>.generate(64, (index) => index + 1)`, `showEs5: false`, and `busLabel: testBusLabel`.
   - Call `await tester.pumpAndSettle();`.
   - Read `final dialogRect = tester.getRect(find.byType(Dialog));`.
   - Read `final selectedY = tester.getCenter(find.text('A30')).dy;`.
   - Assert `selectedY` is greater than `dialogRect.top + dialogRect.height * 0.30`.
   - Assert `selectedY` is less than `dialogRect.top + dialogRect.height * 0.80`.

### Leftover checks

Run:

```bash
grep -n "final ScrollController _scrollController" lib/ui/widgets/routing/bus_picker_dialog.dart
grep -n "void _centerCurrentBus" lib/ui/widgets/routing/bus_picker_dialog.dart
grep -n "selected: bus == widget.currentBus" lib/ui/widgets/routing/bus_picker_dialog.dart
grep -n "Current bus" lib/ui/widgets/routing/bus_picker_dialog.dart
grep -n "bus picker scrolls current bus near vertical center" test/ui/widgets/routing/bus_picker_dialog_test.dart
```

Expected counts: each command prints at least one line.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/widgets/routing/bus_picker_dialog.dart test/ui/widgets/routing/bus_picker_dialog_test.dart
flutter analyze
flutter test test/ui/widgets/routing/bus_picker_dialog_test.dart
git add lib/ui/widgets/routing/bus_picker_dialog.dart test/ui/widgets/routing/bus_picker_dialog_test.dart
git status --short
git commit -m "feat(routing): center selected bus in picker"
```

Only these files may appear in `git status --short` before the commit:

- `lib/ui/widgets/routing/bus_picker_dialog.dart`
- `test/ui/widgets/routing/bus_picker_dialog_test.dart`

### Commit message

`feat(routing): center selected bus in picker`

## STEP 2 of 2 — Show used buses in the bus-lanes picker

### Prerequisites

- STEP 1 committed with message `feat(routing): center selected bus in picker`.

### Files to edit

- `lib/ui/widgets/routing/bus_lanes_view.dart`
- `test/ui/widgets/routing/bus_lanes_view_test.dart`

### Required implementation

1. In `_BusLanesViewState._showBusPicker`, rename the local list from `available` to `buses`.
2. Replace the `addRange` body with this exact logic:

   ```dart
   void addRange(int from, int to) {
     for (var b = from; b <= to; b++) {
       if (!buses.contains(b)) buses.add(b);
     }
   }
   ```

3. Remove the `b == ref.previousBus` filter.
4. Remove the `_lastVisibleBuses.contains(b)` filter.
5. Keep the same range calls in this order:
   - `addRange(BusSpec.inputMin, BusSpec.inputMax);`
   - `addRange(BusSpec.outputMin, BusSpec.outputMax);`
   - `addRange(BusSpec.auxMin, auxMax);`
   - `if (isUsbf) addRange(es5Min, es5Max);`
6. Change the empty-list guard to `if (buses.isEmpty) return;`.
7. Pass `availableBuses: buses` to `BusPickerDialog`.
8. After the dialog returns, use this exact guard order:

   ```dart
   if (choice == null || !mounted || !context.mounted) return;
   if (choice == ref.previousBus) return;
   await _applyAssign(context, ref, choice);
   ```

9. Do not edit `_buildData`, `_lastVisibleBuses` assignment, `_busLabel`, `_applyAssign`, `RoutingEditorCubit`, `BusSpec`, or any routing service.
10. Do not add a success snackbar or debug logging.

### Required tests

In `test/ui/widgets/routing/bus_lanes_view_test.dart`:

1. Add this helper near the existing `oscWithOutput()` helper:

   ```dart
   state.RoutingAlgorithm dualOutputsOnAdjacentBuses() => state.RoutingAlgorithm(
     id: 'algoDual',
     index: 0,
     algorithm: Algorithm(algorithmIndex: 0, guid: 'dual', name: 'Dual'),
     inputPorts: const [],
     outputPorts: const [
       Port(
         id: 'dual_out_13',
         name: 'Out 13',
         type: PortType.audio,
         direction: PortDirection.output,
         busValue: 13,
         outputMode: OutputMode.add,
         parameterNumber: 3,
         modeParameterNumber: 5,
       ),
       Port(
         id: 'dual_out_14',
         name: 'Out 14',
         type: PortType.audio,
         direction: PortDirection.output,
         busValue: 14,
         outputMode: OutputMode.add,
         parameterNumber: 4,
         modeParameterNumber: 6,
       ),
     ],
   );
   ```

2. Add exactly this widget test after `renders lanes and a block for a loaded preset`:

   ```dart
   testWidgets('bus picker opened from plus lane shows current and used lower buses', (
     tester,
   ) async {
     when(cubit.state).thenReturn(loadedWith([dualOutputsOnAdjacentBuses()]));

     await tester.pumpWidget(host());
     await tester.pump();

     // Visible buses are 13 and 14. The second output bead is on bus 14
     // at column 2, row 1. Dropping it one rail to the right lands on plus.
     await tester.dragFrom(const Offset(277, 99), const Offset(42, 0));
     await tester.pumpAndSettle();

     expect(find.bySemanticsLabel('Current bus O2'), findsOneWidget);
     expect(find.text('O1'), findsOneWidget);
     expect(find.text('O2'), findsOneWidget);
   });
   ```

3. Keep all existing tests unchanged except for formatting.

### Leftover checks

Run:

```bash
grep -n "final buses = <int>\[\]" lib/ui/widgets/routing/bus_lanes_view.dart
grep -n "_lastVisibleBuses.contains" lib/ui/widgets/routing/bus_lanes_view.dart || true
grep -n "b == ref.previousBus" lib/ui/widgets/routing/bus_lanes_view.dart || true
grep -n "availableBuses: buses" lib/ui/widgets/routing/bus_lanes_view.dart
grep -n "final visible = usedBuses.where" lib/ui/widgets/routing/bus_lanes_view.dart
grep -n "bus picker opened from plus lane shows current and used lower buses" test/ui/widgets/routing/bus_lanes_view_test.dart
```

Expected counts:

- `final buses = <int>[]` appears one time.
- `_lastVisibleBuses.contains` appears zero times.
- `b == ref.previousBus` appears zero times.
- `availableBuses: buses` appears one time.
- `final visible = usedBuses.where` appears one time.
- The new test name appears one time.

### Verification commands

```bash
cd /Users/nealsanche/nosuch/nt_helper
dart format lib/ui/widgets/routing/bus_lanes_view.dart test/ui/widgets/routing/bus_lanes_view_test.dart
flutter analyze
flutter test test/ui/widgets/routing/bus_picker_dialog_test.dart test/ui/widgets/routing/bus_lanes_view_test.dart
git add lib/ui/widgets/routing/bus_lanes_view.dart test/ui/widgets/routing/bus_lanes_view_test.dart
git status --short
git commit -m "feat(routing): show used buses in picker"
```

Only these files may appear in `git status --short` before the commit:

- `lib/ui/widgets/routing/bus_lanes_view.dart`
- `test/ui/widgets/routing/bus_lanes_view_test.dart`

### Commit message

`feat(routing): show used buses in picker`
