local function parameter_text(parameter)
  if parameter == nil then return "Unavailable" end
  if parameter.display_value ~= nil and parameter.display_value ~= "" then
    return parameter.display_value
  end
  local enum = parameter.enum_values[parameter.value + 1]
  if enum ~= nil and enum ~= "" then return enum end
  return tostring(parameter.value)
end

local function normalized_value(parameter)
  if parameter == nil or parameter.maximum == parameter.minimum then return 0 end
  return math.max(
    0,
    math.min(
      1,
      (parameter.value - parameter.minimum) /
        (parameter.maximum - parameter.minimum)
    )
  )
end

local function macro_asymmetric_attack_fraction(joint_time)
  local position = normalized_value(joint_time)
  local positions = { 0, 0.25, 0.5, 0.75, 1 }
  local fractions = { 0.5, 0.15, 0.5, 0.85, 0.5 }

  for index = 1, #positions - 1 do
    if position <= positions[index + 1] then
      local span = positions[index + 1] - positions[index]
      local amount = (position - positions[index]) / span
      return fractions[index] +
        (fractions[index + 1] - fractions[index]) * amount
    end
  end
  return 0.5
end

local function attack_fraction(time_mode, joint_time, attack_time, release_time)
  if time_mode.value == 0 then
    return macro_asymmetric_attack_fraction(joint_time)
  end
  if time_mode.value == 1 then return 0.5 end

  local attack = normalized_value(attack_time)
  local release = normalized_value(release_time)
  if attack + release < 0.001 then return 0.5 end
  return math.max(0.12, math.min(0.88, attack / (attack + release)))
end

local function append_curve(
    shapes, x1, y1, x2, y2, exponent, rising, colour)
  local previous_x = x1
  local previous_y = y1
  for sample = 1, 12 do
    local position = sample / 12
    local curved = position ^ exponent
    if not rising then curved = 1 - (1 - position) ^ exponent end
    local x = x1 + (x2 - x1) * position
    local y = y1 + (y2 - y1) * curved
    table.insert(shapes, ui.line {
      x1 = previous_x,
      y1 = previous_y,
      x2 = x,
      y2 = y,
      stroke = colour,
      stroke_width = 3
    })
    previous_x = x
    previous_y = y
  end
end

local function append_ad_cycle(
    shapes,
    x1,
    x2,
    baseline_y,
    peak_y,
    fraction,
    attack_exponent,
    release_exponent)
  local attack_end = x1 + (x2 - x1) * fraction
  append_curve(
    shapes,
    x1,
    baseline_y,
    attack_end,
    peak_y,
    attack_exponent,
    true,
    "primary"
  )
  append_curve(
    shapes,
    attack_end,
    peak_y,
    x2,
    baseline_y,
    release_exponent,
    false,
    "secondary"
  )
end

local function envelope_shapes(
    trigger_mode,
    time_mode,
    joint_time,
    attack_time,
    release_time,
    attack_shape,
    release_shape)
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.05,
      width = 1,
      height = 0.9,
      radius = 0.08,
      fill = "surface_container_highest"
    },
    ui.line {
      x1 = 0.04,
      y1 = 0.82,
      x2 = 0.96,
      y2 = 0.82,
      stroke = "outline",
      stroke_width = 1
    }
  }

  local baseline_y = 0.82
  local peak_y = 0.14
  local fraction = attack_fraction(
    time_mode,
    joint_time,
    attack_time,
    release_time
  )
  local attack_exponent = 4 - normalized_value(attack_shape) * 3
  local release_exponent = 4 - normalized_value(release_shape) * 3

  if trigger_mode.value == 0 then
    local x1 = 0.06
    local x2 = 0.94
    local plateau_width = 0.2
    local moving_width = x2 - x1 - plateau_width
    local attack_end = x1 + moving_width * fraction
    local release_start = attack_end + plateau_width

    append_curve(
      shapes,
      x1,
      baseline_y,
      attack_end,
      peak_y,
      attack_exponent,
      true,
      "primary"
    )
    table.insert(shapes, ui.line {
      x1 = attack_end,
      y1 = peak_y,
      x2 = release_start,
      y2 = peak_y,
      stroke = "tertiary",
      stroke_width = 3
    })
    append_curve(
      shapes,
      release_start,
      peak_y,
      x2,
      baseline_y,
      release_exponent,
      false,
      "secondary"
    )
  elseif trigger_mode.value == 1 then
    append_ad_cycle(
      shapes,
      0.06,
      0.94,
      baseline_y,
      peak_y,
      fraction,
      attack_exponent,
      release_exponent
    )
  else
    append_ad_cycle(
      shapes,
      0.06,
      0.49,
      baseline_y,
      peak_y,
      fraction,
      attack_exponent,
      release_exponent
    )
    append_ad_cycle(
      shapes,
      0.51,
      0.94,
      baseline_y,
      peak_y,
      fraction,
      attack_exponent,
      release_exponent
    )
  end

  return shapes
end

