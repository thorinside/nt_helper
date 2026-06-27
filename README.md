# nt_helper

## Poly Multisample Builder Test Release

Branch: `nymph-next-fix`
Tag: `poly-multisample-builder-test-v1`
Windows zip: `nt_helper-windows-poly-multisample-builder-test-v1.zip`

This fork/branch contains an experimental Windows test build for a new Poly Multisample Builder in NT Helper.

### What It Adds

- Adds a `Samples` workspace for Disting NT Poly Multisample sample folders.
- Opens local/mounted sample folders, including mounted Disting NT SD cards.
- Opens direct Disting NT `/samples` folders for browsing and filename/tag edits.
- Parses Disting-style WAV filename tags:
  - root note;
  - low/switch note;
  - velocity layer;
  - round robin number.
- Shows a read-only keyboard map for roots, ranges, velocity layers, and round robin groups.
- Lets the sample list manually edit `Root`, `Low`, `High`, `Vel`, and `RR`.
- Applies filename/tag edits by renaming WAV files.
- Keeps mapping edits as a draft until the main `Apply` button is used.

### Local/Mounted WAV Features

These work when the sample folder is available as a normal local path.

- Draws waveform previews.
- Reads and saves WAV `smpl` loop metadata.
- Plays local WAV previews.
- Auditions loop points continuously while editing.
- Adds Destructive mode for local WAV edits:
  - trim start/end;
  - fade in/out;
  - independent fade curves;
  - gain;
  - normalize;
  - `Save`;
  - `Save as`.

Destructive trim is exact-frame. Zero-crossing snapping is only done when explicitly using the `Zero` controls.

### Direct Disting NT SD Limits

Direct SD access over MIDI/SysEx can currently list folders/files and rename files, but waveform/audio work is disabled.

The current file download path appears to return whole files in one nibble-encoded SysEx response. That is not practical for automatic WAV waveform display, loop metadata inspection, or audio preview.

Useful future firmware/API support would be:

- ranged file reads, e.g. `read_file(path, offset, length)`;
- WAV metadata summary reads;
- WAV `smpl` loop metadata write/patch support;
- optional waveform peak summaries.

Until then, waveform, playback, loop editing, and destructive WAV editing are local/mounted-folder features only.

### Fixes Included

- Manual root edits now clear stale `No root` warnings.
- Destructive trim no longer secretly snaps to zero-crossings while dragging/sliding.
- Fade preview and rendered fade timing are aligned more closely.
- Keyboard-map selection and list selection stay linked for the tested sample sets.

### Validation

- `flutter analyze` passed for the touched sample-builder and WAV files.
- Parser tests passed.
- WAV metadata/render tests passed.
- Windows release build completed successfully.

### Still Experimental

- Complex velocity/round-robin libraries need more real-world testing.
- Drag/drop import and drag-to-key assignment are not implemented yet.
- Decent Sampler conversion/export is not implemented yet.
- Direct Disting NT SD waveform/audio editing needs better file access from the device.

---

A cross-platform Flutter application designed for editing presets on the Expert Sleepers Disting NT module. It provides an intuitive interface for managing algorithms, parameters, and mappings on your Disting NT device.

## Core Features

- **Comprehensive Preset Management**: Easily load, save, and create new presets.
- **Detailed Algorithm Editing**: Access and modify all parameters for each algorithm in your preset. Some algorithms feature custom UI views for a more specialized editing experience.
- **Advanced Parameter Mapping**: Configure CV, MIDI (including a CC detection helper), and I2C mappings for dynamic control over your sound.
- **Visual Routing Analysis**: Understand the signal flow within your presets with a clear graphical representation.
- **Performance Mode**: View and interact with all your mapped parameters on a single screen, with real-time updates from MIDI/I2C (CV changes provide offsets and are not currently reflected in real-time on sliders).
- **Specialized Editors**: Benefit from dedicated UI components for certain parameter types, such as an intuitive BPM editor for tempo-related parameters.
- **MCP Server**: Includes a built-in MCP (Model Context Protocol) server (on desktop platforms) for integration with external tools and AI-driven workflows. See the [Model Context Protocol website](https://modelcontextprotocol.io/introduction) for more details on MCP.
- **Offline Data Management**: Synchronize and manage algorithm metadata for offline use or when the Disting NT is not connected. Features incremental sync and improved algorithm rescan UX.
- **Drag & Drop Installation**: Install preset packages by simply dragging and dropping them onto the load dialog (desktop platforms).
- **Cross-Platform**: Runs on Windows, macOS, Linux, iOS, and Android.

## System Requirements

| Platform | Minimum Version |
|----------|-----------------|
| macOS    | 10.15 (Catalina) |
| iOS      | 15.6 |
| Android  | API 24 (7.0 Nougat) |
| Windows  | 10 |
| Linux    | Ubuntu 20.04 LTS+ |

## Getting Started

1.  Download the latest release for your platform from the [GitHub Releases](https://github.com/thorinside/nt_helper/releases) page (or [TestFlight](https://testflight.apple.com/join/BSFFSpd3) for iOS).
2.  Install the application.
3.  Connect your Disting NT to your device via USB.
4.  Launch `nt_helper`, select the MIDI input/output ports for your Disting NT, and connect.

For detailed instructions, troubleshooting, and a full feature list, please refer to the [project website documentation](https://nosuch.dev/nt-helper).

## Startup Diagnostics

If the app does not show a window, nt_helper writes an early startup log that can be shared with the developer:

- **Windows:** `%LOCALAPPDATA%\nt_helper\logs\nt_helper_startup.log`
- **macOS/Linux:** `~/.nt_helper/logs/nt_helper_startup.log`

On Windows, if that file is not created at all, the failure is likely occurring before nt_helper's native entry point runs (for example, a missing system runtime or loader error).

The Disting NT does not need to be connected for the app window to open. After the UI starts, the same log records MIDI device discovery/autoconnect attempts and will say when the saved Disting NT MIDI ports are not visible. In Flutter CLI output, `Lost connection to device` refers to the macOS/Windows app process used by `flutter run`, not to the Disting NT hardware.

## Recent Updates

- **Experimental fork test build**: The `nymph-next-fix` branch includes a Poly Multisample Builder test workspace for editing Disting NT sample-folder structures and local/mounted WAV loop/audio edits. See the top of this README for the test-release notes.
- **v1.39.0+77**: Added incremental sync and improved algorithm rescan UX
- **Drag & Drop Support**: Preset packages can now be installed via drag-and-drop on desktop platforms
- **MCP Enhancements**: Simplified server implementation, improved connection stability, and added CPU usage monitoring
- **Algorithm Matching**: Added fuzzy category matching for better algorithm discovery
- **Routing Improvements**: Enhanced real-time routing data queries from hardware

## Contributing

Contributions, issues, and feature requests are welcome! Please feel free to check the [issues page](https://github.com/thorinside/nt_helper/issues).

## License

This project is open source.

## MCP Tools

The application includes an MCP (Model Context Protocol) server with 6 tools for AI-assisted preset creation:

| Tool | Purpose |
|------|---------|
| `search` | Find algorithms by name or category |
| `show` | Inspect preset, slot, parameter, routing, CPU, or screen |
| `new` | Create a new preset with optional algorithms |
| `save` | Save the current preset to the device |
| `add` | Add an algorithm to the preset |
| `edit` | Modify preset, slot, or parameter values/mappings |

Most tools use `target` to specify what they operate on (e.g., `target: "algorithm"`, `target: "slot"`).

See [docs/mcp-api-guide.md](docs/mcp-api-guide.md) for detailed documentation.
