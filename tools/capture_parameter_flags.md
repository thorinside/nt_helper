# Parameter Flag Capture Instructions

## Goal
Capture the raw SysEx 0x44 (AllParameterValues) message from the disting NT hardware to analyze which parameters have the flag set in bits 16-20.

## Option 1: Use MIDI Monitor (Easiest)

1. **Download a MIDI Monitor tool:**
   - macOS: [MIDI Monitor](https://www.snoize.com/MIDIMonitor/)
   - Windows: [MIDI-OX](http://www.midiox.com/)
   - Linux: `aseqdump` or `amidi`

2. **Run the nt_helper app:**
   ```bash
   flutter run -d macos
   ```

3. **Connect to your disting NT in the app**

4. **Open MIDI Monitor and select the disting NT device**

5. **In nt_helper, trigger a parameter query:**
   - Navigate to slot 0 (which should have the Clock algorithm)
   - The app should automatically query parameters when you switch slots
   - OR use the MCP server to query: `get_multiple_parameters` tool

6. **In MIDI Monitor, find the SysEx message starting with:**
   ```
   F0 00 21 27 6D <sysexId> 44 ...
   ```
   - `F0` = SysEx start
   - `00 21 27` = Expert Sleepers manufacturer ID
   - `6D` = disting NT prefix
   - `<sysexId>` = Your disting's SysEx ID (usually 00)
   - `44` = All Parameter Values response

7. **Copy the entire hex dump**

8. **Paste it into the test tool:**
   ```bash
   # Edit this file and replace PASTE_HEX_DUMP_HERE with the actual hex dump:
   vim tools/parameter_flag_analyzer.dart

   # Then run:
   dart run tools/parameter_flag_analyzer.dart
   ```

## Option 2: Use the Flutter App (Interactive)

Run this Dart code from the Flutter DevTools console or add it temporarily to the app:

```dart
// Get the MIDI manager from the cubit
final midiManager = context.read<DistingCubit>().disting;

// Query parameters for slot 0
final result = await midiManager.requestAllParameterValues(0);

// Print the results
for (final pv in result!.values) {
  print('Parameter ${pv.parameterNumber}: ${pv.value}');
}
```

## Option 3: Use MCP Server

If you have the MCP server running:

```bash
# Connect the MCP tool
# Then use get_multiple_parameters for slot 0

# This will internally query all parameters
```

## Next Steps

Once you have the hex dump:

1. **Paste it into `tools/parameter_flag_analyzer.dart`**
2. **Run the analysis:**
   ```bash
   dart run tools/parameter_flag_analyzer.dart
   ```
3. **The tool will show which parameters have the flag set**

## Expected Output Format

```
Parameter Flag Test - Examining SysEx 0x44 Message
======================================================================

Full message: f0 00 21 27 6d 00 44 ...
Algorithm Index: 0

Parameter Analysis:
----------------------------------------------------------------------
Param# | Byte0 | Byte1 | Byte2 | Flag  | Value   | Analysis
----------------------------------------------------------------------
     0 |  0x00 |  0x00 |  0x00 |     0 |       0 |
     1 |  0x04 |  0x1e |  0x00 |     1 |    3840 | <<< FLAG SET!
     2 |  0x00 |  0x00 |  0x00 |     0 |       0 |
...
======================================================================
```

The "Flag" column shows the value of bits 16-20.
Parameters with non-zero flag values will be marked with "<<< FLAG SET!"
