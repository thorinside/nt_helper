local channel_numbers = nt.channels()
local channel_views = {}

local function transfer_shapes(gain, offset)
  local input_low = -5
  local input_high = 5
  local output_low = offset + input_low * gain
  local output_high = offset + input_high * gain
  local output_range = math.max(5, math.abs(output_low), math.abs(output_high))

  local function x_position(value)
    return 0.08 + ((value - input_low) / (input_high - input_low)) * 0.84
  end

  local function y_position(value)
    return 0.5 - (value / output_range) * 0.4
  end

  return {
    ui.rect {
      x = 0,
      y = 0.04,
      width = 1,
      height = 0.92,
      radius = 0.08,
      fill = "surface_container_highest"
    },
    ui.line {
      x1 = 0.08,
      y1 = 0.5,
      x2 = 0.92,
      y2 = 0.5,
      stroke = "outline"
    },
    ui.line {
      x1 = 0.5,
      y1 = 0.1,
      x2 = 0.5,
      y2 = 0.9,
      stroke = "outline"
    },
    ui.line {
      x1 = x_position(input_low),
      y1 = y_position(output_low),
      x2 = x_position(input_high),
      y2 = y_position(output_high),
      stroke = "primary",
      stroke_width = 3
    },
    ui.circle {
      x = x_position(input_low),
      y = y_position(output_low),
      radius = 0.035,
      fill = "primary"
    },
    ui.circle {
      x = x_position(input_high),
      y = y_position(output_high),
      radius = 0.035,
      fill = "primary"
    }
  }
end

for _, channel in ipairs(channel_numbers) do
  local enabled = nt.channel_parameter(channel, "Enable")
  local scale = nt.channel_parameter(channel, "Scale")
  local offset = nt.channel_parameter(channel, "Offset")
  local fine = nt.channel_parameter(channel, "Fine")
  local octaves = nt.channel_parameter(channel, "Octaves")
  local semitones = nt.channel_parameter(channel, "Semitones")

  if scale ~= nil and offset ~= nil and fine ~= nil and
      octaves ~= nil and semitones ~= nil then
    local gain = scale.value / 1000
    local total_offset = offset.value / 10 + fine.value / 1000 +
      octaves.value + semitones.value / 12
    local children = {}

    if enabled ~= nil then
      table.insert(children, ui.toggle {
        label = "Enabled",
        parameter = enabled.number
      })
    end

    table.insert(children, ui.canvas {
      semantics_label = string.format(
        "Illustrative channel %d transfer preview. Output equals input times %.3f plus %.3f volts.",
        channel,
        gain,
        total_offset
      ),
      aspect_ratio = 4.8,
      shapes = transfer_shapes(gain, total_offset)
    })
    table.insert(children, ui.slider {
      label = "Scale",
      parameter = scale.number
    })
    table.insert(children, ui.slider {
      label = "Offset",
      parameter = offset.number
    })
    table.insert(children, ui.slider {
      label = "Fine",
      parameter = fine.number
    })
    table.insert(children, ui.slider {
      label = "Octaves",
      parameter = octaves.number
    })
    table.insert(children, ui.slider {
      label = "Semitones",
      parameter = semitones.number
    })
    table.insert(children, ui.row {
      gap = 8,
      children = {
        ui.button {
          label = "Unity",
          style = "outlined",
          enabled = scale.value ~= 1000,
          action = {
            type = "set_parameter",
            parameter = scale.number,
            value = 1000
          }
        },
        ui.button {
          label = "Invert",
          style = "outlined",
          enabled = scale.value ~= -1000,
          action = {
            type = "set_parameter",
            parameter = scale.number,
            value = -1000
          }
        },
        ui.button {
          label = "Zero gain",
          style = "outlined",
          enabled = scale.value ~= 0,
          action = {
            type = "set_parameter",
            parameter = scale.number,
            value = 0
          }
        }
      }
    })

    table.insert(channel_views, ui.section {
      title = "Channel " .. channel,
      subtitle = string.format(
        "gain %.3f · offset %.3f V",
        gain,
        total_offset
      ),
      children = children
    })
  end
end

if #channel_views == 0 then
  table.insert(channel_views, ui.text {
    text = "No attenuverter channels were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Attenuverter",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = channel_views
  }
}
