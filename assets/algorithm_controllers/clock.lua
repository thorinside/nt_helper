local function enum_label(parameter)
  if parameter == nil then return "" end
  local label = parameter.enum_values[parameter.value + 1]
  if label ~= nil and label ~= "" then return label end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function swing_shapes(swing_type, swing, note_1, note_2, note_3)
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.08,
      width = 1,
      height = 0.84,
      radius = 0.08,
      fill = "surface_container_highest"
    }
  }

  if swing_type.value <= 2 then
    local shift = (swing.value / 1000) * 0.025
    for step = 0, 15 do
      local x = 0.04 + (step / 15) * 0.92
      if swing_type.value == 1 and step % 2 == 1 then x = x + shift end
      if swing_type.value == 2 and step % 4 == 2 then x = x + shift end
      x = math.max(0.025, math.min(0.975, x))
      table.insert(shapes, ui.line {
        x1 = x,
        y1 = step % 4 == 0 and 0.24 or 0.36,
        x2 = x,
        y2 = 0.76,
        stroke = step % 4 == 0 and "primary" or "outline",
        stroke_width = step % 4 == 0 and 3 or 1
      })
    end
  else
    local subdivisions = swing_type.value + 2
    for step = 0, subdivisions do
      local x = 0.05 + (step / subdivisions) * 0.9
      table.insert(shapes, ui.line {
        x1 = x,
        y1 = 0.36,
        x2 = x,
        y2 = 0.72,
        stroke = step == 0 and "primary" or "outline",
        stroke_width = step == 0 and 3 or 1
      })
    end
    for _, note in ipairs({ note_1, note_2, note_3 }) do
      if note ~= nil then
        local position = math.max(1, math.min(subdivisions, note.value))
        table.insert(shapes, ui.circle {
          x = 0.05 + (position / subdivisions) * 0.9,
          y = 0.28,
          radius = 0.035,
          fill = "tertiary",
          stroke = "tertiary"
        })
      end
    end
  end
  return shapes
end

local function ratchet_count(mode, value)
  if mode == 1 then
    local values = { 1, 2, 4, 8, 16, 16, 16, 16 }
    return values[value + 1] or 1
  end
  if mode == 2 then
    local values = { 1, 2, 3, 4, 6, 8, 12, 16 }
    return values[value + 1] or 1
  end
  return 1
end

local function output_shapes(output_type, divisor, ratchet_mode, ratchet)
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.1,
      width = 1,
      height = 0.8,
      radius = 0.08,
      fill = "surface_container_highest"
    },
    ui.line {
      x1 = 0.04,
      y1 = 0.72,
      x2 = 0.96,
      y2 = 0.72,
      stroke = "outline"
    }
  }

  if output_type.value == 0 then
    local pulse_count = math.max(1, math.min(8, 16 - divisor.value))
    local ratchets = ratchet_count(
      ratchet_mode ~= nil and ratchet_mode.value or 0,
      ratchet ~= nil and ratchet.value or 0
    )
    local shown_ratchets = math.min(4, ratchets)
    for pulse = 0, pulse_count - 1 do
      local center = 0.08
      if pulse_count > 1 then center = 0.08 + (pulse / (pulse_count - 1)) * 0.84 end
      for sub = 0, shown_ratchets - 1 do
        local offset = (sub - (shown_ratchets - 1) / 2) * 0.018
        table.insert(shapes, ui.line {
          x1 = center + offset,
          y1 = 0.32,
          x2 = center + offset,
          y2 = 0.72,
          stroke = "primary",
          stroke_width = 2
        })
      end
    end
  elseif output_type.value == 1 then
    table.insert(shapes, ui.rect {
      x = 0.08,
      y = 0.3,
      width = 0.84,
      height = 0.42,
      radius = 0.02,
      fill = "primary"
    })
  else
    table.insert(shapes, ui.rect {
      x = output_type.value == 2 and 0.08 or 0.48,
      y = 0.3,
      width = 0.08,
      height = 0.42,
      radius = 0.02,
      fill = output_type.value == 2 and "secondary" or "tertiary"
    })
  end
  return shapes
end

local source = nt.parameter("Source")
local tempo = nt.parameter("Tempo")
local run = nt.parameter("Run")
local numerator = nt.parameter("Time sig numerator")
local denominator = nt.parameter("Time sig denominator")
local swing_type = nt.parameter("Swing type")
local swing = nt.parameter("Swing")
local note_1 = nt.parameter("16th note 1")
local note_2 = nt.parameter("16th note 2")
local note_3 = nt.parameter("16th note 3")

local common_children = {}
if source ~= nil then
  table.insert(common_children, ui.choice {
    label = "Source",
    parameter = source.number
  })