local trigger_mode = nt.parameter("Trigger mode")
local time_mode = nt.parameter("Time mode")
local joint_time = nt.parameter("Joint time")
local attack_time = nt.parameter("Attack time")
local release_time = nt.parameter("Release time")
local attack_shape = nt.parameter("Attack shape")
local release_shape = nt.parameter("Release shape")

local root_children = {}
local shape_children = {}

if trigger_mode ~= nil then
  table.insert(shape_children, ui.choice {
    label = "Trigger mode",
    parameter = trigger_mode.number
  })
end
if time_mode ~= nil then
  table.insert(shape_children, ui.choice {
    label = "Time mode",
    parameter = time_mode.number
  })
end

local can_draw =
  trigger_mode ~= nil and
  time_mode ~= nil and
  attack_shape ~= nil and
  release_shape ~= nil and
  (
    (time_mode.value == 2 and attack_time ~= nil and release_time ~= nil) or
    (time_mode.value ~= 2 and joint_time ~= nil)
  )

if can_draw then
  local timing_description = ""
  if time_mode.value == 2 then
    timing_description =
      "attack " .. parameter_text(attack_time) ..
      " and release " .. parameter_text(release_time)
  else
    timing_description = "joint time " .. parameter_text(joint_time)
  end
  local gate_description = ""
  if trigger_mode.value == 0 then
    gate_description =
      " The plateau represents the externally held gate and has no configured duration."
  end

  table.insert(shape_children, ui.canvas {
    semantics_label =
      "Illustrative configured " .. parameter_text(trigger_mode) ..
      " envelope in " .. parameter_text(time_mode) .. " mode, with " ..
      timing_description .. ", attack shape " ..
      parameter_text(attack_shape) .. ", and release shape " ..
      parameter_text(release_shape) ..
      ". The curve is normalized to fit and is not live output or a precise time scale." ..
      gate_description,
    aspect_ratio = 6,
    shapes = envelope_shapes(
      trigger_mode,
      time_mode,
      joint_time,
      attack_time,
      release_time,
      attack_shape,
      release_shape
    )
  })
  local preview_text =
    "Configuration preview — normalized to fit, not live output."
  if trigger_mode.value == 0 then
    preview_text = preview_text ..
      " The plateau represents a held gate, not a configured duration."
  end
  table.insert(shape_children, ui.text {
    text = preview_text,
    style = "caption",
    align = "center"
  })
end

if time_mode ~= nil and time_mode.value == 2 then
  if attack_time ~= nil then
    table.insert(shape_children, ui.slider {
      label = "Attack time",
      parameter = attack_time.number
    })
  end
  if release_time ~= nil then
    table.insert(shape_children, ui.slider {
      label = "Release time",
      parameter = release_time.number
    })
  end
elseif joint_time ~= nil then
  table.insert(shape_children, ui.slider {
    label = "Joint time",
    parameter = joint_time.number
  })
end

if attack_shape ~= nil then
  table.insert(shape_children, ui.slider {
    label = "Attack shape",
    parameter = attack_shape.number
  })
end
if release_shape ~= nil then
  table.insert(shape_children, ui.slider {
    label = "Release shape",
    parameter = release_shape.number
  })
end

if #shape_children > 0 then
  local subtitle = nil
  if trigger_mode ~= nil and time_mode ~= nil then
    subtitle =
      parameter_text(trigger_mode) .. " · " .. parameter_text(time_mode)
  end
  table.insert(root_children, ui.section {
    title = "Envelope shape",
    subtitle = subtitle,
    children = shape_children
  })
end

for _, channel in ipairs(nt.channels()) do
  local enabled = nt.channel_parameter(channel, "Enable")
  local amplitude = nt.channel_parameter(channel, "Amplitude")
  local offset = nt.channel_parameter(channel, "Offset")
  local velocity_depth = nt.channel_parameter(channel, "Velocity depth")
  local children = {}

  if enabled ~= nil then
    table.insert(children, ui.toggle {
      label = "Enabled",
      parameter = enabled.number
    })
  end
  if amplitude ~= nil then
    table.insert(children, ui.slider {
      label = "Amplitude",
      parameter = amplitude.number
    })
  end
  if offset ~= nil then
    table.insert(children, ui.slider {
      label = "Offset",
      parameter = offset.number
    })
  end
  if velocity_depth ~= nil then
    table.insert(children, ui.slider {
      label = "Velocity depth",
      parameter = velocity_depth.number
    })
  end

  if #children > 0 then
    local subtitle_parts = {}
    if enabled ~= nil then
      table.insert(subtitle_parts, parameter_text(enabled))
    end
    if amplitude ~= nil then
      table.insert(
        subtitle_parts,
        "amplitude " .. parameter_text(amplitude)
      )
    end
    table.insert(root_children, ui.section {
      title = "Channel " .. channel,
      subtitle = table.concat(subtitle_parts, " · "),
      children = children
    })
  end
end

if #root_children == 0 then
  table.insert(root_children, ui.text {
    text = "No Envelope AR/AD controls were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Envelope AR/AD",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
