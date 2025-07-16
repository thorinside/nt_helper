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

## MCP Tool Reference

The `nt_helper` application exposes a comprehensive set of functions via its built-in MCP (Model Context Protocol) server, allowing for programmatic interaction. These tools enable AI assistants to control the application and interact with the Disting NT hardware.

**Important Notes:**
- All tool parameters are passed as a JSON object in the request.
- All tools return a JSON string. Successful operations return the requested data, while errors include an `"error": "message"` field.
- Parameter references use `parameter_number` (0-based index) from `get_current_preset` or `parameter_name` for unique parameter names.
- Values are automatically scaled using display values (not raw internal values).
- Some tools accept empty JSON object `{}` when no parameters are required.

### Algorithm Metadata Tools

**`get_algorithm_details`** - Retrieves full metadata for a specific algorithm
- Parameters: `algorithm_guid` (string) OR `algorithm_name` (string), `expand_features` (bool, optional)
- Supports fuzzy matching ≥70% similarity for algorithm names
- Returns: Complete `AlgorithmMetadata` object with parameters, categories, and description

**`list_algorithms`** - Lists available algorithms with optional filtering  
- Parameters: `category` (string, optional), `query` (string, optional)
- Supports fuzzy category matching and text search across names/descriptions
- Returns: Array of algorithm summaries with name, GUID, and first sentence of description

**`get_routing`** - Retrieves current routing state and signal flow
- Parameters: None
- Actively refreshes routing data from hardware before returning
- Returns: Bus usage information showing inputs/outputs for each algorithm slot

### Core Disting NT Tools

**`get_current_preset`** - Gets complete preset state including all slots and parameters
- Parameters: None  
- Returns: Preset name, slot configurations, algorithm details, and parameter info with live values
- Essential starting point for understanding current device state

**`add_algorithm`** - Adds algorithm to first available slot
- Parameters: `algorithm_guid` (string) OR `algorithm_name` (string)
- Supports exact and fuzzy name matching
- Returns: Success confirmation with slot placement

**`remove_algorithm`** - Clears algorithm from specified slot
- Parameters: `slot_index` (int, required)
- Returns: Success confirmation

**`set_parameter_value`** - Sets parameter value using display values
- Parameters: `slot_index` (int), `parameter_number` (int) OR `parameter_name` (string), `value` (number)
- Automatically handles scaling based on parameter metadata
- Returns: Success confirmation with parameter details

**`get_parameter_value`** - Gets current parameter value
- Parameters: `slot_index` (int), `parameter_number` (int)
- Returns: Scaled parameter value with metadata

### Preset Management Tools

**`set_preset_name`** / **`get_preset_name`** - Manage preset names
- Set parameters: `name` (string, required)
- Get parameters: None
- Returns: Success confirmation or current preset name

**`set_slot_name`** / **`get_slot_name`** - Manage custom slot names  
- Set parameters: `slot_index` (int), `name` (string)
- Get parameters: `slot_index` (int)
- Returns: Success confirmation or current slot name

**`new_preset`** - Creates new empty preset
- Parameters: None
- Clears all slots and resets to default state

**`save_preset`** - Saves current preset to device
- Parameters: None  
- Persists all changes to device memory

### Algorithm Movement Tools

**`move_algorithm_up`** / **`move_algorithm_down`** - Move algorithms one position
- Parameters: `slot_index` (int, required)
- Changes processing order (slot 0 processes first)
- Returns: Success confirmation

**`move_algorithm`** - Move algorithms multiple positions
- Parameters: `slot_index` (int), `direction` (string: "up"/"down"), `steps` (int, optional, default: 1)
- Performs multiple move operations in sequence
- Returns: Success confirmation with final position

### Batch Operation Tools

**`set_multiple_parameters`** - Set multiple parameters in one operation
- Parameters: `slot_index` (int), `parameters` (array of objects with `parameter_number`/`parameter_name` and `value`)
- Efficient for configuring multiple parameters simultaneously
- Returns: Results array with success/failure status for each parameter

**`get_multiple_parameters`** - Get multiple parameter values efficiently
- Parameters: `slot_index` (int), `parameter_numbers` (array of integers)
- Returns: Array of parameter values with metadata

**`build_preset_from_json`** - Build complete preset from structured data
- Parameters: `preset_data` (object with `preset_name` and `slots` array), `clear_existing` (bool, optional, default: true)
- Supports complex preset creation with algorithms and parameter configurations
- Returns: Detailed build results with success/failure status per slot

### Utility Tools

**`get_module_screenshot`** - Captures current device display  
- Parameters: None
- Returns: Base64-encoded JPEG image of module screen
- Useful for visual confirmation of device state

**`get_cpu_usage`** - Monitors device performance
- Parameters: None
- Returns: CPU1/CPU2 percentages and per-slot usage breakdown

**`set_notes`** / **`get_notes`** - Manage preset notes
- Set parameters: `text` (string, max 7 lines × 31 characters)
- Get parameters: None
- Automatically creates/manages Notes algorithm in slot 0
- Returns: Notes content or success confirmation

**`find_algorithm_in_preset`** - Locate algorithms in current preset
- Parameters: `algorithm_guid` (string) OR `algorithm_name` (string)
- Searches all slots for specified algorithm
- Returns: Array of slot locations where algorithm is found

### Diagnostic Tools

**`mcp_diagnostics`** - Check MCP server health and connection status
- Parameters: None
- Returns: Server status, active connections, and library version information

### MCP Resources

The server also provides documentation resources accessible via MCP resource URLs:

- **`mcp://nt-helper/bus-mapping`** - Physical I/O to internal bus mapping reference
- **`mcp://nt-helper/usage-guide`** - Essential tools and best practices for small LLMs  
- **`mcp://nt-helper/algorithm-categories`** - Complete list of 44+ algorithm categories
- **`mcp://nt-helper/preset-format`** - JSON structure documentation for `build_preset_from_json`
- **`mcp://nt-helper/routing-concepts`** - Signal flow and routing fundamentals

### Best Practices

1. **Start with `get_current_preset`** to understand the current state
2. **Use exact algorithm GUIDs** when possible for reliable results  
3. **Check parameter ranges** from `get_current_preset` before setting values
4. **Save presets** after making changes to persist them
5. **Use batch operations** for efficiency when setting multiple parameters
6. **Monitor CPU usage** when building complex presets
7. **Use physical names** (Input N, Output N, Aux N) when discussing routing