end
if run ~= nil then
  table.insert(common_children, ui.toggle {
    label = "Run",
    parameter = run.number
  })
end
if tempo ~= nil then
  table.insert(common_children, ui.slider {
    label = "Tempo",
    parameter = tempo.number,
    enabled = source == nil or source.value == 0
  })
end
if numerator ~= nil then
  table.insert(common_children, ui.slider {
    label = "Numerator",
    parameter = numerator.number
  })
end
if denominator ~= nil then
  table.insert(common_children, ui.choice {
    label = "Denominator",
    parameter = denominator.number
  })
end

local swing_children = {}
if swing_type ~= nil then
  table.insert(swing_children, ui.choice {
    label = "Swing type",
    parameter = swing_type.number
  })
end
if swing ~= nil then
  table.insert(swing_children, ui.slider {
    label = "Swing",
    parameter = swing.number,
    enabled = swing_type == nil or swing_type.value ~= 0
  })
end
if swing_type ~= nil and swing_type.value >= 3 then
  for index, note in ipairs({ note_1, note_2, note_3 }) do
    if note ~= nil then
      table.insert(swing_children, ui.slider {
        label = "16th note " .. index,
        parameter = note.number
      })
    end
  end
end
if swing_type ~= nil and swing ~= nil then
  table.insert(swing_children, ui.canvas {
    semantics_label = "Illustrative " .. enum_label(swing_type) ..
      " timing preview at swing " .. enum_label(swing) ..
      "; this is not live transport.",
    aspect_ratio = 6,
    shapes = swing_shapes(swing_type, swing, note_1, note_2, note_3)
  })
end

local output_sections = {}
for _, output in ipairs(nt.channels()) do
  local enabled = nt.channel_parameter(output, "Enable")
  local output_type = nt.channel_parameter(output, "Type")
  local divisor = nt.channel_parameter(output, "Divisor")
  local low_voltage = nt.channel_parameter(output, "Low voltage")
  local high_voltage = nt.channel_parameter(output, "High voltage")
  local ratchet_mode = nt.channel_parameter(output, "Ratchet mode")
  local ratchet = nt.channel_parameter(output, "Ratchet")
  local trigger_length = nt.channel_parameter(output, "Trigger length")

  if output_type ~= nil then
    local children = {}
    if enabled ~= nil then
      table.insert(children, ui.toggle {
        label = "Enabled",
        parameter = enabled.number
      })
    end
    table.insert(children, ui.choice {
      label = "Type",
      parameter = output_type.number
    })
    if output_type.value == 0 and divisor ~= nil then
      table.insert(children, ui.choice {
        label = "Divisor",
        parameter = divisor.number
      })
    end
    if low_voltage ~= nil then
      table.insert(children, ui.slider {
        label = "Low voltage",
        parameter = low_voltage.number
      })
    end
    if high_voltage ~= nil then
      table.insert(children, ui.slider {
        label = "High voltage",
        parameter = high_voltage.number
      })
    end
    if output_type.value == 0 and ratchet_mode ~= nil then
      table.insert(children, ui.choice {
        label = "Ratchet mode",
        parameter = ratchet_mode.number
      })
      if ratchet_mode.value ~= 0 and ratchet ~= nil then
        table.insert(children, ui.slider {
          label = "Ratchet",
          parameter = ratchet.number
        })
      end
    end
    if output_type.value >= 2 and trigger_length ~= nil then
      table.insert(children, ui.slider {
        label = "Trigger length",
        parameter = trigger_length.number
      })
    end
    table.insert(children, ui.canvas {
      semantics_label = "Illustrative output " .. output .. " " ..
        enum_label(output_type) .. " behavior preview" ..
        (divisor ~= nil and output_type.value == 0 and
          (" at " .. enum_label(divisor)) or "") ..
        "; this is not live phase or signal state.",
      aspect_ratio = 5.5,
      shapes = output_shapes(
        output_type,
        divisor or { value = 0 },
        ratchet_mode,
        ratchet
      )
    })

    table.insert(output_sections, ui.section {
      title = "Output " .. output,
      subtitle = enum_label(output_type) ..
        (divisor ~= nil and output_type.value == 0 and
          (" · " .. enum_label(divisor)) or ""),
      children = children
    })
  end
end

local root_children = {
  ui.section {
    title = "Clock",
    subtitle = source ~= nil and enum_label(source) or nil,
    children = common_children
  },
  ui.section {
    title = "Swing",
    subtitle = swing_type ~= nil and enum_label(swing_type) or nil,
    children = swing_children
  }
}
for _, section in ipairs(output_sections) do
  table.insert(root_children, section)
end

return {
  version = 1,
  title = "Clock",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
