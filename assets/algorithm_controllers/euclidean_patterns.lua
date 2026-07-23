local channel_numbers = nt.channels()
local channel_views = {}

local function pattern_shapes(steps, pulses, rotation)
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.12,
      width = 1,
      height = 0.76,
      radius = 0.12,
      fill = "surface_container_highest"
    }
  }

  for step = 0, steps - 1 do
    local x = 0.5
    if steps > 1 then x = 0.04 + (step / (steps - 1)) * 0.92 end
    local source_step = step - rotation
    local is_pulse = ((source_step * pulses) % steps) < pulses
    table.insert(shapes, ui.circle {
      x = x,
      y = 0.5,
      radius = 0.065,
      fill = is_pulse and "primary" or "surface",
      stroke = is_pulse and "primary" or "outline",
      stroke_width = is_pulse and 2 or 1
    })
  end

  return shapes
end

for _, channel in ipairs(channel_numbers) do
  local enabled = nt.channel_parameter(channel, "Enable")
  local steps = nt.channel_parameter(channel, "Steps")
  local pulses = nt.channel_parameter(channel, "Pulses")
  local rotation = nt.channel_parameter(channel, "Rotation")

  if steps ~= nil and pulses ~= nil and rotation ~= nil then
    local children = {}
    if enabled ~= nil then
      table.insert(children, ui.toggle {
        label = "Enabled",
        parameter = enabled.number
      })
    end

    table.insert(children, ui.canvas {
      semantics_label = "Illustrative channel " .. channel ..
        " pattern preview, " ..
        pulses.value .. " pulses across " .. steps.value ..
        " steps, rotation " .. rotation.value ..
        "; this is not live phase.",
      aspect_ratio = 5.5,
      shapes = pattern_shapes(steps.value, pulses.value, rotation.value)
    })
    table.insert(children, ui.slider {
      label = "Steps",
      parameter = steps.number
    })
    table.insert(children, ui.slider {
      label = "Pulses",
      parameter = pulses.number
    })
    table.insert(children, ui.slider {
      label = "Rotation",
      parameter = rotation.number
    })
    table.insert(children, ui.button {
      label = "Reset rotation",
      style = "outlined",
      enabled = rotation.value ~= 0,
      action = {
        type = "set_parameter",
        parameter = rotation.number,
        value = 0
      }
    })

    table.insert(channel_views, ui.section {
      title = "Channel " .. channel,
      subtitle = steps.value .. " steps · " .. pulses.value ..
        " pulses · rotation " .. rotation.value,
      children = children
    })
  end
end

if #channel_views == 0 then
  table.insert(channel_views, ui.text {
    text = "No Euclidean pattern channels were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Euclidean Patterns",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = {
      ui.text {
        text = #channel_numbers .. " channels configured by the algorithm",
        style = "caption"
      },
      ui.column {
        gap = 16,
        children = channel_views
      }
    }
  }
}
