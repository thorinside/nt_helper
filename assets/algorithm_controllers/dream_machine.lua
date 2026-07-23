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

local denominator = nt.parameter("Denominator")
local tones = {}
for tone = 0, 4 do
  local numerator = tone == 0 and nil or nt.parameter("Numerator " .. tone)
  local gate = nt.parameter("Gate " .. tone)
  local gain = nt.parameter("Gain " .. tone)
  if gate ~= nil and gain ~= nil and
      (tone == 0 or numerator ~= nil) and denominator ~= nil then
    table.insert(tones, {
      number = tone,
      numerator = numerator,
      gate = gate,
      gain = gain,
      pan = tone == 0 and nil or nt.parameter("Pan " .. tone),
      ratio = tone == 0 and 1 or numerator.value / denominator.value
    })
  end
end

local function ratio_shapes()
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
      y1 = 0.86,
      x2 = 0.94,
      y2 = 0.86,
      stroke = "outline"
    }
  }

  local minimum_log = nil
  local maximum_log = nil
  for _, tone in ipairs(tones) do
    local log_ratio = math.log(math.max(0.000001, tone.ratio))
    tone.log_ratio = log_ratio
    minimum_log = minimum_log == nil and log_ratio or
      math.min(minimum_log, log_ratio)
    maximum_log = maximum_log == nil and log_ratio or
      math.max(maximum_log, log_ratio)
  end
  local span = math.max(0.000001, maximum_log - minimum_log)

  for index, tone in ipairs(tones) do
    local x = #tones == 1 and 0.5 or
      0.08 + ((index - 1) / (#tones - 1)) * 0.84
    local ratio_position = (tone.log_ratio - minimum_log) / span
    if maximum_log == minimum_log then ratio_position = 0.5 end
    local y = 0.76 - ratio_position * 0.56
    local gain_range = math.max(1, tone.gain.maximum - tone.gain.minimum)
    local gain_position = math.max(
      0,
      math.min(1, (tone.gain.value - tone.gain.minimum) / gain_range)
    )
    local active = tone.gate.value ~= 0

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
      radius = 0.025 + gain_position * 0.026,
      fill = active and "primary" or "surface",
      stroke = active and "primary" or "outline",
      stroke_width = active and 2 or 1
    })
  end
  return shapes
end

local function ratio_semantics()
  local descriptions = {}
  for _, tone in ipairs(tones) do
    local ratio = tone.number == 0 and "1 to 1" or
      display_value(tone.numerator) .. " to " .. display_value(denominator)
    table.insert(
      descriptions,
      (tone.number == 0 and "fundamental" or "tone " .. tone.number) ..
        " ratio " .. ratio .. ", gain " .. display_value(tone.gain) ..
        ", gate " .. display_value(tone.gate)
    )
  end
  return "Illustrative configured frequency-ratio map: " ..
    table.concat(descriptions, "; ") ..
    ". Vertical position represents relative pitch, circle size represents " ..
    "configured gain, and filled circles have their gate enabled; this is " ..
    "not live phase or audio."
end

local root_children = {}
if #tones > 0 then
  table.insert(root_children, ui.canvas {
    semantics_label = ratio_semantics(),
    aspect_ratio = 5.5,
    shapes = ratio_shapes()
  })
end

local wavetable = nt.parameter("Wavetable")
local waveform = nt.parameter("Waveform 0")
local wave_offset = nt.parameter("Wave offset")
local wavetable_children = {}
if wavetable ~= nil then
  table.insert(wavetable_children, ui.slider {
    label = "Wavetable",
    parameter = wavetable.number
  })
end
if waveform ~= nil then
  table.insert(wavetable_children, ui.choice {
    label = "Fundamental wave",
    parameter = waveform.number
  })
end
if wave_offset ~= nil then
  table.insert(wavetable_children, ui.slider {
    label = "Wave offset",
    parameter = wave_offset.number
  })
end
if #wavetable_children > 0 then
  table.insert(root_children, ui.section {
    title = "Wavetable",
    subtitle = wavetable ~= nil and display_value(wavetable) or nil,
    children = wavetable_children
  })
end

local tuning_children = {}
for _, name in ipairs({ "Fundamental", "Octave", "Transpose", "Denominator" }) do
  local parameter = nt.parameter(name)
  if parameter ~= nil then
    table.insert(tuning_children, ui.slider {
      label = name,
      parameter = parameter.number
    })
  end
end
for prime = 1, 4 do
  local parameter = nt.parameter("Prime " .. prime)
  if parameter ~= nil then
    table.insert(tuning_children, ui.slider {
      label = "Prime " .. prime,
      parameter = parameter.number
    })
  end
end
if #tuning_children > 0 then
  local fundamental = nt.parameter("Fundamental")
  local octave = nt.parameter("Octave")
  table.insert(root_children, ui.section {
    title = "Tuning",
    subtitle = fundamental ~= nil and
      (display_value(fundamental) ..
        (octave ~= nil and " · octave " .. display_value(octave) or "")) or nil,
    children = tuning_children
  })
end

for _, tone in ipairs(tones) do
  local children = {}
  if tone.numerator ~= nil then
    table.insert(children, ui.slider {
      label = "Numerator",
      parameter = tone.numerator.number
    })
  end
  table.insert(children, ui.toggle {
    label = "Gate",
    parameter = tone.gate.number
  })
  table.insert(children, ui.slider {
    label = "Gain",
    parameter = tone.gain.number
  })
  if tone.pan ~= nil then
    table.insert(children, ui.slider {
      label = "Pan",
      parameter = tone.pan.number
    })
  end

  local ratio = tone.number == 0 and "1/1" or
    display_value(tone.numerator) .. "/" .. display_value(denominator)
  local state = "gate " .. display_value(tone.gate)
  table.insert(root_children, ui.section {
    title = tone.number == 0 and "Fundamental" or "Tone " .. tone.number,
    subtitle = ratio .. " · " .. display_value(tone.gain) .. " · " .. state,
    children = children
  })
end

local response_children = {}
for _, name in ipairs({
  "Attack time",
  "Decay time",
  "Frequency slew",
  "Crossfade time"
}) do
  local parameter = nt.parameter(name)
  if parameter ~= nil then
    table.insert(response_children, ui.slider {
      label = name,
      parameter = parameter.number
    })
  end
end
local fm_range = nt.parameter("FM Range")
if fm_range ~= nil then
  table.insert(response_children, ui.choice {
    label = "FM range",
    parameter = fm_range.number
  })
end
if #response_children > 0 then
  table.insert(root_children, ui.section {
    title = "Response",
    subtitle = fm_range ~= nil and display_value(fm_range) or nil,
    children = response_children
  })
end

if #tones == 0 then
  table.insert(root_children, ui.text {
    text = "Dream Machine tone controls are unavailable in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Dream Machine",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
