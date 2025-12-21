# nt_helper

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

## Recent Updates

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
