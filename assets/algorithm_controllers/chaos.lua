local function enum_label(parameter)
  if parameter == nil then return "" end
  local label = parameter.enum_values[parameter.value + 1]
  if label ~= nil and label ~= "" then return label end
  if parameter.display_value ~= "" then return parameter.display_value end
  return tostring(parameter.value)
end

local function scaled_value(parameter)
  if parameter == nil then return 0 end
  return parameter.value * (10 ^ parameter.power_of_ten)
end

local function finite(value)
  return value == value and math.abs(value) < 1000000
end

local function initial_state(attractor, reset_x, reset_y, reset_z)
  local x = scaled_value(reset_x)
  local y = scaled_value(reset_y)
  local z = scaled_value(reset_z)

  -- Several attractors have a stationary point at the origin. Use a tiny,
  -- deterministic displacement so the illustrative preview remains useful.
  if math.abs(x) + math.abs(y) + math.abs(z) < 0.000001 then
    if attractor == 1 then return 0.1, 0, 0.1 end
    if attractor == 2 then return 0.1, 0, 0 end
    if attractor == 3 then return 0.1, 0, 0 end
    if attractor == 4 then return 0.1, 0, 0 end
    return 0.1, 0, 0
  end
  return x, y, z
end

local function derivative(attractor, x, y, z, rho, beta)
  if attractor == 1 then
    -- Rössler
    return -y - z, x + 0.2 * y, 0.2 + z * (x - 5.7)
  end
  if attractor == 2 then
    -- Aizawa
    local a = 0.95
    local b = 0.7
    local c = 0.6
    local d = 3.5
    local e = 0.25
    local f = 0.1
    return
      (z - b) * x - d * y,
      d * x + (z - b) * y,
      c + a * z - (z * z * z) / 3 -
        (x * x + y * y) * (1 + e * z) +
        f * z * x * x * x
  end
  if attractor == 3 then
    -- Arneodo
    return y, z, -5.5 * x + 3.5 * y - z - x * x * x
  end
  if attractor == 4 then
    -- Thomas
    local b = 0.208186
    return
      math.sin(y) - b * x,
      math.sin(z) - b * y,
      math.sin(x) - b * z
  end

  -- Lorenz. The NT uses 64 and 8/3 as its unmodulated r and b values.
  return 10 * (y - x), x * (rho - z) - y, x * y - beta * z
end

local function simulation_points(
  attractor,
  rho_mod,
  beta_mod,
  reset_x,
  reset_y,
  reset_z
)
  local rho = math.max(0.1, math.min(100, 64 + scaled_value(rho_mod)))
  local beta = math.max(0.1, math.min(10, 8 / 3 + scaled_value(beta_mod)))
  local dt_values = { 0.004, 0.025, 0.01, 0.008, 0.05 }
  local dt = dt_values[attractor + 1] or 0.004
  local x, y, z = initial_state(attractor, reset_x, reset_y, reset_z)
  local fallback_x, fallback_y, fallback_z = x, y, z
  local points = {}

  -- Fixed iteration and sample counts keep controller evaluation bounded.
  for iteration = 1, 720 do
    local dx, dy, dz = derivative(attractor, x, y, z, rho, beta)
    x = x + dx * dt
    y = y + dy * dt
    z = z + dz * dt

    if not finite(x) or not finite(y) or not finite(z) then
      x = fallback_x + 0.001
      y = fallback_y
      z = fallback_z
    end

    if iteration > 120 and iteration % 4 == 0 then
      table.insert(points, { x = x, y = y, z = z })
    end
  end
  return points
end

local function projection_shapes(points, horizontal, vertical)
  local shapes = {
    ui.rect {
      x = 0,
      y = 0.02,
      width = 1,
      height = 0.96,
      radius = 0.06,
      fill = "surface_container_highest"
    }
  }

  if #points == 0 then return shapes end

  local minimum_x = points[1][horizontal]
  local maximum_x = minimum_x
  local minimum_y = points[1][vertical]
  local maximum_y = minimum_y
  for _, point in ipairs(points) do
    minimum_x = math.min(minimum_x, point[horizontal])
    maximum_x = math.max(maximum_x, point[horizontal])
    minimum_y = math.min(minimum_y, point[vertical])
    maximum_y = math.max(maximum_y, point[vertical])
  end

  if maximum_x - minimum_x < 0.000001 then
    minimum_x = minimum_x - 1
    maximum_x = maximum_x + 1
  end
  if maximum_y - minimum_y < 0.000001 then
    minimum_y = minimum_y - 1
    maximum_y = maximum_y + 1
  end

  local margin_x = (maximum_x - minimum_x) * 0.06
  local margin_y = (maximum_y - minimum_y) * 0.06
  minimum_x = minimum_x - margin_x
  maximum_x = maximum_x + margin_x
  minimum_y = minimum_y - margin_y
  maximum_y = maximum_y + margin_y

  local function x_position(value)
    return 0.04 + ((value - minimum_x) / (maximum_x - minimum_x)) * 0.92
  end

  local function y_position(value)
    return 0.96 - ((value - minimum_y) / (maximum_y - minimum_y)) * 0.92
  end

  if minimum_x <= 0 and maximum_x >= 0 then
    local axis = x_position(0)
    table.insert(shapes, ui.line {
      x1 = axis,
      y1 = 0.04,
      x2 = axis,
      y2 = 0.96,
      stroke = "outline"
    })
  end
  if minimum_y <= 0 and maximum_y >= 0 then
    local axis = y_position(0)
    table.insert(shapes, ui.line {
      x1 = 0.04,
      y1 = axis,
      x2 = 0.96,
      y2 = axis,
      stroke = "outline"
    })
  end

  local previous = nil
  for _, point in ipairs(points) do
    local current = {
      x = x_position(point[horizontal]),
      y = y_position(point[vertical])
    }
    if previous ~= nil then
      table.insert(shapes, ui.line {
        x1 = previous.x,
        y1 = previous.y,
        x2 = current.x,
        y2 = current.y,
        stroke = "primary",
        stroke_width = 1.5
      })
    end
    previous = current
  end
  return shapes
