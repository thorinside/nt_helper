local function parameter_text(parameter)
  if parameter == nil then return "Unavailable" end
  local enum = parameter.enum_values[parameter.value + 1]
  if enum ~= nil and enum ~= "" then return enum end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function normalized_value(parameter)
  if parameter == nil or parameter.maximum == parameter.minimum then return 0 end
  return math.max(
    0,
    math.min(
      1,
      (parameter.value - parameter.minimum) /
        (parameter.maximum - parameter.minimum)
    )
  )
end

local function envelope_shapes(
    delay, attack, hold, decay, sustain, release, attack_shape, decay_shape)
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
      x1 = 0.04,
      y1 = 0.5,
      x2 = 0.96,
      y2 = 0.5,
      stroke = "outline"
    }
  }

  local delay_time = math.max(0, delay.value)
  local attack_time = math.max(0, attack.value)
  local hold_time = math.max(0, hold.value)
  local decay_time = math.max(0, decay.value)
  local release_time = math.max(0, release.value)
  local total_time =
    delay_time + attack_time + hold_time + decay_time + release_time
  if total_time == 0 then total_time = 1 end

  local timed_width = 0.78
  local sustain_width = 0.10
  local x0 = 0.04
  local x_delay = x0 + timed_width * delay_time / total_time
  local x_attack = x_delay + timed_width * attack_time / total_time
  local x_hold = x_attack + timed_width * hold_time / total_time
  local x_decay = x_hold + timed_width * decay_time / total_time
  local x_sustain = x_decay + sustain_width
  local x_release = x_sustain + timed_width * release_time / total_time

  local baseline_y = 0.5
  local peak_y = 0.1
  local sustain_level = normalized_value(sustain) * 2 - 1
  local sustain_y = 0.5 - sustain_level * 0.4
  local attack_exponent = 3 - normalized_value(attack_shape) * 2
  local decay_exponent = 3 - normalized_value(decay_shape) * 2

  table.insert(shapes, ui.line {
    x1 = x0,
    y1 = baseline_y,
    x2 = x_delay,
    y2 = baseline_y,
    stroke = "outline",
    stroke_width = 2
  })

  local previous_x = x_delay
  local previous_y = baseline_y
  for sample = 1, 8 do
    local position = sample / 8
    local curved = position ^ attack_exponent
    local x = x_delay + (x_attack - x_delay) * position
    local y = baseline_y + (peak_y - baseline_y) * curved
    table.insert(shapes, ui.line {
      x1 = previous_x,
      y1 = previous_y,
      x2 = x,
      y2 = y,
      stroke = "primary",
      stroke_width = 3
    })
    previous_x = x
    previous_y = y
  end

  table.insert(shapes, ui.line {
    x1 = x_attack,
    y1 = peak_y,
    x2 = x_hold,
    y2 = peak_y,
    stroke = "secondary",
    stroke_width = 3
  })

  previous_x = x_hold
  previous_y = peak_y
  for sample = 1, 8 do
    local position = sample / 8
    local curved = 1 - (1 - position) ^ decay_exponent
    local x = x_hold + (x_decay - x_hold) * position
    local y = peak_y + (sustain_y - peak_y) * curved
    table.insert(shapes, ui.line {
      x1 = previous_x,
      y1 = previous_y,
      x2 = x,
      y2 = y,
      stroke = "tertiary",
      stroke_width = 3
    })
    previous_x = x
    previous_y = y
  end

  table.insert(shapes, ui.line {
    x1 = x_decay,
    y1 = sustain_y,
    x2 = x_sustain,
    y2 = sustain_y,
    stroke = "primary",
    stroke_width = 3
  })

  previous_x = x_sustain
  previous_y = sustain_y
  for sample = 1, 8 do
    local position = sample / 8
    local curved = 1 - (1 - position) ^ decay_exponent
    local x = x_sustain + (x_release - x_sustain) * position
    local y = sustain_y + (baseline_y - sustain_y) * curved
    table.insert(shapes, ui.line {
      x1 = previous_x,
      y1 = previous_y,
      x2 = x,
      y2 = y,
      stroke = "secondary",
      stroke_width = 3
    })
    previous_x = x
    previous_y = y
  end

  table.insert(shapes, ui.line {
    x1 = x_release,
    y1 = baseline_y,
    x2 = 0.96,
    y2 = baseline_y,
    stroke = "outline",
    stroke_width = 2
  })

  return shapes
end

local channel_sections = {}
local shape_sections = {}

