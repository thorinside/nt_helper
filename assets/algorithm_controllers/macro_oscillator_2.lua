local function display_value(parameter)
  if parameter == nil then return "" end
  if parameter.display_value ~= nil and parameter.display_value ~= "" then
    return parameter.display_value
  end
  local enum = parameter.enum_values[parameter.value + 1]
  if enum ~= nil and enum ~= "" then return enum end
  return tostring(parameter.value)
end

-- The monophonic and polyphonic Plaits algorithms use different parameter
-- numbers. Name lookup keeps this controller tied to the immutable algorithm
-- snapshot rather than either layout.
local model = nt.parameter("Model")
local harmonics = nt.parameter("Harmonics")
local timbre = nt.parameter("Timbre")
local morph = nt.parameter("Morph")
local coarse_tune = nt.parameter("Coarse tune")
local fine_tune = nt.parameter("Fine tune")
local fm = nt.parameter("FM")
local timbre_mod = nt.parameter("Timbre mod")
local morph_mod = nt.parameter("Morph mod")
local low_pass_gate = nt.parameter("Low-pass gate")
local time_decay = nt.parameter("Time/decay")

local root_children = {}

if model ~= nil then
  table.insert(root_children, ui.section {
    title = "Engine",
    subtitle = display_value(model),
    children = {
      ui.slider {
        label = "Model",
        parameter = model.number
      }
    }
  })
end

local tone_children = {}
if harmonics ~= nil then
  table.insert(tone_children, ui.slider {
    label = "Harmonics",
    parameter = harmonics.number
  })
end
if timbre ~= nil and morph ~= nil then
  table.insert(tone_children, ui.xy_pad {
    label = "Timbre and morph",
    x_label = "Timbre",
    y_label = "Morph",
    x_parameter = timbre.number,
    y_parameter = morph.number,
    aspect_ratio = 1
  })
elseif timbre ~= nil then
  table.insert(tone_children, ui.slider {
    label = "Timbre",
    parameter = timbre.number
  })
elseif morph ~= nil then
  table.insert(tone_children, ui.slider {
    label = "Morph",
    parameter = morph.number
  })
end
if #tone_children > 0 then
  local tone_summary = {}
  if harmonics ~= nil then
    table.insert(tone_summary, "harmonics " .. display_value(harmonics))
  end
  if timbre ~= nil then
    table.insert(tone_summary, "timbre " .. display_value(timbre))
  end
  if morph ~= nil then
    table.insert(tone_summary, "morph " .. display_value(morph))
  end
  table.insert(root_children, ui.section {
    title = "Tone",
    subtitle = table.concat(tone_summary, " · "),
    children = tone_children
  })
end

local voice_children = {}
for _, item in ipairs({
  { parameter = coarse_tune, label = "Coarse tune" },
  { parameter = fine_tune, label = "Fine tune" },
  { parameter = low_pass_gate, label = "Low-pass gate" },
  { parameter = time_decay, label = "Time/decay" }
}) do
  if item.parameter ~= nil then
    table.insert(voice_children, ui.slider {
      label = item.label,
      parameter = item.parameter.number
    })
  end
end
if #voice_children > 0 then
  table.insert(root_children, ui.section {
    title = "Voice",
    subtitle = "Tuning and internal envelope",
    children = voice_children
  })
end

local modulation_children = {}
for _, item in ipairs({
  { parameter = fm, label = "FM depth" },
  { parameter = timbre_mod, label = "Timbre modulation" },
  { parameter = morph_mod, label = "Morph modulation" }
}) do
  if item.parameter ~= nil then
    table.insert(modulation_children, ui.slider {
      label = item.label,
      parameter = item.parameter.number
    })
  end
end
if #modulation_children > 0 then
  table.insert(root_children, ui.section {
    title = "Modulation depth",
    subtitle = "Response to assigned modulation inputs",
    children = modulation_children
  })
end

if #root_children == 0 then
  table.insert(root_children, ui.text {
    text = "No Plaits synthesis controls were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Macro Oscillator 2",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
