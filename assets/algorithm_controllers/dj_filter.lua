local function parameter_text(parameter)
  if parameter == nil then return "Unavailable" end
  if parameter.display_value ~= nil and parameter.display_value ~= "" then
    return parameter.display_value
  end
  local enum = parameter.enum_values[parameter.value + 1]
  if enum ~= nil and enum ~= "" then return enum end
  return tostring(parameter.value)
end

local sweep = nt.parameter("Sweep")
local resonance = nt.parameter("Resonance")
local filter_children = {}

if sweep ~= nil and resonance ~= nil then
  table.insert(filter_children, ui.text {
    text = "Low-pass ←  centre dry  → High-pass",
    style = "caption",
    align = "center"
  })
  table.insert(filter_children, ui.xy_pad {
    label = "DJ filter performance pad",
    x_label = "Sweep",
    y_label = "Resonance",
    x_parameter = sweep.number,
    y_parameter = resonance.number,
    aspect_ratio = 1.6,
    invert_y = true
  })
end

if sweep ~= nil then
  table.insert(filter_children, ui.slider {
    label = "Sweep",
    parameter = sweep.number
  })
end
if resonance ~= nil then
  table.insert(filter_children, ui.slider {
    label = "Resonance",
    parameter = resonance.number
  })
end

local root
if #filter_children == 0 then
  root = ui.text {
    text = "No DJ Filter controls were found in this slot.",
    style = "body"
  }
else
  local subtitle_parts = {}
  if sweep ~= nil then
    table.insert(subtitle_parts, "sweep " .. parameter_text(sweep))
  end
  if resonance ~= nil then
    table.insert(
      subtitle_parts,
      "resonance " .. parameter_text(resonance)
    )
  end
  root = ui.section {
    title = "Filter",
    subtitle = table.concat(subtitle_parts, " · "),
    children = filter_children
  }
end

return {
  version = 1,
  title = "DJ Filter",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = { root }
  }
}
