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

local function greatest_common_divisor(left, right)
  left = math.abs(math.floor(left))
  right = math.abs(math.floor(right))
  while right ~= 0 do
    local remainder = left % right
    left = right
    right = remainder
  end
  return math.max(1, left)
end

local function reduced_ratio(numerator, denominator)
  local divisor = greatest_common_divisor(numerator, denominator)
  return tostring(math.floor(numerator / divisor)) .. "/" ..
    tostring(math.floor(denominator / divisor))
end

local function format_frequency(frequency)
  if frequency == nil then return "Frequency unavailable" end
  return string.format("%.2f Hz", frequency)
end

local fundamental = nt.parameter("Fundamental")
local octave = nt.parameter("Octave")
local transpose = nt.parameter("Transpose")
local configured_fundamental = nil
if fundamental ~= nil then
  configured_fundamental =
    fundamental.value * (10 ^ (fundamental.power_of_ten or 0))
  if octave ~= nil then
    configured_fundamental = configured_fundamental * (2 ^ octave.value)
  end
  if transpose ~= nil then
    configured_fundamental =
      configured_fundamental * (2 ^ (transpose.value / 12))
  end
end

local denominator = nt.parameter("Denominator")
local tones = {}
for tone = 0, 4 do
  local numerator = tone == 0 and nil or nt.parameter("Numerator " .. tone)
  local gate = nt.parameter("Gate " .. tone)
  local gain = nt.parameter("Gain " .. tone)
  if gate ~= nil and gain ~= nil and
      (tone == 0 or numerator ~= nil) and denominator ~= nil then
    local ratio = tone == 0 and 1 or numerator.value / denominator.value
    local frequency = nil
    if configured_fundamental ~= nil then
      frequency = configured_fundamental * ratio
    end
    table.insert(tones, {
      number = tone,
      numerator = numerator,
      gate = gate,
      gain = gain,
      pan = tone == 0 and nil or nt.parameter("Pan " .. tone),
      ratio_text = tone == 0 and "1/1" or
        reduced_ratio(numerator.value, denominator.value),
      frequency = frequency
    })
  end
end

local function tone_name(tone)
  return tone.number == 0 and "Fundamental" or "Tone " .. tone.number
end

local function gate_state(tone)
  return tone.gate.value == 0 and "Off" or "On"
end

local function tone_summary(tone)
  return format_frequency(tone.frequency) .. " · " .. tone.ratio_text ..
    " · Gate " .. gate_state(tone)
end

local root_children = {}
if #tones > 0 then
  local voice_readouts = {}
  for _, tone in ipairs(tones) do
    table.insert(voice_readouts, ui.text {
      text = tone_name(tone) .. "\n" ..
        format_frequency(tone.frequency) .. "\n" ..
        tone.ratio_text .. "\n" ..
        "Gate " .. gate_state(tone),
      style = "caption",
      align = "center"
    })
  end
  table.insert(root_children, ui.row {
    gap = 20,
    children = voice_readouts
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
  table.insert(root_children, ui.section {
    title = "Tuning",
    subtitle = configured_fundamental ~= nil and
      format_frequency(configured_fundamental) or nil,
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

  table.insert(root_children, ui.section {
    title = tone_name(tone),
    subtitle = tone_summary(tone),
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
