local function enum_label(parameter)
  if parameter == nil then return "" end
  local label = parameter.enum_values[parameter.value + 1]
  if label ~= nil and label ~= "" then return label end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function display_value(parameter)
  if parameter == nil then return "" end
  if parameter.display_value ~= "" then return parameter.display_value end
  local multiplier = 10 ^ parameter.power_of_ten
  local value = parameter.value * multiplier
  if parameter.power_of_ten < 0 then
    return string.format(
      "%." .. math.abs(parameter.power_of_ten) .. "f",
      value
    )
  end
  return tostring(value)
end

local function curve_value(curve, position)
  if curve == 0 then return 0 end
  if curve == 1 then return 1 end
  if curve == 2 then return position end
  if curve == 3 then return 1 - position end
  if curve == 4 then return position * position * position end
  if curve == 5 then
    local inverse = 1 - position
    return inverse * inverse * inverse
  end
  if curve == 6 then
    local inverse = 1 - position
    return 1 - inverse * inverse * inverse
  end
  if curve == 7 then
    return 1 - position * position * position
  end
  if curve == 8 then
    return position * position * (3 - 2 * position)
  end
  if curve == 9 then
    return 1 - position * position * (3 - 2 * position)
  end
  if curve == 10 then
    return 1 - math.abs(position * 2 - 1)
  end
  return (1 - math.cos(position * math.pi * 2)) / 2
end

local function scaled_value(parameter)
  if parameter == nil then return 0 end
  return parameter.value * (10 ^ parameter.power_of_ten)
end

local function division_count(parameter)
  if parameter == nil then return 1, "none" end
  if parameter.value <= 6 then return 8 - parameter.value, "ratchet" end
  if parameter.value >= 8 then return parameter.value - 6, "repeat" end
  return 1, "none"
end

local steps = {}
for step = 1, 16 do
  table.insert(steps, {
    number = step,
    curve = nt.channel_parameter(step, "Curve"),
    scale = nt.channel_parameter(step, "Scale"),
    offset = nt.channel_parameter(step, "Offset"),
    division = nt.channel_parameter(step, "Division"),
    mute = nt.channel_parameter(step, "Mute"),
    skip = nt.channel_parameter(step, "Skip"),
    reset = nt.channel_parameter(step, "Reset"),
    repeat_step = nt.channel_parameter(step, "Repeat")
  })
end

local start_step = nt.parameter("Start")
local end_step = nt.parameter("End")

local function sequence_shapes()
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.02,
      width = 1,
      height = 0.96,
      radius = 0.04,
      fill = "surface_container_highest"
    }
  }

  local minimum = 0
  local maximum = 0
  for _, step in ipairs(steps) do
    if step.curve ~= nil and step.scale ~= nil and step.offset ~= nil then
      for sample = 0, 8 do
        local value = scaled_value(step.offset) +
          scaled_value(step.scale) *
          curve_value(step.curve.value, sample / 8)
        minimum = math.min(minimum, value)
        maximum = math.max(maximum, value)
      end
    end
  end
  if maximum - minimum < 0.1 then
    minimum = minimum - 1
    maximum = maximum + 1
  end
  local margin = (maximum - minimum) * 0.08
  minimum = minimum - margin
  maximum = maximum + margin

  local function y_position(value)
    return 0.88 - ((value - minimum) / (maximum - minimum)) * 0.72
  end

  if minimum <= 0 and maximum >= 0 then
    local zero = y_position(0)
    table.insert(shapes, ui.line {
      x1 = 0.025,
      y1 = zero,
      x2 = 0.975,
      y2 = zero,
      stroke = "outline"
    })
  end

  local active_start = start_step ~= nil and start_step.value or 1
  local active_end = end_step ~= nil and end_step.value or 16
  for _, step in ipairs(steps) do
    local left = 0.025 + ((step.number - 1) / 16) * 0.95
    local width = 0.95 / 16
    local active = step.number >= active_start and step.number <= active_end
    if active then
      table.insert(shapes, ui.rect {
        x = left,
        y = 0.08,
        width = width,
        height = 0.84,
        fill = "surface_container",
        stroke = "primary"
      })
    end

    table.insert(shapes, ui.line {
      x1 = left,
      y1 = 0.08,
      x2 = left,
      y2 = 0.92,
      stroke = "outline"
    })

    if step.curve ~= nil and step.scale ~= nil and step.offset ~= nil then
      local previous = nil
      for sample = 0, 8 do
        local position = sample / 8
        local value = scaled_value(step.offset) +
          scaled_value(step.scale) *
          curve_value(step.curve.value, position)
        local current = {
          x = left + position * width,
          y = y_position(value)
        }
        if previous ~= nil then
          table.insert(shapes, ui.line {
            x1 = previous.x,
            y1 = previous.y,
            x2 = current.x,
            y2 = current.y,
            stroke = step.mute ~= nil and step.mute.value == 100 and
              "error" or "primary",
            stroke_width = active and 2.5 or 1.5
          })
        end
        previous = current
      end
    end

    local count, division_type = division_count(step.division)
    if division_type ~= "none" then
      for subdivision = 1, count do
        local indicator_width = width / count
        table.insert(shapes, ui.rect {
          x = left + (subdivision - 1) * indicator_width + 0.002,
          y = 0.055,
          width = math.max(0.002, indicator_width - 0.004),
          height = 0.018,
          fill = division_type == "ratchet" and "tertiary" or "secondary"
        })
      end
    end
  end

  table.insert(shapes, ui.line {
    x1 = 0.975,
    y1 = 0.08,
    x2 = 0.975,
    y2 = 0.92,
    stroke = "outline"
  })
  return shapes
