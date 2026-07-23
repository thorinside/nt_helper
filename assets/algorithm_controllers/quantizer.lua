local note_names = {
  "C", "C sharp", "D", "D sharp", "E", "F",
  "F sharp", "G", "G sharp", "A", "A sharp", "B"
}

local function enum_label(parameter)
  if parameter == nil then return "" end
  local label = parameter.enum_values[parameter.value + 1]
  if label ~= nil and label ~= "" then return label end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function add_slider(children, label, parameter, enabled)
  if parameter == nil then return end
  table.insert(children, ui.slider {
    label = label,
    parameter = parameter.number,
    enabled = enabled == nil or enabled
  })
end

local function add_choice(children, label, parameter, enabled)
  if parameter == nil then return end
  table.insert(children, ui.choice {
    label = label,
    parameter = parameter.number,
    enabled = enabled == nil or enabled
  })
end

local function add_toggle(children, label, parameter, enabled)
  if parameter == nil then return end
  table.insert(children, ui.toggle {
    label = label,
    parameter = parameter.number,
    enabled = enabled == nil or enabled
  })
end

local quantize_mode = nt.parameter("Quantize mode")
local input_transpose = nt.parameter("Input transpose")
local shift = nt.parameter("Shift")
local key = nt.parameter("Key")
local scale = nt.parameter("Scale")
local mode = nt.parameter("Mode")
local output_transpose = nt.parameter("Output transpose")
local output_gate_mode = nt.parameter("Output gate mode")
local gate_offset = nt.parameter("Gate offset")

local pitch_children = {}
add_choice(pitch_children, "Quantize mode", quantize_mode)
add_slider(pitch_children, "Input transpose", input_transpose)
add_slider(pitch_children, "In-scale shift", shift)
add_slider(pitch_children, "Key", key)
add_choice(pitch_children, "Scale", scale)
add_slider(pitch_children, "Mode", mode)
add_slider(pitch_children, "Output transpose", output_transpose)
add_choice(pitch_children, "Output gate mode", output_gate_mode)
add_slider(pitch_children, "Gate offset", gate_offset)

local microtuning = nt.parameter("Microtuning")
local apply_mask = nt.parameter("Apply")
local scale_intervals = {
  [2] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
  [3] = { 0, 2, 4, 5, 7, 9, 11 },
  [4] = { 0, 2, 3, 5, 7, 8, 10 },
  [5] = { 0, 2, 3, 5, 7, 8, 11 },
  [6] = { 0, 2, 4, 5, 7, 9, 10 },
  [7] = { 0, 2, 3, 5, 6, 8, 9, 11 },
  [8] = { 0, 1, 3, 4, 6, 7, 9, 10 },
  [9] = { 0, 3, 4, 7, 8, 11 },
  [10] = { 0, 2, 4, 6, 8, 10 }
}

local function modulo(value, divisor)
  return ((value % divisor) + divisor) % divisor
end

local function mask_parameters()
  local page = nt.page("Mask")
  local parameters = {}
  if page == nil then return parameters end

  for _, parameter_number in ipairs(page.parameters) do
    local parameter = nt.parameter_by_number(parameter_number)
    if parameter ~= nil and not parameter.disabled and
        string.sub(parameter.name, 1, 5) == "Note " then
      table.insert(parameters, {
        degree = tonumber(string.sub(parameter.name, 6)) or 0,
        parameter = parameter
      })
    end
  end
  table.sort(parameters, function(left, right)
    return left.degree < right.degree
  end)
  return parameters
end

local mask_entries = mask_parameters()
local mask_notes = {}
local mask_layout = "degrees"
local intervals = scale ~= nil and scale_intervals[scale.value] or nil
local uses_builtin_twelve_degree_tuning =
  (microtuning == nil or microtuning.value == 0) and
  intervals ~= nil and
  #mask_entries == #intervals

if uses_builtin_twelve_degree_tuning then
  mask_layout = "piano"
  local mode_index = modulo((mode ~= nil and mode.value or 1) - 1, #intervals) + 1
  local mode_root = intervals[mode_index]
  local key_offset = key ~= nil and key.value or 0
  for index, entry in ipairs(mask_entries) do
    local interval_index = modulo(mode_index + index - 2, #intervals) + 1
    local pitch_class = modulo(
      key_offset + intervals[interval_index] - mode_root,
      12
    )
    table.insert(mask_notes, {
      label = note_names[pitch_class + 1],
      parameter = entry.parameter.number,
      pitch_class = pitch_class
    })
  end
else
  for _, entry in ipairs(mask_entries) do
    table.insert(mask_notes, {
      label = "Degree " .. entry.degree,
      parameter = entry.parameter.number
    })
  end
end

local mask_children = {}
if apply_mask ~= nil then
  table.insert(mask_children, ui.toggle {
    label = "Apply note mask",
    parameter = apply_mask.number
  })
end
if #mask_notes > 0 then
  table.insert(mask_children, ui.note_mask {
    label = "Quantizer note mask",
    layout = mask_layout,
    notes = mask_notes
  })
end

local microtuning_children = {}
add_choice(microtuning_children, "Microtuning", microtuning)
if microtuning ~= nil and microtuning.value == 1 then
  add_choice(microtuning_children, "Scala scale", nt.parameter("Scala .scl"))
  local scala_kbm = nt.parameter("Scala .kbm")
  add_slider(
    microtuning_children,
    "Scala keyboard map",
    scala_kbm
  )
  local scala_kbm_label = enum_label(scala_kbm)
  if scala_kbm_label == "Automatic" or scala_kbm_label == "automatic" then
    add_slider(
      microtuning_children,
      "Automatic keyboard-map root",
      nt.parameter("Auto kbm root")
    )
    add_slider(
      microtuning_children,
      "Automatic keyboard-map frequency",
      nt.parameter("Auto kbm Hz")
    )
  end
elseif microtuning ~= nil and microtuning.value == 2 then
  add_slider(microtuning_children, "MTS tuning", nt.parameter("MTS .syx"))
end

local pitch_bend_children = {}
local send_pitch_bend = nt.parameter("Send pitch bend")
add_toggle(pitch_bend_children, "Send pitch bend", send_pitch_bend)
add_slider(
  pitch_bend_children,
  "Pitch bend range",
  nt.parameter("Pitch bend range"),
  send_pitch_bend == nil or send_pitch_bend.value == 1
)

local root_children = {}
if #pitch_children > 0 then
  table.insert(root_children, ui.section {
    title = "Pitch selection",
    subtitle = scale ~= nil and enum_label(scale) or nil,
    children = pitch_children
  })
end
table.insert(root_children, ui.section {
  title = "Note mask",
  children = mask_children
})
if #microtuning_children > 0 then
  table.insert(root_children, ui.section {
    title = "Microtuning",
    subtitle = microtuning ~= nil and enum_label(microtuning) or nil,
    children = microtuning_children
  })
end
if #pitch_bend_children > 0 then
  table.insert(root_children, ui.section {
    title = "MIDI pitch bend",
    children = pitch_bend_children
  })
end

return {
  version = 1,
  title = "Quantizer",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
