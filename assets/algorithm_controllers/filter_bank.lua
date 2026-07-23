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

local mode = nt.parameter("Mode")
local resonance = nt.parameter("Resonance/Q")
local microtuning = nt.parameter("Microtuning")

local plot_left = 0.06
local plot_right = 0.94
local plot_top = 0.10
local plot_bottom = 0.90
local plot_width = plot_right - plot_left
local plot_height = plot_bottom - plot_top
local gain_minimum_db = -40
local gain_maximum_db = 24

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

local function engineering_value(parameter)
  return parameter.value * (10 ^ (parameter.power_of_ten or 0))
end

local function nominal_frequency(note)
  return 440 * (2 ^ ((note - 69) / 12))
end

local minimum_frequency = nominal_frequency(0)
local maximum_frequency = nominal_frequency(127)

local function frequency_x_from_hz(frequency)
  local position = math.log(frequency / minimum_frequency) /
    math.log(maximum_frequency / minimum_frequency)
  return plot_left + clamp(position, 0, 1) * plot_width
end

local function pitch_x(pitch)
  return frequency_x_from_hz(nominal_frequency(pitch.value))
end

local function gain_y(gain)
  local gain_db = clamp(
    engineering_value(gain),
    gain_minimum_db,
    gain_maximum_db
  )
  local position = (gain_maximum_db - gain_db) /
    (gain_maximum_db - gain_minimum_db)
  return plot_top + position * plot_height
end

local function frequency_text(frequency)
  if frequency >= 1000 then
    return string.format("%.2f kilohertz", frequency / 1000)
  end
  return string.format("%.2f hertz", frequency)
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
      x1 = plot_left,
      y1 = gain_y({ value = 0, power_of_ten = 0 }),
      x2 = plot_right,
      y2 = gain_y({ value = 0, power_of_ten = 0 }),
      stroke = "outline"
    }
  }

  for _, frequency in ipairs({ 10, 100, 1000, 10000 }) do
    local x = frequency_x_from_hz(frequency)
    table.insert(shapes, ui.line {
      x1 = x,
      y1 = plot_top,
      x2 = x,
      y2 = plot_bottom,
      stroke = "outline"
    })
  end

  local zero_db_y = gain_y({ value = 0, power_of_ten = 0 })
  local multiband = mode ~= nil and mode.value == 2
  for _, filter in ipairs(filters) do
    local x = pitch_x(filter.pitch)
    local y = gain_y(filter.gain)
    local active = filter.gate.value ~= 0

    table.insert(shapes, ui.line {
      x1 = x,
      y1 = multiband and plot_top or zero_db_y,
      x2 = x,
      y2 = multiband and plot_bottom or y,
      stroke = active and "primary" or "outline",
      stroke_width = active and 2 or 1
    })
    table.insert(shapes, ui.circle {
      x = x,
      y = y,
      radius = 0.026,
      fill = active and "primary" or "surface",
      stroke = active and "primary" or "secondary",
      stroke_width = active and 2 or 1
    })
  end
  return shapes
end

local function bank_semantics()
  local descriptions = {}
  local tuned = microtuning ~= nil and microtuning.value ~= 0
  for _, filter in ipairs(filters) do
    local frequency = tuned and "" or
      ", nominal " .. frequency_text(nominal_frequency(filter.pitch.value))
    table.insert(
      descriptions,
      "filter " .. filter.number .. " pitch " .. display_value(filter.pitch) ..
        frequency .. ", gain " .. display_value(filter.gain) ..
        ", Gate parameter " .. (filter.gate.value ~= 0 and "on" or "off")
    )
  end

  local axis_description
  if tuned then
    axis_description =
      "Horizontal positions show stored MIDI pitch on an equal-temperament " ..
      "logarithmic-frequency reference axis. " .. display_value(microtuning) ..
      " microtuning is active, so actual frequencies are unavailable from " ..
      "this slot snapshot. "
  else
    axis_description =
      "The horizontal axis is nominal equal-tempered frequency on a " ..
      "logarithmic scale, from MIDI note 0 at 8.18 hertz to MIDI note 127 " ..
      "at 12.54 kilohertz. "
  end

  local mode_description
  if mode ~= nil and mode.value == 2 then
    mode_description =
      "Vertical lines mark configured Multiband crossover pitches and dots " ..
      "mark their per-filter gains. "
  else
    mode_description =
      "Each stem and dot is an independent configured filter. "
  end

  local resonance_description = ""
  if resonance ~= nil then
    if mode ~= nil and mode.value == 0 then
      resonance_description =
        "The global Resonance/Q control acts as resonator gain and is " ..
        display_value(resonance) ..
        "; it is not included in the dot positions, and bandwidth is not " ..
        "available from the algorithm metadata. "
    else
      resonance_description =
        "The global resonance control is " .. display_value(resonance) ..
        "; bandwidth is not available from the algorithm metadata. "
    end
  end

  return "Configured Filter Bank, " ..
    (mode ~= nil and display_value(mode) .. " mode. " or "") ..
    axis_description ..
    "The vertical axis is configured per-filter gain from minus 40 to plus " ..
    "24 decibels; overall gain is excluded. " ..
    mode_description ..
    table.concat(descriptions, "; ") .. ". " ..
    resonance_description ..
    "Filled dots mean the configured Gate parameter is on. These markers " ..
    "are not a summed response, measured audio, or live envelope levels."
end

local function bank_caption()
  local tuning_text
  if microtuning ~= nil and microtuning.value ~= 0 then
    tuning_text =
      "MIDI pitch on an equal-temperament log-frequency reference " ..
      "(actual tuned Hz unavailable)"
  else
    tuning_text = "Nominal log frequency 8.18 Hz to 12.54 kHz"
  end

  if mode ~= nil and mode.value == 2 then
    return tuning_text ..
      " · crossover lines with per-filter gain dots (-40 to +24 dB) · " ..
      "configured values, not a response curve"
  end
  return tuning_text ..
    " · independent per-filter gain (-40 to +24 dB) · configured values, " ..
    "not a response curve"
end

local root_children = {}
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
    aspect_ratio = 4.8,
    shapes = bank_shapes()
  })
  table.insert(root_children, ui.text {
    text = bank_caption(),
    style = "caption",
    align = "center"
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