end

local sequencer_children = {}
local sequence = nt.parameter("Sequence")
local direction = nt.parameter("Direction")
local permutation = nt.parameter("Permutation")
local reset_offset = nt.parameter("Reset offset")
local length_type = nt.parameter("Length type")
local percent_length = nt.parameter("% length")
local fixed_length = nt.parameter("Fixed length")

for _, item in ipairs({
  { parameter = sequence, label = "Sequence", kind = "slider" },
  { parameter = start_step, label = "Start step", kind = "slider" },
  { parameter = end_step, label = "End step", kind = "slider" },
  { parameter = direction, label = "Direction", kind = "choice" },
  { parameter = permutation, label = "Permutation", kind = "choice" },
  { parameter = reset_offset, label = "Reset offset", kind = "slider" },
  { parameter = length_type, label = "Length type", kind = "choice" }
}) do
  if item.parameter ~= nil then
    if item.kind == "choice" then
      table.insert(sequencer_children, ui.choice {
        label = item.label,
        parameter = item.parameter.number
      })
    else
      table.insert(sequencer_children, ui.slider {
        label = item.label,
        parameter = item.parameter.number
      })
    end
  end
end
if length_type == nil or length_type.value == 0 then
  if percent_length ~= nil then
    table.insert(sequencer_children, ui.slider {
      label = "Step length",
      parameter = percent_length.number
    })
  end
elseif fixed_length ~= nil then
  table.insert(sequencer_children, ui.slider {
    label = "Step length",
    parameter = fixed_length.number
  })
end

local quick_mute_buttons = {}
local step_sections = {}
for _, step in ipairs(steps) do
  if step.mute ~= nil then
    table.insert(quick_mute_buttons, ui.button {
      label = "Step " .. step.number .. " · mute " .. display_value(step.mute),
      style = step.mute.value > 0 and "filled" or "outlined",
      action = {
        type = "set_parameter",
        parameter = step.mute.number,
        value = step.mute.value > 0 and 0 or 100
      }
    })
  end

  local children = {}
  if step.curve ~= nil then
    table.insert(children, ui.choice {
      label = "Curve",
      parameter = step.curve.number
    })
  end
  for _, item in ipairs({
    { parameter = step.scale, label = "Scale" },
    { parameter = step.offset, label = "Offset" }
  }) do
    if item.parameter ~= nil then
      table.insert(children, ui.slider {
        label = item.label,
        parameter = item.parameter.number
      })
    end
  end
  if step.division ~= nil then
    table.insert(children, ui.choice {
      label = "Division",
      parameter = step.division.number
    })
  end
  for _, item in ipairs({
    { parameter = step.mute, label = "Mute probability" },
    { parameter = step.skip, label = "Skip probability" },
    { parameter = step.reset, label = "Reset probability" },
    { parameter = step.repeat_step, label = "Repeat probability" }
  }) do
    if item.parameter ~= nil then
      table.insert(children, ui.slider {
        label = item.label,
        parameter = item.parameter.number
      })
    end
  end

  if #children > 0 then
    local subtitle_parts = {}
    if step.curve ~= nil then
      table.insert(subtitle_parts, enum_label(step.curve))
    end
    if step.scale ~= nil then
      table.insert(subtitle_parts, "scale " .. display_value(step.scale))
    end
    if step.offset ~= nil then
      table.insert(subtitle_parts, "offset " .. display_value(step.offset))
    end
    if step.division ~= nil then
      table.insert(subtitle_parts, enum_label(step.division))
    end
    table.insert(step_sections, ui.section {
      title = "Step " .. step.number,
      subtitle = table.concat(subtitle_parts, " · "),
      children = children
    })
  end
