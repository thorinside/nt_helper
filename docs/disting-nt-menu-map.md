# Disting NT menu map — live, read-only exploration

Observed through `nt_helper` MCP on firmware **v1.19.0**, 2026-10-17.
Context: preset **Init**, zero algorithm slots. This is a map of the menu labels
and safely accessible submenus, not a claim that every action or value choice was
exercised. Dynamic algorithm, mapping, file, and script contents depend on state.

## Navigation and safety

- Button 1 (push/release index 0) opens/closes the menu from ordinary screens.
- Left encoder rotation (index 0) moves the selection; its press (index 7)
  opens a submenu. Selections clamp at list ends in the menus explored.
- Use `show_screen({})` after navigation; it takes no arguments and preserves
  the display being observed. `set_display_mode` is a separate explicit view
  change, not a menu navigation control. An immediate capture occasionally showed the
  preceding selection; wait briefly and recapture before entering an item.
- `>` usually denotes a submenu. `...` can lead to a dialog, browser, or command;
  it does **not** guarantee a confirmation before a state-changing operation.
- Value rows are leaves. Opening a value editor is not needed to map its label;
  rotating a control there can change settings.
- Modal screens do not necessarily return to the same level as ordinary menus.
  Observe the result of dismissal rather than blindly continuing a saved offset.

During this mapping pass, only the left encoder was rotated. Button 1 and the
left encoder press were used to navigate. No pot/right-encoder value commands,
Apply/Set/Save operations, preset loads, calibration operations, resets, MIDI
output commands, reboot, or USB-disk-mode commands were executed. Menu cursor
positions changed; some submenu positions may remain remembered by the firmware.

### Legend

- `>`: submenu whose displayed contents were inspected below.
- `[leaf]`: displayed value or editable field; value choices were not enumerated.
- `[action]`: command label observed, deliberately not executed.
- `[boundary]`: entry observed, deeper contents not safely established in this pass.
- `[view]`: informational display, not a settings change.

Labels below preserve the device wording where readable; decorative chevrons and
selection markers are omitted. Current setting values are intentionally not used
as defaults or as a configuration recommendation.

## Main menu

```text
Menu
├── Algorithms >
├── Presets >
├── Mappings >
├── Performance page >
├── Settings >
├── Misc >
└── UI Scripts >
```

## Algorithms

```text
Algorithms
├── Add algorithm >
│   ├── Tags                       [leaf: filter]
│   ├── Select                     [leaf: algorithm choice]
│   ├── Add                        [action]
│   └── Algorithm specifications   [dynamic fields, when required]
├── Respecify algorithm...         [boundary: requires an algorithm]
├── Remove algorithm...            [action]
├── Move algorithm up              [action]
├── Move algorithm down            [action]
├── Customise name                 [boundary: requires an algorithm]
├── Duplicate algorithm            [action]
└── Style >                       [unavailable with the empty preset]
```

The Add chooser's Tags/Select/Add rows were observed in earlier live navigation;
Attenuverter additionally displayed a Channels specification row. Specification
fields vary by selected algorithm. No algorithm was added to enumerate them.
Attempting to open Style on the empty preset left the Algorithms menu unchanged.

## Presets

```text
Presets
├── Load preset...                 [file-selection boundary; no load executed]
├── Name preset                    [leaf]
├── Generate random preset name    [action]
├── Save preset...                 [action]
├── New preset...                  [action]
├── Load parameters...             [file browser; opened, no file selected]
├── Split/combine >
│   ├── Append preset...           [action/file-selection boundary]
│   ├── Insert preset...           [action/file-selection boundary]
│   ├── Prepend preset...          [action/file-selection boundary]
│   ├── Save single algorithm preset [action]
│   └── Save range >
│       ├── Save                   [action]
│       ├── From                   [leaf]
│       └── To                     [leaf]
├── End of chain >                [boundary: algorithm-dependent]
├── Set save location...           [directory-selection boundary]
├── Load disting EX preset...      [file-selection boundary]
└── Author name                    [leaf]
```

Load parameters opened an SD-card browser at `/presets`. The directory listing is
content, not a fixed firmware menu; no directory/file was activated. The save
location displayed `/presets`. Neither setting was changed.

## Mappings

```text
Mappings
├── CV Mappings >                  [algorithm/parameter-dependent boundary]
├── MIDI Mappings >                [algorithm/parameter-dependent boundary]
├── I2C Mappings >                 [algorithm/parameter-dependent boundary]
└── Performance page >            [algorithm/parameter-dependent boundary]
```

Opening CV Mappings on the empty preset left this menu unchanged. Other mapping
editors were not populated or inferred. Mapping-field details require a populated
preset; creating one would violate this exploration's read-only constraint.

## Performance page

```text
Performance page
├── Edit >
│   ├── Item                       [leaf]
│   ├── Algorithm                  [leaf]
│   └── Parameter                  [leaf]
├── Min/max >
│   ├── Item                       [leaf]
│   ├── Min                        [leaf]
│   └── Max                        [leaf]
├── Names >
│   ├── Item                       [leaf]
│   ├── Upper                      [leaf]
│   └── Lower                      [leaf]
├── Move up                        [action]
└── Move down                      [action]
```

Unused entries showed `UNUSED` in Min/max and Names; Edit showed Parameter None.
These are display states, not additional selectable menu entries.

## Settings

