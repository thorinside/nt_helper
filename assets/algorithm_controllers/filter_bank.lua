local function display_value(parameter)
  if parameter == nil then return "" end
  if parameter.display_value ~= nil and parameter.display_value ~= "" then
    return parameter.display_value
  end
  local enum = parameter.enum_values[parameter.value + 1]
  if enum ~= nil and enum ~= "" then return enum end

  local value = parameter.value
  local decimals = 0
  if parameter.power_of_ten ~= nil and parameter.power_of_ten < 0 then
    decimals = -parameter.power_of_ten
    value = value * (10 ^ parameter.power_of_ten)
  end
  local text = decimals > 0 and
    string.format("%." .. decimals .. "f", value) or tostring(value)
  if parameter.unit ~= nil and parameter.unit ~= "" then
    return text .. " " .. parameter.unit
  end
  return text
end

local filters = {}
for _, channel in ipairs(nt.channels()) do
  local pitch = nt.channel_parameter(channel, "Pitch")
  local gate = nt.channel_parameter(channel, "Gate")
  local gain = nt.channel_parameter(channel, "Gain")
  if pitch ~= nil and gate ~= nil and gain ~= nil then
    table.insert(filters, {
      number = channel,
      pitch = pitch,
      gate = gate,
      gain = gain
    })
  end
end

local function bank_shapes()
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
      y1 = 0.86,
      x2 = 0.96,
      y2 = 0.86,
      stroke = "outline"
    },
    ui.line {
      x1 = 0.04,
      y1 = 0.52,
      x2 = 0.96,
      y2 = 0.52,
      stroke = "outline"
    }
  }

  for index, filter in ipairs(filters) do
    local x = #filters == 1 and 0.5 or
      0.06 + ((index - 1) / (#filters - 1)) * 0.88
    local pitch_position = math.max(
      0,
      math.min(1, (filter.pitch.value - filter.pitch.minimum) /
        math.max(1, filter.pitch.maximum - filter.pitch.minimum))
    )
    local y = 0.84 - pitch_position * 0.66
    local gain_position = math.max(
      0,
      math.min(1, (filter.gain.value - filter.gain.minimum) /
        math.max(1, filter.gain.maximum - filter.gain.minimum))
    )
    local active = filter.gate.value ~= 0

    table.insert(shapes, ui.line {
      x1 = x,
      y1 = 0.86,
      x2 = x,
      y2 = y,
      stroke = active and "primary" or "outline",
      stroke_width = active and 3 or 1
    })
    table.insert(shapes, ui.circle {
      x = x,
      y = y,
      radius = 0.022 + gain_position * 0.024,
      fill = active and "primary" or "surface",
      stroke = active and "primary" or "secondary",
      stroke_width = active and 2 or 1
    })
  end
  return shapes
end

local function bank_semantics()
  local descriptions = {}
  for _, filter in ipairs(filters) do
    table.insert(
      descriptions,
      "filter " .. filter.number .. " pitch " .. display_value(filter.pitch) ..
        ", gain " .. display_value(filter.gain) .. ", gate " ..
        (filter.gate.value ~= 0 and "on" or "off")
    )
  end
  return "Illustrative configured filter bank: " ..
    table.concat(descriptions, "; ") ..
    ". Vertical position represents configured pitch, circle size represents " ..
    "configured gain, and filled circles have their gate enabled; this is " ..
    "not a live envelope or audio-level display."
end

local root_children = {}
local mode = nt.parameter("Mode")
local globals = {}
for _, entry in ipairs({
  { "Width", "slider" },
  { "Mode", "choice" },
  { "Resonance/Q", "slider" },
  { "Attack time", "slider" },
  { "Release time", "slider" },
  { "Gain", "slider" }
}) do
  local parameter = nt.parameter(entry[1])
  if parameter ~= nil then
    table.insert(
      globals,
      entry[2] == "choice" and ui.choice {
        label = entry[1],
        parameter = parameter.number
      } or ui.slider {
        label = entry[1],
        parameter = parameter.number
      }
    )
  end
end
if #globals > 0 then
  table.insert(root_children, ui.section {
    title = "Filter bank",
    subtitle = #filters .. " filters" ..
      (mode ~= nil and " · " .. display_value(mode) or ""),
    children = globals
  })
end

if #filters > 0 then
  table.insert(root_children, ui.canvas {
    semantics_label = bank_semantics(),
    aspect_ratio = 5.5,
    shapes = bank_shapes()
  })
end

local performance_children = {}
for _, entry in ipairs({
  { "Controlled voices", "slider" },
  { "Transpose", "slider" },
  { "Fine tune", "slider" },
  { "Sustain", "toggle" },
  { "Sustain mode", "choice" },
  { "Bend range", "slider" },
  { "Unison", "slider" },
  { "Unison detune", "slider" }
}) do
  local parameter = nt.parameter(entry[1])
  if parameter ~= nil then
    local node = ui.slider {
      label = entry[1],
      parameter = parameter.number
    }
    if entry[2] == "toggle" then
      node = ui.toggle {
        label = entry[1],
        parameter = parameter.number
      }
    elseif entry[2] == "choice" then
      node = ui.choice {
        label = entry[1],
        parameter = parameter.number
      }
    end
    table.insert(performance_children, node)
  end
end
if #performance_children > 0 then
  local voices = nt.parameter("Controlled voices")
  local unison = nt.parameter("Unison")
  local subtitle = voices ~= nil and
    display_value(voices) .. " controlled voices" or nil
  if subtitle ~= nil and unison ~= nil and unison.value > 1 then
    subtitle = subtitle .. " · unison " .. display_value(unison)
  end
  table.insert(root_children, ui.section {
    title = "Performance",
    subtitle = subtitle,
    children = performance_children
  })
end

for _, filter in ipairs(filters) do
  local children = {
    ui.slider {
      label = "Pitch",
      parameter = filter.pitch.number
    },
    ui.toggle {
      label = "Gate",
      parameter = filter.gate.number
    },
    ui.slider {
      label = "Gain",
      parameter = filter.gain.number
    },
    ui.row {
      gap = 8,
      children = {
        ui.button {
          label = "12 notes down",
          style = "outlined",
          enabled = filter.pitch.value >= filter.pitch.minimum + 12,
          action = {
            type = "adjust_parameter",
            parameter = filter.pitch.number,
            delta = -12
          }
        },
        ui.button {
          label = "12 notes up",
          style = "outlined",
          enabled = filter.pitch.value <= filter.pitch.maximum - 12,
          action = {
            type = "adjust_parameter",
            parameter = filter.pitch.number,
            delta = 12
          }
        }
      }
    }
  }
  table.insert(root_children, ui.section {
    title = "Filter " .. filter.number,
    subtitle = display_value(filter.pitch) .. " · " ..
      display_value(filter.gain) .. " · gate " ..
      (filter.gate.value ~= 0 and "on" or "off"),
    children = children
  })
end

if #filters == 0 then
  table.insert(root_children, ui.text {
    text = "No filter-bank voices were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Filter Bank",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