end

local randomise_children = {}
for _, item in ipairs({
  { parameter = nt.parameter("Levels"), label = "Randomise levels" },
  { parameter = nt.parameter("Curves"), label = "Randomise curves" },
  { parameter = nt.parameter("Repeats"), label = "Randomise divisions" }
}) do
  if item.parameter ~= nil then
    table.insert(randomise_children, ui.toggle {
      label = item.label,
      parameter = item.parameter.number
    })
  end
end
for _, item in ipairs({
  { parameter = nt.parameter("Min repeat"), label = "Minimum repeat" },
  { parameter = nt.parameter("Max repeat"), label = "Maximum repeat" },
  { parameter = nt.parameter("Min ratchet"), label = "Minimum ratchet" },
  { parameter = nt.parameter("Max ratchet"), label = "Maximum ratchet" },
  {
    parameter = nt.parameter("Repeat probability"),
    label = "Repeat probability"
  },
  {
    parameter = nt.parameter("Ratchet probability"),
    label = "Ratchet probability"
  }
}) do
  if item.parameter ~= nil then
    table.insert(randomise_children, ui.slider {
      label = item.label,
      parameter = item.parameter.number
    })
  end
end
local randomise = nt.parameter("Randomise")
if randomise ~= nil then
  table.insert(randomise_children, ui.button {
    label = "Randomise active steps now",
    style = "outlined",
    action = {
      type = "pulse_parameter",
      parameter = randomise.number
    }
  })
end

local root_children = {}
if #sequencer_children > 0 then
  table.insert(root_children, ui.section {
    title = "Sequence",
    subtitle = sequence ~= nil and
      ("Pattern " .. display_value(sequence)) or nil,
    children = sequencer_children
  })
end
  table.insert(root_children, ui.section {
    title = "Sixteen-step overview",
    subtitle = start_step ~= nil and end_step ~= nil and
      ("Playback range " .. display_value(start_step) .. "–" ..
        display_value(end_step)) or nil,
  children = {
    ui.text {
      text = "Illustrative stored curve shapes. The preview has no live playhead; narrow marks above each step show its ratchet or repeat subdivisions.",
      style = "caption"
    },
      ui.canvas {
        semantics_label = "Illustrative 16-step envelope preview for " ..
        (sequence ~= nil and ("sequence " .. display_value(sequence)) or
          "the current sequence") .. ". Playback range " ..
        (start_step ~= nil and display_value(start_step) or "1") ..
        " through " ..
        (end_step ~= nil and display_value(end_step) or "16") ..
        ". It reflects stored curve, scale, offset, and division parameters and is not a live playhead.",
      aspect_ratio = 6,
      shapes = sequence_shapes()
    }
  }
})
if #quick_mute_buttons > 0 then
  table.insert(root_children, ui.section {
    title = "Quick full-mute",
    subtitle = "Press a step to toggle its mute probability between 0 and 100 percent",
    children = {
      ui.row {
        gap = 8,
        children = quick_mute_buttons
      }
    }
  })
end
if #step_sections > 0 then
  table.insert(root_children, ui.section {
    title = "Steps",
    subtitle = #step_sections .. " editable steps",
    children = step_sections
  })
end
if #randomise_children > 0 then
  table.insert(root_children, ui.section {
    title = "Randomise",
    subtitle = "Applies to the current start/end range",
    children = randomise_children
  })
end

return {
  version = 1,
  title = "Envelope Sequencer",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
