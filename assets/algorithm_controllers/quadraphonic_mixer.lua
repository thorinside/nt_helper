local function enum_label(parameter)
  if parameter == nil then return "" end
  local label = parameter.enum_values[parameter.value + 1]
  if label ~= nil and label ~= "" then return label end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

local function nominal_position(channel)
  local coordinates = nt.channel_parameter(channel, "Coordinates")
  local x = nt.channel_parameter(channel, "X")
  local y = nt.channel_parameter(channel, "Y")
  local angle = nt.channel_parameter(channel, "Angle")
  local radius = nt.channel_parameter(channel, "Radius")
  if coordinates == nil then return nil end

  if coordinates.value == 0 and x ~= nil and y ~= nil then
    return {
      x = clamp(x.value / 100, -1, 1),
      y = clamp(y.value / 100, -1, 1),
      description = "X " .. enum_label(x) .. ", Y " .. enum_label(y)
    }
  end

  if angle ~= nil and radius ~= nil then
    local radians = (angle.value / 10) * math.pi / 180
    local distance = clamp(radius.value / 100, 0, 1)
    return {
      x = math.sin(radians) * distance,
      y = math.cos(radians) * distance,
      description = "angle " .. enum_label(angle) ..
        ", radius " .. enum_label(radius)
    }
  end
  return nil
end

local channel_numbers = nt.channels()
local positions = {}
local position_descriptions = {}
for _, channel in ipairs(channel_numbers) do
  local position = nominal_position(channel)
  if position ~= nil then
    table.insert(positions, {
      channel = channel,
      x = position.x,
      y = position.y
    })
    table.insert(
      position_descriptions,
      "channel " .. channel .. " " .. position.description
    )
  end
end

