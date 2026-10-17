# Operating the Disting NT through MCP: an agent tutorial

Use this tutorial when a user asks you to operate the NT's physical-style controls through `nt_helper`. Work through the live `nt_helper` MCP tools; repository test suites are not a substitute for operating the device.

## 1. Establish a feedback loop

Discover these tools in the **nt_helper** MCP namespace:

- `remote_state`: availability, index map, busy state, and local commanded state.
- `remote_control`: one ordered, bounded gesture.
- `show_screen`: a capture of the actual NT display.

Start with `remote_state({})` and `show_screen({})`. Proceed when `available` is true, `busy` is false, and you understand the visible screen. Availability requires a synchronized live connection with supported firmware/transport; offline and demo modes cannot control hardware.

**Observe → gesture → observe.** Send a short gesture, capture the screen, and decide the next gesture from what is actually visible. Menus remember selection, and controls are context-sensitive. Avoid long blind scripts. An immediate capture can show the previous selection; wait briefly and recapture before pressing an uncertain row.

For the firmware v1.19.0 menu hierarchy, inspected settings submenus, and mutation boundaries, use the [live menu map](disting-nt-menu-map.md). It marks branches unavailable on an empty preset rather than assuming their contents.

Call `show_screen({})` to observe navigation. It accepts no arguments and never switches display mode. Use the separate `set_display_mode` tool only when the user explicitly requests a parameter/algorithm/overview/VU view; it can dismiss menus and is not a menu navigation control. The screenshot path sends the dedicated SysEx Wake command first, so a sleeping screen can be captured without pressing a menu button or changing settings. Older builds bypassed that wake step in MCP/chat and could return a black screensaver image.

### Tool responses are not hardware acknowledgements

A successful `remote_control` response means transport sending completed. It explicitly reports `delivery: "transport_send_only"`, `acknowledged: false`, and `hardware_reported: null`.

`remote_state.commanded` is local bookkeeping, not a reading of physical pot positions, current parameters, or executed button actions. Confirm a navigation result with the screen; confirm a parameter-edit result with an appropriate fresh parameter read when available.

## 2. Translate physical controls to indices

| Physical control | Action type | Index |
|---|---|---|
| Buttons 1, 2, 3, 4 | `push` / `release` | 0, 1, 2, 3 |
| Left, center, right pot presses | `push` / `release` | 4, 5, 6 |
| Left, right encoder presses | `push` / `release` | 7, 8 |
| Left, right encoder rotation | `encoder_turn` | 0, 1 |
| Left, center, right pot rotation | `pot_turn` | 0, 1, 2 |

Press indices and rotation indices are different namespaces. For example, holding the left encoder uses push index **7**, but rotating it uses encoder index **0**.

`capabilities.pot_indices` lists all three indices: `[0,1,2]`. Older builds incorrectly reported `[0,2]` despite supporting the center pot; that metadata bug is fixed in source. A running older app may still show it until updated.

## 3. Send a tap

Example: tap physical Button 1.

```json
{
  "actions": [
    {"type": "push", "index": 0},
    {"type": "wait", "duration_ms": 50},
    {"type": "release", "index": 0}
  ]
}
```

Pass this object to `remote_control`, then call `show_screen({})`.

The 50 ms wait is a short dwell used successfully during exploration, not a documented firmware requirement. Keep intentional holds inside a single call.

## 4. Navigate menus: a verified walkthrough

This walkthrough was performed on an NT showing an empty preset's Inputs/Outputs overview. No algorithm was added or preset saved.

1. **Tap Button 1** (`push/release` index 0).
   - Observed: the main menu opened, showing Algorithms, Presets, Mappings, and other entries.
2. **Rotate the left encoder by +1**:

   ```json
   {"actions":[{"type":"encoder_turn","index":0,"delta":1}]}
   ```

   - Observed: selection moved from Algorithms to Presets.
   - Rotate by -1 to return to Algorithms. Inspect the screen rather than assuming the starting selection.
3. **Press the left encoder** (`push/release` index 7) with Algorithms selected.
   - Observed: entered the Algorithms submenu, containing Add algorithm, Respecify algorithm, Remove algorithm, etc.
4. **Press the left encoder** with Add algorithm selected.
   - Observed: entered the algorithm chooser. The screen showed a description, `Tags`, `Select`, and `Add` rows.
5. **Rotate the left encoder** to highlight `Select`.
   - Observed: +1 moved from Tags to Select in this chooser.
