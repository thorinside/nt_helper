# Lua Algorithm Controllers

Lua algorithm controllers are optional, algorithm-specific property editors.
They run inside nt_helper, not on the disting NT. The standard parameter editor
remains the default and fallback.

The initial implementation bundles one controller for Euclidean Patterns
(`eucp`). Installation and Gallery distribution are intentionally not enabled
yet; the bundled controller is the first adapter used to validate the interface.

## Lifecycle

A controller is a pure function of the latest immutable `Slot` from
`DistingCubit`:

1. nt_helper converts the current slot into the global `algorithm` table.
2. The Lua file runs and returns a versioned UI document.
3. Flutter validates and renders that document using native Material widgets.
4. Bound controls write through `DistingCubit.updateParameterValue`.
5. A new slot snapshot causes Lua to run again and replace the UI document.

Lua never sends MIDI or SysEx and never retains a mutable copy of slot state.
The selected Standard, Spreadsheet, or Controller mode is owned by the
parameter-editor state above `SlotDetailView`, so rebuilding the parameter
workspace or toggling Routing does not reset the selection.

## Document interface

Every script returns one table:

```lua
return {
  version = 1,
  title = "My controller",
  root = ui.column {
    children = {
      ui.text { text = algorithm.name },
      ui.slider { label = "Level", parameter = 3 }
    }
  }
}
```

Unknown versions, nodes, actions, and malformed fields are rejected. A failure
returns the user to the standard editor.

## Algorithm snapshot

The global `algorithm` table contains:

- `slot_index`, `guid`, `name`, and numeric `specifications`
- `parameters`, in device order
- `pages`, with their parameter-number lists
- raw `routing` values

Each parameter contains:

- `number`, `name`, `minimum`, `maximum`, and `default`
- `value`, `disabled`, `display_value`, and `enum_values`
- `unit`, `unit_index`, and `power_of_ten`
- `is_input` and `is_output`

Helpers are available for common lookups:

```lua
local cutoff = nt.parameter("Cutoff")
local steps = nt.channel_parameter(1, "Steps")
local channel_numbers = nt.channels()
```

`nt.parameter` accepts an optional occurrence number for duplicate names.

## UI primitives

Layout and content:

- `ui.column { children, gap, padding }`
- `ui.row { children, gap }` — a wrapping horizontal flow
- `ui.section { title, subtitle, children }` — individually collapsible
- `ui.text { text, style, align }`
- `ui.divider {}`
- `ui.spacer { size }`

The slot editor's collapse-all control collapses or unfurls every `ui.section`
while preserving the same action bar and overflow menu used by the standard
parameter editor. Collapse state survives immutable `Slot` updates.

Controls:

- `ui.slider { label, parameter, minimum, maximum, enabled }`
- `ui.toggle { label, parameter, on_value, off_value, enabled }`
- `ui.button { label, style, enabled, action }`

Buttons currently support these declarative actions:

```lua
action = { type = "set_parameter", parameter = 4, value = 0 }
action = { type = "adjust_parameter", parameter = 4, delta = 1 }
```

The host intersects controller slider ranges with the live parameter range and
clamps every control result before writing. Flutter owns input semantics,
keyboard behavior, disabled state, and the actual parameter write.

## Drawing primitives

`ui.canvas` is a responsive, normalized drawing surface. Coordinates and sizes
are expressed relative to the canvas instead of in Flutter pixels.

```lua
ui.canvas {
  semantics_label = "Four pulses across sixteen steps",
  aspect_ratio = 5,
  shapes = {
    ui.rect {
      x = 0, y = 0.1, width = 1, height = 0.8,
      radius = 0.1, fill = "surface_container_highest"
    },
    ui.circle {
      x = 0.25, y = 0.5, radius = 0.06,
      fill = "primary", stroke = "outline"
    },
    ui.line {
      x1 = 0.25, y1 = 0.5, x2 = 0.75, y2 = 0.5,
      stroke = "secondary", stroke_width = 2
    }
  }
}
```

Theme tokens include `primary`, `on_primary`, `secondary`, `tertiary`,
`surface`, `surface_container`, `surface_container_highest`, `on_surface`,
`on_surface_variant`, `outline`, `error`, and `transparent`. Hex colors are
accepted, but theme tokens should be preferred. Every canvas requires a useful
`semantics_label`; individual shapes are deliberately not focusable.

## Runtime restrictions

Controllers receive data and return data. The host exposes no Dart callbacks,
widgets, MIDI manager, filesystem, network, process, package-loading, or OS
library. Documents are limited to 512 UI nodes, 2,048 shapes, and 32 levels of
nesting.

Those restrictions are not yet a sufficient sandbox for untrusted Gallery
downloads. Before third-party installation is enabled, controller execution
also needs an isolate with a hard time budget, package manifests and capability
declarations, durable install/remove management, and clear trust information in
the Gallery UI.