local function field_shapes()
  local shapes = {
    ui.rect {
      x = 0,
      y = 0,
      width = 1,
      height = 1,
      radius = 0.05,
      fill = "surface_container_highest"
    },
    ui.line {
      x1 = 0.5,
      y1 = 0.05,
      x2 = 0.5,
      y2 = 0.95,
      stroke = "outline"
    },
    ui.line {
      x1 = 0.05,
      y1 = 0.5,
      x2 = 0.95,
      y2 = 0.5,
      stroke = "outline"
    }
  }

  for _, speaker in ipairs({
    { x = 0.035, y = 0.035 },
    { x = 0.915, y = 0.035 },
    { x = 0.035, y = 0.915 },
    { x = 0.915, y = 0.915 }
  }) do
    table.insert(shapes, ui.rect {
      x = speaker.x,
      y = speaker.y,
      width = 0.05,
      height = 0.05,
      radius = 0.012,
      fill = "on_surface_variant"
    })
  end

  local colors = { "primary", "secondary", "tertiary", "on_surface" }
  for index, position in ipairs(positions) do
    local x = 0.5 + clamp(position.x, -1, 1) * 0.4
    local y = 0.5 - clamp(position.y, -1, 1) * 0.4
    local color = colors[((index - 1) % #colors) + 1]
    table.insert(shapes, ui.line {
      x1 = 0.5,
      y1 = 0.5,
      x2 = x,
      y2 = y,
      stroke = color,
      stroke_width = 2
    })
    table.insert(shapes, ui.circle {
      x = x,
      y = y,
      radius = 0.035,
      fill = color,
      stroke = "surface",
      stroke_width = 2
    })
  end
  return shapes
end

local root_children = {}
if #positions > 0 then
  table.insert(root_children, ui.section {
    title = "Sound field",
    subtitle = #positions .. " nominal source positions",
    children = {
      ui.canvas {
        semantics_label = "Illustrative quadraphonic sound field showing " ..
          table.concat(position_descriptions, "; ") ..
          ". These are nominal parameter positions; spinner and orbiter phase are not live.",
        aspect_ratio = 1,
        shapes = field_shapes()
      },
      ui.text {
        text = "Front is at the top. The overview shows parameter positions, not live spinner or orbiter phase.",
        style = "caption"
      }
    }
  })
end

local common_children = {}
for _, control in ipairs({
  { label = "Overall gain", name = "Overall gain" },
  { label = "Front gain", name = "Front gain" },
  { label = "Rear gain", name = "Rear gain" },
  { label = "Front bass", name = "Front bass" },
  { label = "Front treble", name = "Front treble" },
  { label = "Rear bass", name = "Rear bass" },
  { label = "Rear treble", name = "Rear treble" }
}) do
  local parameter = nt.parameter(control.name)
  if parameter ~= nil then
    table.insert(common_children, ui.slider {
      label = control.label,
      parameter = parameter.number
    })
  end
end
if #common_children > 0 then
  table.insert(root_children, ui.section {
    title = "Output mix",
    subtitle = "Four-speaker gain and tone",
    children = common_children
  })
end

for _, channel in ipairs(channel_numbers) do
  local gain = nt.channel_parameter(channel, "Gain")
  local coordinates = nt.channel_parameter(channel, "Coordinates")
  local x = nt.channel_parameter(channel, "X")
  local y = nt.channel_parameter(channel, "Y")
  local angle = nt.channel_parameter(channel, "Angle")
  local radius = nt.channel_parameter(channel, "Radius")
  local spinner = nt.channel_parameter(channel, "Spinner")
  local spin_rate = nt.channel_parameter(channel, "Spin rate")
  local orbiter = nt.channel_parameter(channel, "Orbiter")
  local orbit_rate = nt.channel_parameter(channel, "Orbit rate")
  local orbit_radius = nt.channel_parameter(channel, "Orbit radius")
  local orbit_phase = nt.channel_parameter(channel, "Orbit phase")
  local mute = nt.channel_parameter(channel, "Mute")
  local solo = nt.channel_parameter(channel, "Solo")
  local distance_gain = nt.channel_parameter(channel, "Distance gain")

  if coordinates ~= nil then
    local children = {}
    if mute ~= nil then
      table.insert(children, ui.toggle {
        label = "Mute",
        parameter = mute.number
      })
    end
    if solo ~= nil then
      table.insert(children, ui.toggle {
        label = "Solo",
        parameter = solo.number
      })
    end
    if gain ~= nil then
      table.insert(children, ui.slider {
        label = "Gain",
        parameter = gain.number
      })
    end
    table.insert(children, ui.choice {
      label = "Coordinates",
      parameter = coordinates.number
    })

    if coordinates.value == 0 and x ~= nil and y ~= nil then
      table.insert(children, ui.xy_pad {
        label = "Position",
        x_label = "X",
        y_label = "Y",
        x_parameter = x.number,
        y_parameter = y.number,
        aspect_ratio = 1
      })
      table.insert(children, ui.slider {
        label = "X",
        parameter = x.number
      })
      table.insert(children, ui.slider {
        label = "Y",
        parameter = y.number
      })
    elseif angle ~= nil and radius ~= nil then
      table.insert(children, ui.slider {
        label = "Angle",
        parameter = angle.number
      })
      table.insert(children, ui.slider {
        label = "Radius",
        parameter = radius.number
      })
    end

    if coordinates.value ~= 0 and spinner ~= nil then
      table.insert(children, ui.slider {
        label = "Spinner",
        parameter = spinner.number
      })
    end
    if spin_rate ~= nil then
      table.insert(children, ui.slider {
        label = "Spin rate",
        parameter = spin_rate.number
      })
    end
    if orbiter ~= nil then
      table.insert(children, ui.slider {
        label = "Orbiter",
        parameter = orbiter.number
      })
    end
    if orbit_rate ~= nil then
      table.insert(children, ui.slider {
        label = "Orbit rate",
        parameter = orbit_rate.number
      })
    end
    if orbit_radius ~= nil then
      table.insert(children, ui.slider {
        label = "Orbit radius",
        parameter = orbit_radius.number
      })
    end
    if orbit_phase ~= nil then
      table.insert(children, ui.slider {
        label = "Orbit phase",
        parameter = orbit_phase.number
      })
    end
    if distance_gain ~= nil then
      table.insert(children, ui.slider {
        label = "Distance gain",
        parameter = distance_gain.number
      })
    end

    local position = nominal_position(channel)
    table.insert(root_children, ui.section {
      title = "Channel " .. channel,
      subtitle = enum_label(coordinates) ..
        (position ~= nil and " · " .. position.description or ""),
      children = children
    })
  end
end

if #root_children == 0 then
  table.insert(root_children, ui.text {
    text = "No quadraphonic mixer controls were found in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Quadraphonic Mixer",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
