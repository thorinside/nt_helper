local position = nt.parameter("Crossfader")
local curve = nt.parameter("Curve")
local input_count = nt.parameter("Number of inputs")
local width = nt.parameter("Width")
local crossfade_input = nt.parameter("Crossfade input")

local function enum_label(parameter)
  if parameter == nil then return "" end
  local label = parameter.enum_values[parameter.value + 1]
  if label ~= nil and label ~= "" then return label end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function gains(curve_value, t)
  if curve_value == 1 then
    return math.cos(math.pi * t / 2), math.sin(math.pi * t / 2)
  end
  if curve_value == 2 then
    return math.min(1, 2 * (1 - t)), math.min(1, 2 * t)
  end
  return 1 - t, t
end

local function curve_shapes(curve_value, marker)
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.04,
      width = 1,
      height = 0.92,
      radius = 0.08,
      fill = "surface_container_highest"
    },
    ui.line {
      x1 = 0.06,
      y1 = 0.9,
      x2 = 0.94,
      y2 = 0.9,
      stroke = "outline"
    },
    ui.line {
      x1 = 0.06,
      y1 = 0.1,
      x2 = 0.06,
      y2 = 0.9,
      stroke = "outline"
    }
  }

  local previous_a = nil
  local previous_b = nil
  for sample = 0, 32 do
    local t = sample / 32
    local a, b = gains(curve_value, t)
    local x = 0.06 + t * 0.88
    local point_a = { x = x, y = 0.9 - a * 0.8 }
    local point_b = { x = x, y = 0.9 - b * 0.8 }
    if previous_a ~= nil then
      table.insert(shapes, ui.line {
        x1 = previous_a.x,
        y1 = previous_a.y,
        x2 = point_a.x,
        y2 = point_a.y,
        stroke = "primary",
        stroke_width = 3
      })
      table.insert(shapes, ui.line {
        x1 = previous_b.x,
        y1 = previous_b.y,
        x2 = point_b.x,
        y2 = point_b.y,
        stroke = "secondary",
        stroke_width = 3
      })
    end
    previous_a = point_a
    previous_b = point_b
  end

  local marker_x = 0.06 + marker * 0.88
  table.insert(shapes, ui.line {
    x1 = marker_x,
    y1 = 0.08,
    x2 = marker_x,
    y2 = 0.92,
    stroke = "tertiary",
    stroke_width = 2
  })
  return shapes
end

local children = {}
if position ~= nil and curve ~= nil and input_count ~= nil and width ~= nil then
  local normalized = math.max(0, math.min(1, position.value / 1000))
  local count = math.max(2, math.min(12, input_count.value))
  local scaled = normalized * (count - 1)
  local left = math.floor(scaled) + 1
  local local_position = scaled - math.floor(scaled)
  if left >= count then
    left = count - 1
    local_position = 1
  end
  local right = left + 1
  local left_label = string.char(64 + left)
  local right_label = string.char(64 + right)
  local gain_a, gain_b = gains(curve.value, local_position)

  table.insert(children, ui.canvas {
    semantics_label = string.format(
      "Illustrative %s crossfade preview between inputs %s and %s. Local position %.1f percent, gains %.3f and %.3f.",
      enum_label(curve),
      left_label,
      right_label,
      local_position * 100,
      gain_a,
      gain_b
    ),
    aspect_ratio = 4.8,
    shapes = curve_shapes(curve.value, local_position)
  })
  table.insert(children, ui.text {
    text = string.format(
      "Active pair %s–%s · gains %.3f / %.3f",
      left_label,
      right_label,
      gain_a,
      gain_b
    ),
    style = "caption"
  })
  table.insert(children, ui.slider {
    label = "Position",
    parameter = position.number
  })
  table.insert(children, ui.choice {
    label = "Curve",
    parameter = curve.number
  })
  table.insert(children, ui.slider {
    label = "Inputs",
    parameter = input_count.number
  })
  table.insert(children, ui.slider {
    label = "Width",
    parameter = width.number
  })

  local jump_buttons = {}
  for input = 1, count do
    table.insert(jump_buttons, ui.button {
      label = string.char(64 + input),
      style = "outlined",
      action = {
        type = "set_parameter",
        parameter = position.number,
        value = math.floor(((input - 1) / (count - 1)) * 1000 + 0.5)
      }
    })
  end
  table.insert(children, ui.text {
    text = "Jump to input",
    style = "caption"
  })
  table.insert(children, ui.row {
    gap = 8,
    children = jump_buttons
  })

  if crossfade_input ~= nil and crossfade_input.value ~= 0 then
    table.insert(children, ui.text {
      text = "Preview excludes the contribution from the assigned external crossfade CV.",
      style = "caption"
    })
  end
else
  table.insert(children, ui.text {
    text = "Crossfader controls are unavailable in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Crossfader",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = {
      ui.section {
        title = "Crossfader",
        subtitle = input_count ~= nil and
          (input_count.value .. " inputs · " .. enum_label(curve)) or nil,
        children = children
      }
    }
  }
}