for _, channel in ipairs(nt.channels()) do
  local enabled = nt.channel_parameter(channel, "Enable")
  local shape = nt.channel_parameter(channel, "Shape")
  local trigger_mode = nt.channel_parameter(channel, "Trigger mode")
  local clock_mode = nt.channel_parameter(channel, "Clock mode")
  local clock_source = nt.channel_parameter(channel, "Clock source")
  local midi_divisor = nt.channel_parameter(channel, "MIDI divisor")
  local scale = nt.channel_parameter(channel, "Scale")
  local offset = nt.channel_parameter(channel, "Offset")
  local velocity_scale = nt.channel_parameter(channel, "Vel -> scale")
  local velocity_attack = nt.channel_parameter(channel, "Vel -> attack")

  if enabled ~= nil and shape ~= nil and trigger_mode ~= nil then
    local children = {
      ui.toggle {
        label = "Enabled",
        parameter = enabled.number
      },
      ui.slider {
        label = "Shape",
        parameter = shape.number
      },
      ui.choice {
        label = "Trigger mode",
        parameter = trigger_mode.number
      }
    }

    if clock_mode ~= nil then
      table.insert(children, ui.choice {
        label = "Clock mode",
        parameter = clock_mode.number
      })
      if clock_mode.value ~= 0 and clock_source ~= nil then
        table.insert(children, ui.choice {
          label = "Clock source",
          parameter = clock_source.number
        })
        if clock_source.value == 1 and midi_divisor ~= nil then
          table.insert(children, ui.choice {
            label = "MIDI divisor",
            parameter = midi_divisor.number
          })
        end
      end
    end
    if scale ~= nil then
      table.insert(children, ui.slider {
        label = "Scale",
        parameter = scale.number
      })
    end
    if offset ~= nil then
      table.insert(children, ui.slider {
        label = "Offset",
        parameter = offset.number
      })
    end
    if velocity_scale ~= nil then
      table.insert(children, ui.slider {
        label = "Velocity to scale",
        parameter = velocity_scale.number
      })
    end
    if velocity_attack ~= nil then
      table.insert(children, ui.slider {
        label = "Velocity to attack",
        parameter = velocity_attack.number
      })
    end

    table.insert(channel_sections, ui.section {
      title = "Envelope " .. channel,
      subtitle = "Shape " .. parameter_text(shape) .. " · " ..
        parameter_text(trigger_mode),
      children = children
    })
  end
end

local discovered_shapes = {}
for _, parameter in ipairs(algorithm.parameters) do
  local separator = string.find(parameter.name, ":")
  if separator ~= nil and string.sub(parameter.name, separator + 1) == "Delay" then
    local shape_number = tonumber(string.sub(parameter.name, 1, separator - 1))
    if shape_number ~= nil then discovered_shapes[shape_number] = true end
  end
end

local shape_numbers = {}
for shape_number, _ in pairs(discovered_shapes) do
  table.insert(shape_numbers, shape_number)
end
table.sort(shape_numbers)

for _, shape_number in ipairs(shape_numbers) do
  local delay = nt.channel_parameter(shape_number, "Delay")
  local attack = nt.channel_parameter(shape_number, "Attack")
  local hold = nt.channel_parameter(shape_number, "Hold")
  local decay = nt.channel_parameter(shape_number, "Decay")
  local sustain = nt.channel_parameter(shape_number, "Sustain")
  local release = nt.channel_parameter(shape_number, "Release")
  local attack_shape = nt.channel_parameter(shape_number, "Attack shape")
  local decay_shape = nt.channel_parameter(shape_number, "Decay shape")
  local range = nt.channel_parameter(shape_number, "Range")

  if delay ~= nil and attack ~= nil and hold ~= nil and decay ~= nil and
      sustain ~= nil and release ~= nil and attack_shape ~= nil and
      decay_shape ~= nil then
    local children = {
      ui.canvas {
        semantics_label = "Illustrative DAHDSR curve for shape " ..
          shape_number .. ": delay " .. parameter_text(delay) ..
          ", attack " .. parameter_text(attack) .. ", hold " ..
          parameter_text(hold) .. ", decay " .. parameter_text(decay) ..
          ", sustain " .. parameter_text(sustain) .. ", release " ..
          parameter_text(release) .. ", and range " .. parameter_text(range) ..
          ". This is not a live stage or output display.",
        aspect_ratio = 5.2,
        shapes = envelope_shapes(
          delay,
          attack,
          hold,
          decay,
          sustain,
          release,
          attack_shape,
          decay_shape
        )
      },
      ui.slider {
        label = "Delay",
        parameter = delay.number
      },
      ui.slider {
        label = "Attack",
        parameter = attack.number
      },
      ui.slider {
        label = "Hold",
        parameter = hold.number
      },
      ui.slider {
        label = "Decay",
        parameter = decay.number
      },
      ui.slider {
        label = "Sustain",
        parameter = sustain.number
      },
      ui.slider {
        label = "Release",
        parameter = release.number
      },
      ui.slider {
        label = "Attack shape",
        parameter = attack_shape.number
      },
      ui.slider {
        label = "Decay shape",
        parameter = decay_shape.number
      }
    }
    if range ~= nil then
      table.insert(children, ui.choice {
        label = "Range",
        parameter = range.number
      })
    end

    table.insert(shape_sections, ui.section {
      title = "Shape " .. shape_number,
      subtitle = "A " .. parameter_text(attack) ..
        " · D " .. parameter_text(decay) ..
        " · S " .. parameter_text(sustain) ..
        " · R " .. parameter_text(release),
      children = children
    })
  end
end

local root_children = {}
if #channel_sections > 0 then
  table.insert(root_children, ui.text {
    text = #channel_sections .. " envelopes use the shared shapes below.",
    style = "caption"
  })
  for _, section in ipairs(channel_sections) do
    table.insert(root_children, section)
  end
else
  table.insert(root_children, ui.text {
    text = "No envelope channels were found in this slot.",
    style = "body"
  })
end

if #shape_sections > 0 then
  table.insert(root_children, ui.divider {})
  table.insert(root_children, ui.text {
    text = "Shape controls are shared by every envelope assigned to that shape.",
    style = "caption"
  })
  for _, section in ipairs(shape_sections) do
    table.insert(root_children, section)
  end
else
  table.insert(root_children, ui.text {
    text = "No DAHDSR shapes were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Envelope (DAHDSR)",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