```text
Settings
├── Display >
│   ├── Contrast                   [leaf]
│   ├── Master contrast            [leaf]
│   ├── Flip                       [leaf]
│   ├── Screensaver (minutes)      [leaf]
│   ├── Screensaver style          [leaf]
│   ├── Wake on MIDI/I2C           [leaf]
│   ├── Enter screensaver now      [action]
│   ├── Support USB Video Class    [leaf]
│   ├── CPU load display           [leaf]
│   ├── Bypass >
│   │   ├── Off                    [leaf]
│   │   └── On                     [leaf]
│   ├── Performance page >
│   │   ├── Show CPU load          [leaf]
│   │   ├── Show stopwatch         [leaf]
│   │   └── CPU on list view       [leaf]
│   └── Expert settings >
│       ├── Clock frequency (9)    [leaf]
│       ├── Clock divider (1)      [leaf]
│       ├── Phase 1 (2)            [leaf]
│       ├── Phase 2 (14)           [leaf]
│       ├── Precharge level (31)   [leaf]
│       └── Phase 3 (8)            [leaf]
├── UI >
│   ├── Show button help           [leaf]
│   ├── Button 4 function          [leaf]
│   ├── Button ordering            [leaf]
│   ├── Primary encoder            [leaf]
│   ├── Pot threshold              [leaf]
│   ├── Add algorithms bypassed    [leaf]
│   └── Knob record min playback   [leaf]
├── Engine >
│   ├── Sample rate                [leaf]
│   ├── Block size                 [leaf]
│   ├── Apply                      [action]
│   ├── Allow USB rate change      [leaf]
│   └── NTX-8CV >
│       ├── Mode                   [leaf]
│       ├── Apply mode change      [action]
│       ├── Also use ES-5          [leaf]
│       ├── Channel                [leaf]
│       └── Enable                 [leaf]
├── Globals >
│   └── Tuning A=                  [leaf]
├── Startup >
│   └── Load last preset           [leaf]
├── Select Bus >
│   └── Speed multiplier           [leaf]
├── MIDI >
│   ├── CC changes view            [leaf]
│   ├── SysEx changes view         [leaf]
│   ├── Soft takeover              [leaf]
│   ├── Send CCs                   [leaf]
│   ├── Send CCs if changed by MIDI map [leaf]
│   ├── Learn is exclusive         [leaf]
│   ├── SysEx Device ID            [leaf]
│   ├── Program Change channel     [leaf]
│   ├── Program Change uses Bank   [leaf]
│   ├── Program Change shows message [leaf]
│   ├── Support NRPNs              [leaf]
│   └── Forwarding >
│       ├── USB to Breakout        [leaf]
│       ├── USB to Select Bus      [leaf]
│       ├── Breakout to Breakout   [leaf]
│       ├── Breakout to Select Bus [leaf]
│       ├── Breakout to USB        [leaf]
│       ├── Select Bus to Breakout [leaf]
│       └── Select Bus to USB      [leaf]
├── I2C >
│   ├── Address (as follower)      [leaf]
│   └── CC changes view            [leaf]
├── Real-time clock >
│   ├── Year                       [leaf]
│   ├── Month                      [leaf]
│   ├── Day                        [leaf]
│   ├── Hour                       [leaf]
│   ├── Minute                     [leaf]
│   └── Set                        [action]
├── Calibration >
│   ├── Zero input offsets...      [action]
│   ├── Calibrate an input >       [boundary: calibration workflow]
│   ├── Calibrate an output >      [boundary: calibration workflow]
│   ├── Save to calibration to flash... [action; wording as displayed]
│   ├── Reset calibration          [action]
│   ├── Read factory calibration   [action]
│   ├── View calibration           [view boundary]
│   └── View input voltages        [view boundary]
├── Audio recordings folder...     [directory-selection boundary]
├── Warnings >
│   └── Three Pot safety           [leaf]
└── Factory reset...               [action]
```

The NTX-8CV submenu was observed in its existing Audio 32 bit (1x8) mode. Other
modes may expose different fields; none were selected. The parentheses in the
Display Expert labels are part of the labels, not a range established by this
exploration. The real-time clock was inspected but Set was not activated.

## Misc

```text
Misc
├── About...                       [view: firmware/build information; opened]
├── MicroSD card >
│   ├── Remount                    [action]
│   ├── Regenerate wavcache files... [action]
│   ├── Test speed                 [action]
│   ├── Browse...                  [file-browser boundary]
│   └── Enter USB disk mode...     [action]
├── Reboot...                      [action]
├── Enter bootloader mode...       [action]
├── MIDI monitor >
│   ├── GO                         [monitor action; not activated]
│   └── Show Clocks                [leaf]
├── I2C monitor >
│   ├── GO                         [monitor action; not activated]
│   └── Show Getters               [leaf]
├── Mappings monitor               [view boundary]
├── MIDI >
│   ├── All notes off              [action]
│   └── All sound off              [action]
├── Plug-ins >
│   └── View info...               [view: installed plug-in information; opened]
└── Reset state...                 [action]
```

The About screen reported firmware v1.19.0. Plug-in information is a dynamic
installed-content list, not another fixed menu hierarchy. No plug-in or script
was loaded, removed, or run.

## UI Scripts

```text
UI Scripts
└── Run UI script...               [file-selection/execution boundary]
```

## Coverage limits and final state

All seven top-level sections were visited. The nested lists above were read
through screen captures, with explicit boundaries for destructive commands,
calibration workflows, dynamic file/script lists, unavailable algorithm-specific
editors, and value vocabularies that would require changing a setting to inspect.
Those boundaries are intentionally **not** represented as fully mapped subtrees.

The preset remained Init with zero slots. The final ordinary display was restored
to the Inputs/Outputs overview, with Algorithms selected when reopening the main
menu. No held or pending-release controls remained. Persistent setting equality
cannot be independently proven by `remote_state`, which reports only local
commanded input state; the no-change assurance rests on using navigation inputs
and avoiding all value/commit/mutation actions during this pass.

For executable gesture examples, see the [MCP remote-control tutorial](mcp-remote-control-tutorial.md).
