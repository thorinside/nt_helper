# Routing bus picker selected-center spec

Baseline ref: `HEAD` (`65db0bf5` at spec authoring time)

Hardening policy: realistic-only

Verification command hint: `flutter analyze && flutter test`

## Inventory summary

Inventory was generated from the repo root with:

```bash
python3 .pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/ui/widgets/routing/bus_picker_dialog.dart \
  lib/ui/widgets/routing/bus_lanes_view.dart \
  lib/cubit/routing_editor_cubit.dart \
  lib/ui/widgets/routing/routing_editor_widget.dart \
  test/ui/widgets/routing/algorithm_node_widget_test.dart \
  > /tmp/routing_bus_picker_inventory.md
python3 .pi/skills/decision-free-specs/languages/dart/inventory.py \
  test/ui/widgets/routing/bus_lanes_view_test.dart \
  > /tmp/bus_lanes_test_inventory.md
python3 .pi/skills/decision-free-specs/languages/dart/inventory.py \
  lib/core/routing/bus_spec.dart \
  > /tmp/bus_spec_inventory.md
```

Hand check completed for `lib/ui/widgets/routing/bus_picker_dialog.dart`: the inventory declaration list matches the file structure for `BusPickerDialog`, `_BusPickerDialogState`, `_BusTile`, and `_BusTileState`.

Relevant inventory facts:

| File | Size | Relevant declarations | Imported by |
|---|---:|---|---|
| `lib/ui/widgets/routing/bus_picker_dialog.dart` | 232 lines | `BusPickerDialog`, `_BusPickerDialogState`, `_BusTile`, `_BusTileState` | `lib/ui/widgets/routing/bus_lanes_view.dart` |
| `lib/ui/widgets/routing/bus_lanes_view.dart` | 1162 lines | `BusLanesView`, `_BusLanesViewState`, `_PortRef`, `_Bead`, `_BusLanesData`; methods `_showBusPicker`, `_applyAssign`, `_busLabel`, `_buildData` | `lib/ui/widgets/routing/routing_editor_widget.dart`, `test/ui/widgets/routing/bus_lanes_view_test.dart` |
| `lib/cubit/routing_editor_cubit.dart` | 3610 lines | `RoutingEditorCubit.assignBusAndSolve`, `setPortBus`, `undoBusAssignment`; no implementation change in this program | many routing UI and cubit tests |
| `lib/ui/widgets/routing/routing_editor_widget.dart` | 4893 lines | `RoutingEditorWidget` imports and hosts `BusLanesView`; no implementation change in this program | app screens and routing widget tests |
| `lib/core/routing/bus_spec.dart` | 106 lines | `BusSpec` bus ranges and classifiers | routing UI, cubit, core routing, tests |
| `test/ui/widgets/routing/bus_lanes_view_test.dart` | 511 lines | existing `BusLanesView` widget tests and mocked `RoutingEditorCubit` | no imports |

## Architecture

Keep the bus picker as the existing bus-lanes dialog interaction. Do not introduce a new dropdown, route picker service, cubit method, routing model, or persistence state. This program changes only the dialog presentation and the bus list passed into that dialog from `BusLanesView`.

`BusLanesView` remains the UI coordinator for the bus-lanes drag/drop interaction. `RoutingEditorCubit.assignBusAndSolve` remains the only path that changes a port bus after the user selects a bus. All routing semantics, slot reorder solving, bus numbering, and hardware synchronization behavior stay in the cubit and existing services.

### Target file tree

| Path | Action |
|---|---|
| `lib/ui/widgets/routing/bus_picker_dialog.dart` | Make the dialog scrollable, insert and highlight the current bus, center the current bus when opened, preserve accessible selected semantics |
| `test/ui/widgets/routing/bus_picker_dialog_test.dart` | New focused dialog tests |
| `lib/ui/widgets/routing/bus_lanes_view.dart` | Pass every valid bus in the relevant ranges to the dialog, including currently used buses and the current bus |
| `test/ui/widgets/routing/bus_lanes_view_test.dart` | Add regression test for used-bus visibility from the plus-lane picker |
| `specs/README.md` | Program table row added by this spec authoring commit |

### Symbol map

| Symbol | Current location | Destination after implementation | Exported | Notes |
|---|---|---|---|---|
| `BusPickerDialog` | `lib/ui/widgets/routing/bus_picker_dialog.dart` | unchanged | yes | Constructor keeps the `availableBuses` named parameter for compatibility; the parameter is treated as the complete display list supplied by the caller |
| `_BusPickerDialogState` | `lib/ui/widgets/routing/bus_picker_dialog.dart` | unchanged | no | Adds scroll controller, current-bus key, current-centering helper, and sorted display bus computation |
| `_BusTile` | `lib/ui/widgets/routing/bus_picker_dialog.dart` | unchanged | no | Adds `selected` flag and nullable `onTap` |
| `_BusTileState` | `lib/ui/widgets/routing/bus_picker_dialog.dart` | unchanged | no | Adds selected-state visual and selected-state semantics |
| `_BusLanesViewState._showBusPicker` | `lib/ui/widgets/routing/bus_lanes_view.dart` | unchanged | no | Stops filtering `_lastVisibleBuses` and stops excluding `ref.previousBus` from the picker list |
| `_BusLanesViewState._applyAssign` | `lib/ui/widgets/routing/bus_lanes_view.dart` | unchanged | no | Continues to call `RoutingEditorCubit.assignBusAndSolve` for real changes only |
| `_BusLanesViewState._buildData` | `lib/ui/widgets/routing/bus_lanes_view.dart` | unchanged | no | Used-bus lane visibility remains only the existing canvas lane filtering |

