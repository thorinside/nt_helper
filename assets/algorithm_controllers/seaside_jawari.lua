local function page_parameter(page_name, name)
  local page = nt.page(page_name)
  if page == nil then return nil end

  for _, parameter_number in ipairs(page.parameters or {}) do
    local parameter = nt.parameter_by_number(parameter_number)
    if parameter ~= nil and
        parameter.name == name and
        (parameter.io_flags or 0) == 0 and
        parameter.is_input ~= true and
        parameter.is_output ~= true then
      return parameter
    end
  end
  return nil
end

local bridge_shape = page_parameter("Jawari", "Bridge shape")
local first_string_tuning =
  page_parameter("Jawari", "Tuning (1st string)")
local transpose = page_parameter("Jawari", "Transpose")
local fine_tune = page_parameter("Jawari", "Fine tune")
local strum = page_parameter("Jawari", "Strum")
local reset = page_parameter("Jawari", "Reset")
local velocity = page_parameter("Jawari", "Velocity")

local play_children = {
  ui.text {
    text = "Strum advances through the four strings. Reset makes the next strum play string 1.",
    style = "caption"
  }
}

local action_buttons = {}
if strum ~= nil then
  table.insert(action_buttons, ui.button {
    label = "Strum next string",
    style = "filled",
    enabled = not strum.disabled,
    action = {
      type = "pulse_parameter",
      parameter = strum.number
    }
  })
end
if reset ~= nil then
  table.insert(action_buttons, ui.button {
    label = "Reset string sequence",
    style = "outlined",
    enabled = not reset.disabled,
    action = {
      type = "pulse_parameter",
      parameter = reset.number
    }
  })
end
if #action_buttons > 0 then
  table.insert(play_children, ui.row {
    gap = 12,
    children = action_buttons
  })
end
if velocity ~= nil then
  table.insert(play_children, ui.slider {
    label = "Strum velocity",
    parameter = velocity.number
  })
end

local tuning_children = {}
if first_string_tuning ~= nil then
  table.insert(tuning_children, ui.choice {
    label = "First string tuning",
    parameter = first_string_tuning.number
  })
end
if transpose ~= nil then
  table.insert(tuning_children, ui.slider {
    label = "Transpose",
    parameter = transpose.number
  })
end
if fine_tune ~= nil then
  table.insert(tuning_children, ui.slider {
    label = "Fine tune",
    parameter = fine_tune.number
  })
end

local timbre_children = {}
if bridge_shape ~= nil then
  table.insert(timbre_children, ui.slider {
    label = "Bridge shape",
    parameter = bridge_shape.number
  })
end
for _, item in ipairs({
  { name = "Damping", label = "Damping", kind = "slider" },
  { name = "Length", label = "Decay length", kind = "slider" },
  { name = "Bounce count", label = "Bridge bounce count", kind = "slider" },
  { name = "Strum level", label = "Strum level", kind = "slider" },
  { name = "Bounce level", label = "Bounce level", kind = "slider" },
  { name = "Start harmonic", label = "Start harmonic", kind = "slider" },
  { name = "End harmonic", label = "End harmonic", kind = "slider" },
  { name = "Strum type", label = "Strum shape", kind = "choice" }
}) do
  local parameter = page_parameter("Tweaks", item.name)
  if parameter ~= nil then
    if item.kind == "choice" then
      table.insert(timbre_children, ui.choice {
        label = item.label,
        parameter = parameter.number
      })
    else
      table.insert(timbre_children, ui.slider {
        label = item.label,
        parameter = parameter.number
      })
    end
  end
end

local root_children = {}
if #play_children > 1 then
  table.insert(root_children, ui.section {
    title = "Play",
    subtitle = "Four-string tanpura",
    children = play_children
  })
end
if #tuning_children > 0 then
  table.insert(root_children, ui.section {
    title = "Tuning",
    subtitle = "First string and instrument pitch",
    children = tuning_children
  })
end
if #timbre_children > 0 then
  table.insert(root_children, ui.section {
    title = "String model",
    subtitle = "Bridge, decay, and harmonics",
    children = timbre_children
  })
end

if #root_children == 0 then
  table.insert(root_children, ui.text {
    text = "Seaside Jawari performance controls are unavailable in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Seaside Jawari",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
