# Offline Preset Building Accessibility

**Severity: Medium**

## User Feedback

A blind tester requested improved offline capabilities so presets can be built without connected hardware and later uploaded to the Disting NT. This capability largely **already exists** but needs better discoverability and accessibility.

## Current Offline Capabilities

The app supports two hardware-free modes:

### Demo Mode
- Available immediately from the device selection screen via "Demo" button
- Creates a simulated Disting NT with pre-configured algorithms (Clock Divider, Step Sequencer, VCO, Envelope, Delay)
- Full parameter editing and manipulation
- Uses `MockDistingMidiManager` for complete simulation

### Offline Mode
- Available when algorithm metadata has been previously cached (requires one prior connection)
- Activated via "Go Offline" button on device selection screen
- Uses `OfflineDistingMidiManager` with database-backed metadata
- Full preset building capability

## What Works Offline

| Feature | Works Offline? | Notes |
|---------|---------------|-------|
| Create new preset | Yes | `requestNewPreset()` |
| Add algorithms | Yes | Full algorithm library from cache |
| Remove algorithms | Yes | `requestRemoveAlgorithm()` |
| Reorder algorithms | Yes | Move up/down |
| Edit parameter values | Yes | All parameters fully editable |
| Set enum values | Yes | Enum strings from cache |
| Set parameter strings | Yes | File names, custom values |
| Rename slots | Yes | Custom algorithm names |
| Rename presets | Yes | Preset title editing |
| Set performance mappings | Yes | Assign to pages P1-P5 |
| Save preset to database | Yes | `requestSavePreset()` |
| Load saved preset | Yes | `loadPresetOffline()` |
| View algorithm documentation | Yes | From cached metadata |

## What Requires Hardware

| Feature | Why | Impact |
|---------|-----|--------|
| Lua script execution | Runs on hardware | Cannot test scripts offline |
| SD card operations | Physical storage | No file upload/download |
| CPU monitoring | Hardware metrics | No performance data |
| Video streaming | Hardware output | No visual feedback |
| Firmware updates | Hardware flash | Must be connected |
| Plugin backup/restore | Hardware storage | Must be connected |
| Real-time parameter polling | MIDI communication | Values don't update live |

## Accessibility Issues with Offline Mode

### 1. Discoverability
The "Demo" and "Go Offline" buttons are on the device selection screen but have no special emphasis or explanation. A screen reader user hearing a list of MIDI devices may not realize there are alternative modes available.

**Fix:** Add semantic descriptions explaining each mode:
- "Demo mode: Try the app with simulated hardware, no Disting NT required"
- "Go offline: Build and edit presets using previously cached algorithm data"

### 2. Mode Indicator
Once in offline/demo mode, the only visual indicator is a small badge or subtle UI change. Screen reader users may not know they're in offline mode.

**Fix:** Add `SemanticsService.announce()` when entering offline/demo mode: "Now in offline mode. You can build and save presets. Some features require hardware connection."

### 3. Graceful Error Handling
When a user attempts a hardware-only operation offline, the app throws `UnsupportedError`. These errors should be caught and presented as accessible error messages rather than crashes.

**Fix:** Wrap hardware-only operations in try-catch with user-friendly announcements: "This feature requires a connected Disting NT"

### 4. Upload Workflow
The workflow for uploading an offline-built preset to hardware when reconnecting is not documented or obvious. Users need to:
1. Build preset offline
2. Save to database
3. Connect to hardware
4. Load the saved preset
5. Upload/sync to hardware

**Fix:** Add an accessible "Upload to Hardware" action when reconnecting with saved offline presets.

### 5. Algorithm Library in Demo Mode
Demo mode provides only 5 pre-configured algorithms. Users wanting to explore the full algorithm library should be guided to use Offline mode (which requires one prior connection for metadata caching) or use the Gallery screen.

## Recommended Improvements

### Quick Wins
1. Add semantic labels to Demo/Go Offline buttons explaining their purpose
2. Announce mode transitions to screen readers
3. Catch and announce hardware-only operation attempts gracefully

### Medium Effort
4. Add an "Offline Presets" section to the preset browser showing database-saved presets
5. Add a "Sync to Hardware" workflow when reconnecting
6. Document the offline workflow in an in-app help screen

### Larger Effort
7. Allow algorithm metadata download/caching without a full sync (e.g., from a bundled database or web download)
8. Implement a "preset export" feature that saves presets as portable files (JSON/SysEx) for sharing
