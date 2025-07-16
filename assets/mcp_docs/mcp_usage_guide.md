# MCP Usage Guide for Disting NT

## Essential Tools for Small LLMs

### Getting Started
1. **`get_current_preset`** - Always start here to understand the current state
2. **`list_algorithms`** - Find available algorithms by category or search
3. **`get_algorithm_details`** - Get detailed info about specific algorithms

### Building Presets
1. **`new_preset`** - Start with a clean slate
2. **`add_algorithm`** - Add algorithms using GUID or name (fuzzy matching ≥70%)
3. **`set_parameter_value`** - Configure algorithm parameters
4. **`save_preset`** - Persist changes to device

### Working with Parameters
- Use `parameter_number` from `get_current_preset` for reliable parameter access
- Alternatively use `parameter_name` if unique within the algorithm
- Values are automatically scaled (use display values, not raw internal values)
- Always check min/max ranges from `get_current_preset`

### Routing and Signal Flow
- **`get_routing`** - See current bus assignments and signal flow
- Algorithms process top-to-bottom (slot 0 → slot N)
- Use `move_algorithm_up`/`move_algorithm_down` to change processing order
- Physical names only: Input N, Output N, Aux N, None

### Batch Operations
- **`set_multiple_parameters`** - Efficient multi-parameter updates
- **`build_preset_from_json`** - Create complete presets from structured data

### Debugging and Diagnostics
- **`mcp_diagnostics`** - Check MCP server health and connection status
- **`get_cpu_usage`** - Monitor device performance
- **`get_module_screenshot`** - Visual confirmation of device state

### Best Practices
- Check device connection status if operations fail
- Use exact algorithm names or GUIDs for reliable results
- Always verify parameter ranges before setting values
- Save presets after making changes to persist them