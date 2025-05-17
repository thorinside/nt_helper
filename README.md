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
- **Offline Data Management**: Synchronize and manage algorithm metadata for offline use or when the Disting NT is not connected.
- **Cross-Platform**: Runs on Windows, macOS, Linux, iOS, and Android.

## Getting Started

1.  Download the latest release for your platform from the [GitHub Releases](https://github.com/thorinside/nt_helper/releases) page (or [TestFlight](https://testflight.apple.com/join/BSFFSpd3) for iOS).
2.  Install the application.
3.  Connect your Disting NT to your device via USB.
4.  Launch `nt_helper`, select the MIDI input/output ports for your Disting NT, and connect.

For detailed instructions, troubleshooting, and a full feature list, please refer to the [project website documentation](/nt_helper.md) or the `nt_helper.md` file within the project.

## Contributing

Contributions, issues, and feature requests are welcome! Please feel free to check the [issues page](https://github.com/thorinside/nt_helper/issues).

## License

This project is open source.

## MCP Tool Reference

The `nt_helper` application exposes several functions via its built-in MCP (Model Context Protocol) server, allowing for programmatic interaction. These tools are used by AI assistants like Cursor to control the application.

**Important Notes:**
- All tool parameters are passed as a JSON object in the request.
- All tools return a JSON string. Successful operations usually include `"success": true`, while errors include `"success": false` and an `"error": "message"` field.
- For tools interacting with the Disting NT hardware, the `parameter_index` for `set_parameter_value` and `get_parameter_value` refers to the 0-based index of the parameter *within the specific algorithm currently in that slot*, as returned by `get_current_preset`. This may not directly correspond to a globally unique parameter ID across all algorithms.
- Some tools that take no logical parameters (e.g., `get_current_preset`, `new_preset`, `save_preset`, `get_current_routing_state`) might still expect an empty JSON object `{}` or a dummy parameter (e.g. `{"random_string": ""}`) if the MCP client or server framework requires it for no-argument calls.

### Algorithm Metadata Tools

These tools interact with the locally cached algorithm metadata.

-   **`get_algorithm_details`**
    -   Description: Retrieves full metadata for a specific algorithm by its GUID.
    -   Parameters:
        -   `guid` (string, required): The unique identifier of the algorithm.
        -   `expand_features` (bool, optional, default: `false`): If `true`, resolves and includes parameters defined within features directly in the main parameter list.
    -   Returns: A JSON string representing the `AlgorithmMetadata` object for the specified GUID, or `null` if not found.

-   **`list_algorithms`**
    -   Description: Lists available algorithms, optionally filtered.
    -   Parameters:
        -   `category` (string, optional): Filters the list to algorithms belonging to this category (case-insensitive).
        -   `feature_guid` (string, optional): Filters the list to algorithms that include this feature GUID.
    -   Returns: A JSON string representing a list of `AlgorithmMetadata` objects.

-   **`find_algorithms`**
    -   Description: Performs a text search across algorithm names, descriptions, and categories.
    -   Parameters:
        -   `query` (string, required): The search query text.
    -   Returns: A JSON string representing a list of matching `AlgorithmMetadata` objects.

-   **`get_current_routing_state`**
    -   Description: Retrieves the current routing state of all algorithms in the preset, decoded into `RoutingInformation` objects. This helps visualize how audio and CV signals are passed between algorithms.
    -   Parameters: None required (may accept a dummy parameter like `{"random_string": "some_value"}` for MCP compatibility).
    -   Returns: A JSON string representing a list of `RoutingInformation` objects. Returns an empty list `[]` if the application state is not synchronized (e.g., not connected to a Disting NT or in offline mode without a loaded preset).

### Disting NT Interaction Tools

These tools interact directly with the connected Disting NT module or the offline preset representation.

-   **`get_current_preset`**
    -   Description: Gets the entire current preset state from the Disting NT (or the current offline preset).
    -   Parameters: None required (may accept a dummy parameter).
    -   Returns: A JSON string containing:
        -   `success` (bool): Indicates if the operation was successful.
        -   `presetName` (string): The name of the current preset.
        -   `slots` (array): An array (potentially sparse, up to `maxSlots` which is 32) of slot objects. Non-null slots include:
            -   `slotIndex` (int): The 0-based index of the slot.
            -   `algorithm` (object): Details of the algorithm in the slot (`guid`, `name`, `algorithmIndex` which is the module's internal reference for this instance).
            -   `parameters` (array): A list of parameter information objects for the algorithm in this slot (`parameterNumber` which is the 0-based index for API calls, `name`, `min`, `max`, `defaultValue`, `unit`, `powerOfTen`). **Note**: The live `value` is NOT returned here; use `get_parameter_value` for that.

-   **`add_algorithm`**
    -   Description: Adds a specified algorithm to the *first available empty slot* on the Disting NT. The actual slot index is determined by the module's firmware.
    -   Parameters:
        -   `algorithm_guid` (string, required): The GUID of the algorithm to add.
    -   Returns: A JSON string with a success or error message.

-   **`remove_algorithm`**
    -   Description: Removes (clears) the algorithm from a specific slot.
    -   Parameters:
        -   `slot_index` (int, required): The 0-based index of the slot to clear.
    -   Returns: A JSON string with a success or error message.

-   **`set_parameter_value`**
    -   Description: Sets the value of a specific parameter in a slot, using its human-readable display value. The tool automatically handles scaling based on the parameter's `powerOfTen` metadata.
    -   Parameters:
        -   `slot_index` (int, required): The 0-based index of the slot containing the algorithm.
        -   `parameter_index` (int, required): The 0-based index of the parameter *within the algorithm in that slot* (this is the `parameterNumber` from `get_current_preset`).
        -   `display_value` (number, required): The human-readable value to set (e.g., for a frequency in Hz, send `5.0`; for a percentage, send `50.0`). If the parameter is an enum, this should be the 0-based index of the desired enum string.
    -   Returns: A JSON string with a success or error message.

-   **`get_parameter_value`**
    -   Description: Gets the current raw integer value of a specific parameter directly from the Disting NT.
    -   Parameters:
        -   `slot_index` (int, required): The 0-based index of the slot.
        -   `parameter_index` (int, required): The 0-based index of the parameter (`parameterNumber`).
    -   Returns: A JSON string with `success`, `slotIndex`, `parameterIndex`, and `value` (the raw integer value), or an error message.

-   **`set_preset_name`**
    -   Description: Sets the name of the currently loaded preset on the device (or the current offline preset).
    -   Parameters:
        -   `name` (string, required): The new name for the preset.
    -   Returns: A JSON string with a success or error message.

-   **`set_slot_name`**
    -   Description: Sets a custom name for the algorithm in a specific slot.
    -   Parameters:
        -   `slot_index` (int, required): The 0-based index of the slot.
        -   `name` (string, required): The desired custom name for the slot.
    -   Returns: A JSON string with a success or error message.

-   **`new_preset`**
    -   Description: Tells the device to clear the current preset and start a new, empty one.
    -   Parameters: None required (may accept a dummy parameter).
    -   Returns: A JSON string with a success or error message.

-   **`save_preset`**
    -   Description: Tells the device to save the current working preset (persisting all changes to algorithms, parameters, and names).
    -   Parameters: None required (may accept a dummy parameter).
    -   Returns: A JSON string with a success or error message.

-   **`move_algorithm_up`**
    -   Description: Moves an algorithm in a specified slot one position up in the slot list (e.g., slot 2 moves to slot 1).
    -   Parameters:
        -   `slot_index` (int, required): The 0-based index of the slot containing the algorithm to move up. Cannot be slot 0.
    -   Returns: A JSON string with a success or error message.

-   **`move_algorithm_down`**
    -   Description: Moves an algorithm in a specified slot one position down in the slot list (e.g., slot 1 moves to slot 2).
    -   Parameters:
        -   `slot_index` (int, required): The 0-based index of the slot containing the algorithm to move down. Cannot be the last occupied slot.
    -   Returns: A JSON string with a success or error message.