No symbol moves. No compatibility re-export is needed.

## Decisions inventory

| Decision | Rationale | Files affected | Classification |
|---|---|---|---|
| Keep `BusPickerDialog` instead of adding a dropdown implementation | The repo already has the newer bus-lanes dialog interaction; the request can be satisfied by hardening that dialog | `lib/ui/widgets/routing/bus_picker_dialog.dart`, `lib/ui/widgets/routing/bus_lanes_view.dart` | required |
| Keep the `availableBuses` constructor parameter name | `BusPickerDialog` is public and imported by `BusLanesView`; retaining the name keeps STEP 1 independently green | `lib/ui/widgets/routing/bus_picker_dialog.dart` | required |
| Interpret `availableBuses` as the complete display list supplied by the caller | The picker must not hide used buses; availability is enforced by existing routing assignment logic, not by visual omission | `lib/ui/widgets/routing/bus_picker_dialog.dart`, `lib/ui/widgets/routing/bus_lanes_view.dart` | required |
| Insert `currentBus` into the dialog display set when `currentBus > 0` | The currently selected bus must be visible even when the caller passes a filtered list | `lib/ui/widgets/routing/bus_picker_dialog.dart` | required |
| Disable tapping the current-bus tile and return no value for it | Re-selecting the same bus is a no-op and must not call `assignBusAndSolve` | `lib/ui/widgets/routing/bus_picker_dialog.dart`, `lib/ui/widgets/routing/bus_lanes_view.dart` | required |
| Add a no-op guard after dialog return when `choice == ref.previousBus` | The guard protects semantics activation, future call sites, and keyboard activation from triggering a redundant assignment | `lib/ui/widgets/routing/bus_lanes_view.dart` | required |
| Use `Scrollable.ensureVisible` with `alignment: 0.5` after the first frame | This opens the picker with the selected bus near the vertical middle of the visible scroll area | `lib/ui/widgets/routing/bus_picker_dialog.dart` | required |
| Group buses in the existing order Inputs, Outputs, Aux, ES-5 | This preserves current dialog organization and bus numbering labels | `lib/ui/widgets/routing/bus_picker_dialog.dart` | required |
| Pass all valid input, output, aux, and valid ES-5 buses from `BusLanesView._showBusPicker` | The dialog must show used buses and nearby lower-numbered buses; ES-5 remains limited to USB Audio output ports | `lib/ui/widgets/routing/bus_lanes_view.dart` | required |
| Leave `_buildData` used-bus lane filtering unchanged | The request scopes the change to selecting an input/output bus and forbids used-bus filtering changes elsewhere | `lib/ui/widgets/routing/bus_lanes_view.dart` | required |
| Do not change `RoutingEditorCubit`, `BusSpec`, routing services, bus numbering, or solver logic | The feature is presentation and selection affordance only | none | out-of-scope |
| Do not add success snackbars or debug logging | Repo rules forbid unnecessary success snackbars and debug logging | all implementation files | out-of-scope |
| Do not persist picker scroll position | The requested state is derived from the current selected bus each time the dialog opens | none | out-of-scope |
| Do not mark used buses with a separate used badge in this program | Visibility of used buses is required; a used-bus legend is a separate UI feature | none | optional |

## Dialog API and behavior contract

`BusPickerDialog` keeps this public constructor shape:

```dart
const BusPickerDialog({
  super.key,
  required this.portLabel,
  required this.currentBus,
  required this.availableBuses,
  required this.showEs5,
  required this.busLabel,
});
```

Behavior after implementation:

| Input | Required behavior |
|---|---|
| `availableBuses` contains a bus that is also used elsewhere | The bus appears as an enabled tile |
| `availableBuses` omits `currentBus` and `currentBus > 0` | The current bus is inserted into the display set and appears in its numeric group |
| `availableBuses` contains duplicates | The dialog displays each bus number once |
| `currentBus == 0` | The footer displays `Currently: None`; no numbered current tile is inserted |
| `showEs5 == false` | The `ES-5` section is hidden; supplied buses `>= BusSpec.auxMin` appear in the `Aux` section unless they are already in the local ES-5 set |
| `showEs5 == true` | ES-5 buses in the supplied range appear in the `ES-5` section, and all remaining supplied buses `>= BusSpec.auxMin` appear in `Aux` |

Current-bus tile contract:

