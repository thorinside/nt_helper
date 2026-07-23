local channel_numbers = nt.channels()
local channel_views = {}

local function enum_label(parameter)
  if parameter == nil then return "" end
  local label = parameter.enum_values[parameter.value + 1]
  if label ~= nil and label ~= "" then return label end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function divisor_value(parameter)
  if parameter == nil then return 1 end
  local parsed = tonumber(enum_label(parameter))
  if parsed ~= nil then return math.max(1, parsed) end
  return math.max(1, parameter.value)
end

local function pulse_shapes(divisor)
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.12,
      width = 1,
      height = 0.76,
      radius = 0.08,
      fill = "surface_container_highest"
    }
  }

  for pulse = 0, 31 do
    local active = pulse % divisor == 0
    table.insert(shapes, ui.circle {
      x = 0.035 + (pulse / 31) * 0.93,
      y = 0.5,
      radius = active and 0.035 or 0.021,
      fill = active and "primary" or "surface",
      stroke = active and "primary" or "outline",
      stroke_width = active and 2 or 1
    })
  end
  return shapes
end

for _, channel in ipairs(channel_numbers) do
  local enabled = nt.channel_parameter(channel, "Enable")
  local divider_type = nt.channel_parameter(channel, "Type")
  local free_divisor = nt.channel_parameter(channel, "Divisor", 1)
  local binary_divisor = nt.channel_parameter(channel, "Divisor", 2)
  local metrical_divisor = nt.channel_parameter(channel, "Divisor", 3)

  if divider_type ~= nil then
    local active_divisor = free_divisor
    if divider_type.value == 1 then active_divisor = binary_divisor end
    if divider_type.value == 2 then active_divisor = metrical_divisor end

    if active_divisor ~= nil then
      local divisor = divisor_value(active_divisor)
      local children = {}
      if enabled ~= nil then
        table.insert(children, ui.toggle {
          label = "Enabled",
          parameter = enabled.number
        })
      end
      table.insert(children, ui.choice {
        label = "Type",
        parameter = divider_type.number
      })
      if divider_type.value == 0 then
        table.insert(children, ui.slider {
          label = "Divisor",
          parameter = active_divisor.number
        })
      else
        table.insert(children, ui.choice {
          label = "Divisor",
          parameter = active_divisor.number
        })
      end
      table.insert(children, ui.canvas {
        semantics_label = "Illustrative channel " .. channel ..
          " divide by " .. divisor ..
          " pulse preview across 32 source pulses; this is not live phase.",
        aspect_ratio = 6,
        shapes = pulse_shapes(divisor)
      })

      table.insert(channel_views, ui.section {
        title = "Channel " .. channel,
        subtitle = enum_label(divider_type) .. " · divide by " .. divisor,
        children = children
      })
    end
  end
end

if #channel_views == 0 then
  table.insert(channel_views, ui.text {
    text = "No clock-divider channels were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Clock Divider",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = channel_views
  }
}
