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

local apply_mask = nt.parameter("Apply")
local mask_groups = {}
local included_count = 0
local available_count = 0

for group = 0, 10 do
  local buttons = {}
  local first_note = group * 12
  local last_note = math.min(127, first_note + 11)

  for midi_note = first_note, last_note do
    local parameter_index = midi_note + 1
    local parameter = nt.parameter("Note " .. parameter_index)
    if parameter ~= nil then
      available_count = available_count + 1
      if parameter.value == 1 then included_count = included_count + 1 end

      local pitch_name = note_names[(midi_note % 12) + 1] ..
        tostring(math.floor(midi_note / 12) - 1)
      table.insert(buttons, ui.button {
        label = pitch_name .. (parameter.value == 1 and " on" or " off"),
        style = parameter.value == 1 and "filled" or "outlined",
        action = {
          type = "set_parameter",
          parameter = parameter.number,
          value = parameter.value == 1 and 0 or 1
        }
      })
    end
  end

  if #buttons > 0 then
    table.insert(mask_groups, ui.section {
      title = "Mask " .. (first_note + 1) .. "–" .. (last_note + 1),
      subtitle = note_names[(first_note % 12) + 1] ..
        tostring(math.floor(first_note / 12) - 1) .. " through " ..
        note_names[(last_note % 12) + 1] ..
        tostring(math.floor(last_note / 12) - 1) .. " in 12-degree tuning",
      children = {
        ui.row {
          gap = 8,
          children = buttons
        }
      }
    })
  end
end

local mask_children = {
  ui.text {
    text = "Pitch names are a 12-degree reference. With other tunings, these controls address tuning degrees directly.",
    style = "caption"
  }
}
if apply_mask ~= nil then
  table.insert(mask_children, ui.toggle {
    label = "Apply note mask",
    parameter = apply_mask.number
  })
end
if available_count > 0 then
  table.insert(mask_children, ui.text {
    text = included_count .. " of " .. available_count ..
      " available mask entries are included.",
    style = "caption"
  })
  for _, group in ipairs(mask_groups) do
    table.insert(mask_children, group)
  end
else
  table.insert(mask_children, ui.text {
    text = "No note-mask parameters were found in this slot.",
    style = "body"
  })
end

local microtuning = nt.parameter("Microtuning")
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

local midi_children = {}
add_slider(midi_children, "MIDI channel in", nt.parameter("MIDI channel (in)"))
add_toggle(
  midi_children,
  "Output to breakout",
  nt.parameter("Output to breakout")
)
add_toggle(
  midi_children,
  "Output to Select Bus",
  nt.parameter("Output to Select Bus")
)
add_toggle(midi_children, "Output to USB", nt.parameter("Output to USB"))
add_toggle(
  midi_children,
  "Output to internal algorithms",
  nt.parameter("Output to internal")
)
local send_pitch_bend = nt.parameter("Send pitch bend")
add_toggle(midi_children, "Send pitch bend", send_pitch_bend)
add_slider(
  midi_children,
  "Pitch bend range",
  nt.parameter("Pitch bend range"),
  send_pitch_bend == nil or send_pitch_bend.value == 1
)

local channel_sections = {}
for _, channel in ipairs(nt.channels()) do
  local children = {}
  add_choice(
    children,
    "CV input",
    nt.channel_parameter(channel, "CV input")
  )
  add_choice(
    children,
    "Gate input",
    nt.channel_parameter(channel, "Gate input")
  )
  add_choice(
    children,
    "CV output",
    nt.channel_parameter(channel, "CV output")
  )
  add_choice(
    children,
    "Gate output",
    nt.channel_parameter(channel, "Gate output")
  )
  add_choice(
    children,
    "Change output",
    nt.channel_parameter(channel, "Change output")
  )
  add_slider(
    children,
    "MIDI channel out",
    nt.channel_parameter(channel, "MIDI channel (out)")
  )

  if #children > 0 then
    table.insert(channel_sections, ui.section {
      title = "Channel " .. channel,
      children = children
    })
  end
end

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
  subtitle = available_count > 0 and
    (included_count .. " of " .. available_count .. " included") or nil,
  children = mask_children
})
if #microtuning_children > 0 then
  table.insert(root_children, ui.section {
    title = "Microtuning",
    subtitle = microtuning ~= nil and enum_label(microtuning) or nil,
    children = microtuning_children
  })
end
if #midi_children > 0 then
  table.insert(root_children, ui.section {
    title = "MIDI",
    children = midi_children
  })
end
if #channel_sections > 0 then
  table.insert(root_children, ui.section {
    title = "Channels",
    subtitle = #channel_sections .. " configured",
    children = channel_sections
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
