local function parameter_text(parameter)
  if parameter == nil then return "Unavailable" end
  local enum = parameter.enum_values[parameter.value + 1]
  if enum ~= nil and enum ~= "" then return enum end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function normalized_value(parameter)
  if parameter == nil or parameter.maximum == parameter.minimum then return 0 end
  return (parameter.value - parameter.minimum) /
    (parameter.maximum - parameter.minimum)
end

local function bipolar_value(parameter)
  if parameter == nil then return 0 end
  local extent = math.max(math.abs(parameter.minimum), math.abs(parameter.maximum))
  if extent == 0 then return 0 end
  return parameter.value / extent
end

local function waveform_shapes(
    sine, triangle, saw, square, pulse_width, offset, asymmetry, random, phase)
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

  local sine_level = bipolar_value(sine)
  local triangle_level = bipolar_value(triangle)
  local saw_level = bipolar_value(saw)
  local square_level = bipolar_value(square)
  local random_level = bipolar_value(random)
  local offset_level = bipolar_value(offset)
  local width = pulse_width ~= nil and normalized_value(pulse_width) or 0.5
  local asymmetry_amount = asymmetry ~= nil and bipolar_value(asymmetry) or 0
  local phase_turns = phase ~= nil and phase.value / 360 or 0
  local split = 0.5 + asymmetry_amount * 0.45
  local random_steps = { -0.52, 0.74, -0.16, 0.38, -0.81, 0.12, 0.63, -0.31 }

  local function warp_cycle(cycle)
    if cycle < split then return (cycle / split) * 0.5 end
    return 0.5 + ((cycle - split) / (1 - split)) * 0.5
  end

  local previous = nil
  for sample = 0, 48 do
    local cycle = (sample / 48 + phase_turns) % 1
    local warped = warp_cycle(cycle)
    local sine_value = math.sin(warped * math.pi * 2)
    local triangle_value = 1 - 4 * math.abs(warped - 0.5)
    local saw_value = warped * 2 - 1
    local square_value = warped < width and 1 or -1
    local random_index = math.floor(warped * #random_steps) + 1
    if random_index > #random_steps then random_index = #random_steps end

    local output = offset_level +
      sine_level * sine_value +
      triangle_level * triangle_value +
      saw_level * saw_value +
      square_level * square_value +
      random_level * random_steps[random_index]
    local range = math.max(
      1,
      math.abs(offset_level) + math.abs(sine_level) +
        math.abs(triangle_level) + math.abs(saw_level) +
        math.abs(square_level) + math.abs(random_level)
    )
    local point = {
      x = 0.04 + (sample / 48) * 0.92,
      y = math.max(0.08, math.min(0.92, 0.5 - (output / range) * 0.4))
    }
    if previous ~= nil then
      table.insert(shapes, ui.line {
        x1 = previous.x,
        y1 = previous.y,
        x2 = point.x,
        y2 = point.y,
        stroke = "primary",
        stroke_width = 3
      })
    end
    previous = point
  end

  return shapes
end

local quality = nt.parameter("Quality")
local root_children = {}

if quality ~= nil then
  table.insert(root_children, ui.section {
    title = "Output quality",
    subtitle = parameter_text(quality),
    children = {
      ui.choice {
        label = "Quality",
        parameter = quality.number
      }
    }
  })
end

local channel_sections = {}
for _, channel in ipairs(nt.channels()) do
  local enabled = nt.channel_parameter(channel, "Enable")
  local speed = nt.channel_parameter(channel, "Speed")
  local multiplier = nt.channel_parameter(channel, "Multiplier")
  local sine = nt.channel_parameter(channel, "Sine")
  local triangle = nt.channel_parameter(channel, "Triangle")
  local saw = nt.channel_parameter(channel, "Saw")
  local square = nt.channel_parameter(channel, "Square")
  local pulse_width = nt.channel_parameter(channel, "Pulse width")
  local offset = nt.channel_parameter(channel, "Offset")
  local asymmetry = nt.channel_parameter(channel, "Asymmetry")
  local random = nt.channel_parameter(channel, "Random")
  local phase = nt.channel_parameter(channel, "Phase")
  local sync = nt.channel_parameter(channel, "Sync")
  local clock_multiplier = nt.channel_parameter(channel, "Clock multiplier")
  local midi_divisor = nt.channel_parameter(channel, "MIDI divisor")

  if speed ~= nil and sine ~= nil and triangle ~= nil and
      saw ~= nil and square ~= nil and offset ~= nil then
    local children = {}

    if enabled ~= nil then
      table.insert(children, ui.toggle {
        label = "Enabled",
        parameter = enabled.number
      })
    end

    table.insert(children, ui.canvas {
      semantics_label = "Illustrative channel " .. channel ..
        " composite waveform preview from the current sine " ..
        parameter_text(sine) .. ", triangle " .. parameter_text(triangle) ..
        ", saw " .. parameter_text(saw) .. ", square " ..
        parameter_text(square) .. ", random " .. parameter_text(random) ..
        ", and offset " .. parameter_text(offset) ..
        ". This is not live phase or output.",
      aspect_ratio = 5.2,
      shapes = waveform_shapes(
        sine,
        triangle,
        saw,
        square,
        pulse_width,
        offset,
        asymmetry,
        random,
        phase
      )
    })
    table.insert(children, ui.slider {
      label = "Speed",
      parameter = speed.number,
      enabled = sync == nil or sync.value == 0
    })
    if multiplier ~= nil then
      table.insert(children, ui.choice {
        label = "Multiplier",
        parameter = multiplier.number,
        enabled = sync == nil or sync.value == 0
      })
    end
    table.insert(children, ui.slider {
      label = "Sine",
      parameter = sine.number
    })
    table.insert(children, ui.slider {
      label = "Triangle",
      parameter = triangle.number
    })
    table.insert(children, ui.slider {
      label = "Saw",
      parameter = saw.number
    })
    table.insert(children, ui.slider {
      label = "Square",
      parameter = square.number
    })
    if pulse_width ~= nil then
      table.insert(children, ui.slider {
        label = "Pulse width",
        parameter = pulse_width.number
      })
    end
    table.insert(children, ui.slider {
      label = "Offset",
      parameter = offset.number
    })
    if asymmetry ~= nil then
      table.insert(children, ui.slider {
        label = "Asymmetry",
        parameter = asymmetry.number
      })
    end
    if random ~= nil then
      table.insert(children, ui.slider {
        label = "Random",
        parameter = random.number
      })
    end
    if phase ~= nil then
      table.insert(children, ui.slider {
        label = "Phase",
        parameter = phase.number
      })
    end
    if sync ~= nil then
      table.insert(children, ui.choice {
        label = "Sync",
        parameter = sync.number
      })
      if (sync.value == 1 or sync.value == 2 or sync.value == 5) and
          clock_multiplier ~= nil then
        table.insert(children, ui.choice {
          label = "Clock multiplier",
          parameter = clock_multiplier.number
        })
      elseif (sync.value == 3 or sync.value == 4) and midi_divisor ~= nil then
        table.insert(children, ui.choice {
          label = "MIDI divisor",
          parameter = midi_divisor.number
        })
      end
    end

    table.insert(channel_sections, ui.section {
      title = "Channel " .. channel,
      subtitle = parameter_text(speed) .. " · " ..
        parameter_text(multiplier) .. " · " .. parameter_text(sync),
      children = children
    })
  end
end

if #channel_sections == 0 then
  table.insert(root_children, ui.text {
    text = "No LFO channels were found in this slot.",
    style = "body"
  })
else
  for _, section in ipairs(channel_sections) do
    table.insert(root_children, section)
  end
end

return {
  version = 1,
  title = "LFO",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