- The tile text is the value returned by `busLabel(currentBus)`.
- The semantics label is `Current bus <label>`.
- The semantics node has `button: true`, `selected: true`, and disabled/enabled state corresponding to `enabled: false`.
- The tile has no `onTap` callback.
- The tile border is visually stronger than non-selected tiles: width `3.0` and color `Theme.of(context).colorScheme.primary`.
- Non-selected tiles keep the existing `Route to <label>` semantics label and pop the dialog with their bus value.

Scroll contract:

- The dialog body uses a `SingleChildScrollView` controlled by `_scrollController`.
- The scrollable bus-section area is constrained to at most `MediaQuery.sizeOf(context).height * 0.65` and at most `420` logical pixels.
- `_BusPickerDialogState.initState` schedules one post-frame callback.
- The callback calls `Scrollable.ensureVisible` on the current tile key with `alignment: 0.5` and `duration: Duration.zero`.
- If `currentBus <= 0` or the current tile context is absent, the callback returns without scrolling.

## `BusLanesView._showBusPicker` contract

The bus collection in `_showBusPicker` changes from unused-only to full-range display:

```dart
final buses = <int>[];
void addRange(int from, int to) {
  for (var b = from; b <= to; b++) {
    if (!buses.contains(b)) buses.add(b);
  }
}

addRange(BusSpec.inputMin, BusSpec.inputMax);
addRange(BusSpec.outputMin, BusSpec.outputMax);
addRange(BusSpec.auxMin, auxMax);
if (isUsbf) addRange(es5Min, es5Max);
```

Then pass `availableBuses: buses` into `BusPickerDialog`.

After the dialog returns, use this exact guard order:

```dart
if (choice == null || !mounted || !context.mounted) return;
if (choice == ref.previousBus) return;
await _applyAssign(context, ref, choice);
```

Do not edit `_buildData` lane visibility logic:

```dart
final visible = usedBuses.where((b) => b >= 1 && b <= maxBus).toList()
  ..sort();
```

## Hardening matrix

| Risk | Plausible path | Handling | Tests required |
|---|---|---|---|
| Current bus is hidden by caller-side filtering | Current implementation excludes `ref.previousBus` before constructing the dialog | `BusPickerDialog` inserts `currentBus` when it is positive | `bus picker displays all supplied buses and marks current bus selected` |
| Used lower-numbered buses are hidden from the plus-lane picker | User drags a bead to the plus lane while bus 13 is already visible and wants to route to that used bus from the dialog | `_showBusPicker` passes full bus ranges and does not filter `_lastVisibleBuses` | `bus picker opened from plus lane shows current and used lower buses` |
| Long bus list overflows on a short viewport | User opens the picker on a small desktop window or mobile-sized surface | Bus sections are inside a constrained `SingleChildScrollView` | `bus picker scrolls current bus near vertical center` |
| Selected bus opens at the top or bottom of the visible list | User opens the picker for a high-numbered current bus and needs nearby lower-numbered buses | Post-frame `Scrollable.ensureVisible(... alignment: 0.5 ...)` centers the current tile | `bus picker scrolls current bus near vertical center` |
| Screen reader does not expose selected state | Blind user opens the picker and needs to know the active bus | Current tile semantics label is `Current bus <label>` and has selected state | `bus picker displays all supplied buses and marks current bus selected` |
| Redundant assignment is sent for the current bus | Keyboard or future interaction activates the current tile | Current tile has no tap handler and `_showBusPicker` returns before `_applyAssign` when the returned bus equals `ref.previousBus` | Covered by implementation contract; no separate test because the disabled tile cannot return a value through the dialog |
| Dialog dismissed while the widget is unmounted | User closes or navigates away while dialog is open | Existing `choice == null`, `mounted`, and `context.mounted` checks remain in place | No new test required; existing async guard stays unchanged |
| Hardware latency or MIDI failure during assignment | `assignBusAndSolve` performs existing async state work after a valid selection | Existing cubit path and snackbar/undo behavior remain unchanged | Out of scope for this UI-only program |
| Bus numbering corruption | A code path changes `BusSpec` constants or `_busLabel` numbering | This program does not edit `BusSpec` or `_busLabel` | Out of scope and protected by existing routing tests |

No file-system behavior, hardware/API latency change, or data-corruption path is introduced by this program. Those areas remain out of scope.

## Acceptance criteria

- Opening the bus-lanes picker for a port with a numbered current bus shows that current bus as a visibly selected tile.
- The selected tile is positioned near the vertical middle of the visible bus list after the dialog opens when scrolling is needed.
- Used buses are still shown in the picker and are enabled unless they are the current bus.
- Existing canvas lane visibility remains based on used buses only.
- Selecting any non-current bus still calls `RoutingEditorCubit.assignBusAndSolve` through `_applyAssign`.
- No cubit, routing service, `BusSpec`, bus numbering, hardware sync, or persistence behavior changes.
- Accessibility semantics expose route tiles as buttons and expose the current tile as selected.