6. **Rotate the right encoder by +1** with Select highlighted.
   - Observed: the selected algorithm changed from Accent sweep to Arpeggiator, and its description changed too.
7. **Tap Button 1** to exit the chooser/menu.
   - Observed: returned to the original overview without adding an algorithm.

This reveals a useful pattern: the **left encoder selects a menu/row**, its **press enters a submenu**, and the **right encoder can change the highlighted row's value**. That pattern is verified for the screens above, not a universal contract for every algorithm UI.

Pressing the right encoder on the main menu did not visibly change that screen. Button 4 did not exit the algorithm chooser. Use the observed Button 1 menu toggle for this workflow rather than assuming Button 4 is a universal Back button.

**Mutation boundary:** selecting an algorithm is not adding it. Stop before activating Add unless the user's task authorizes changing the preset. Read the screen before any add/remove/save/reset operation.

## 5. Pots: absolute values, not encoder-style steps

Example: command the center pot to 1024.

```json
{"actions":[{"type":"pot_turn","index":1,"value":1024}]}
```

Values range from 0 to 4095. A pot command can change a parameter or an algorithm's custom UI depending on context. Use small, deliberate changes on populated presets.

During live exploration, all three pots accepted 0 and 4095, and their local commanded values tracked the requested values. They were restored to the initial **commanded** values `[2048,2048,2048]`. The empty preset provided no visible algorithm parameter response, so this establishes tool delivery and bookkeeping, not a verified audible or parameter-level effect.

A local initial value of 2048 does not establish the physical pot's actual position. Preserve the user's intended parameter state, not merely this bookkeeping value.

## 6. Held combinations and automatic release

Example: turn the left encoder while holding its push control.

```json
{
  "actions": [
    {"type":"push","index":7},
    {"type":"encoder_turn","index":0,"delta":2},
    {"type":"release","index":7}
  ]
}
```

For combinations, push each required control, perform the turn/wait, then release them **in the same call**. Holds do not persist across calls. Outstanding holds are automatically released at the end of the gesture; explicit releases make intent clearer.

Live calls omitting the final release completed with `release_status: "cleanup_completed"`; subsequent `remote_state` showed empty held and pending-release lists. This is completed release sending, not acknowledged hardware execution.

After a gesture, inspect:

- `busy: false`
- `commanded.held_controls: []`
- `commanded.pending_release_controls: []`
- `commanded.pending: false`
- `commanded.error: null`

If a send fails or release status is unknown, stop issuing new gestures and inspect the state/connection. Re-establish a safe connection before continuing; never describe unknown release as confirmed hardware release.

## 7. Bounds and ownership

The tested tool advertised:

- 1–32 actions per call.
- Encoder delta: -1024 to +1024 per action; at most 2048 absolute ticks across a gesture.
- Wait: 0–1000 ms per action; at most 2000 ms across a gesture.
- Gesture deadline: 6000 ms, with a separate 2000 ms cleanup deadline.

Use one gesture at a time. A concurrent live call was rejected with `Remote control is busy in another gesture or UI host.` The original gesture completed and released its hold. If the remote UI owns the session, let it finish rather than attempting to take ownership.

Whole gestures are validated before execution. Live requests with an invalid encoder/pot index, mismatched action fields, or excessive cumulative ticks/waits were rejected. Some invalid inputs are rejected by the MCP client's schema before reaching the server; distinguish that from a device/server response.

`actions_completed` counts processed actions, including waits and no-ops, not hardware packets. A two-wait-only gesture reports two completed actions. Older builds excluded waits from this count.

## 8. Finish with evidence

Capture the final screen and call `remote_state({})`. Report:

1. What the screen demonstrably changed to.
2. What commands were sent but had no observable effect in this context.
3. Any remaining unknowns or cleanup errors.
4. Any deliberate preset/parameter changes and what was restored.

### Scope of the live exploration

All nine press/release indices were accepted. Both rotation indices were accepted; the left encoder visibly navigated the main menu and the right encoder visibly changed the chooser's algorithm selection. All three pot indices accepted endpoints and restored commanded values. Automatic release, concurrent-gesture refusal, maximum action count, maximum cumulative wait, and several invalid requests were exercised live.

Not established by this walkthrough: every button's context-specific function, pot effects on a populated algorithm, audible results, large encoder movement execution, unplug/reconnect recovery, or remote UI ownership behavior. Learn those only when needed for an authorized task, using the same screen-feedback loop.

For the API contract and additional tools, see [MCP API Guide](mcp-api-guide.md).