end

local attractor = nt.parameter("Attractor")
local speed_range = nt.parameter("Speed range")
local speed = nt.parameter("Speed")
local rho_mod = nt.parameter("Rho mod")
local beta_mod = nt.parameter("Beta mod")
local reset = nt.parameter("Reset")
local reset_x = nt.parameter("Reset X")
local reset_y = nt.parameter("Reset Y")
local reset_z = nt.parameter("Reset Z")

local dynamics_children = {}
if attractor ~= nil then
  table.insert(dynamics_children, ui.choice {
    label = "Attractor",
    parameter = attractor.number
  })
end
if speed_range ~= nil then
  table.insert(dynamics_children, ui.slider {
    label = "Speed range",
    parameter = speed_range.number
  })
end
if speed ~= nil then
  table.insert(dynamics_children, ui.slider {
    label = "Speed",
    parameter = speed.number
  })
end
if rho_mod ~= nil then
  table.insert(dynamics_children, ui.slider {
    label = "Rho modulation",
    parameter = rho_mod.number,
    enabled = attractor == nil or attractor.value == 0
  })
end
if beta_mod ~= nil then
  table.insert(dynamics_children, ui.slider {
    label = "Beta modulation",
    parameter = beta_mod.number,
    enabled = attractor == nil or attractor.value == 0
  })
end

local reset_children = {}
for _, item in ipairs({
  { parameter = reset_x, label = "Reset X" },
  { parameter = reset_y, label = "Reset Y" },
  { parameter = reset_z, label = "Reset Z" }
}) do
  if item.parameter ~= nil then
    table.insert(reset_children, ui.slider {
      label = item.label,
      parameter = item.parameter.number
    })
  end
end
if reset ~= nil then
  table.insert(reset_children, ui.button {
    label = "Reset attractor now",
    style = "outlined",
    action = {
      type = "pulse_parameter",
      parameter = reset.number
    }
  })
end

local output_children = {}
for _, axis in ipairs({ "X", "Y", "Z" }) do
  local scale = nt.parameter(axis .. " scale")
  local offset = nt.parameter(axis .. " offset")
  local axis_children = {}
  if scale ~= nil then
    table.insert(axis_children, ui.slider {
      label = axis .. " scale",
      parameter = scale.number
    })
  end
  if offset ~= nil then
    table.insert(axis_children, ui.slider {
      label = axis .. " offset",
      parameter = offset.number
    })
  end
  if #axis_children > 0 then
    table.insert(output_children, ui.section {
      title = axis .. " output",
      children = axis_children
    })
  end
end

local root_children = {}
if attractor ~= nil then
  local points = simulation_points(
    attractor.value,
    rho_mod,
    beta_mod,
    reset_x,
    reset_y,
    reset_z
  )
  local attractor_name = enum_label(attractor)
  table.insert(root_children, ui.section {
    title = "Attractor projections",
    subtitle = attractor_name,
    children = {
      ui.text {
        text = "A bounded illustration calculated from the selected equations and reset point; it is not the live output.",
        style = "caption"
      },
      ui.text { text = "X / Y", style = "subtitle" },
      ui.canvas {
        semantics_label = "Illustrative " .. attractor_name ..
          " X versus Y projection calculated from the current reset point. This is not live output.",
        aspect_ratio = 2.8,
        shapes = projection_shapes(points, "x", "y")
      },
      ui.text { text = "X / Z", style = "subtitle" },
      ui.canvas {
        semantics_label = "Illustrative " .. attractor_name ..
          " X versus Z projection calculated from the current reset point. This is not live output.",
        aspect_ratio = 2.8,
        shapes = projection_shapes(points, "x", "z")
      },
      ui.text { text = "Y / Z", style = "subtitle" },
      ui.canvas {
        semantics_label = "Illustrative " .. attractor_name ..
          " Y versus Z projection calculated from the current reset point. This is not live output.",
        aspect_ratio = 2.8,
        shapes = projection_shapes(points, "y", "z")
      }
    }
  })
end

if #dynamics_children > 0 then
  table.insert(root_children, ui.section {
    title = "Dynamics",
    subtitle = attractor ~= nil and enum_label(attractor) or nil,
    children = dynamics_children
  })
end
if #reset_children > 0 then
  table.insert(root_children, ui.section {
    title = "Reset point",
    children = reset_children
  })
end
if #output_children > 0 then
  table.insert(root_children, ui.section {
    title = "Output scaling",
    children = output_children
  })
end
if #root_children == 0 then
  table.insert(root_children, ui.text {
    text = "Chaos controls are unavailable in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Chaos",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
