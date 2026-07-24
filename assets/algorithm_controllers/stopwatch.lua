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

local mode = page_parameter("Setup", "Mode")
local start_stop_mode = page_parameter("Setup", "Start/stop mode")
local start_stop = page_parameter("Controls", "Start/stop")
local reset = page_parameter("Controls", "Reset")

local control_children = {
  ui.text {
    text = "The current timer or countdown is shown on the disting NT; this panel does not receive a live clock.",
    style = "caption"
  }
}

if start_stop ~= nil then
  if start_stop_mode == nil or start_stop_mode.value == 0 then
    table.insert(control_children, ui.toggle {
      label = "Run while gate is on",
      parameter = start_stop.number
    })
  else
    table.insert(control_children, ui.button {
      label = "Trigger start or stop",
      style = "filled",
      enabled = not start_stop.disabled,
      action = {
        type = "pulse_parameter",
        parameter = start_stop.number
      }
    })
  end
end
if reset ~= nil then
  table.insert(control_children, ui.button {
    label = mode ~= nil and mode.value == 1 and
      "Reset countdown" or "Reset timer",
    style = "outlined",
    enabled = not reset.disabled,
    action = {
      type = "pulse_parameter",
      parameter = reset.number
    }
  })
end

local setup_children = {}
if mode ~= nil then
  table.insert(setup_children, ui.choice {
    label = "Timer mode",
    parameter = mode.number
  })
end
if start_stop_mode ~= nil then
  table.insert(setup_children, ui.choice {
    label = "Start and stop control",
    parameter = start_stop_mode.number
  })
end

local countdown_children = {}
if mode ~= nil and mode.value == 1 then
  for _, item in ipairs({
    { name = "Hours", label = "Countdown hours" },
    { name = "Minutes", label = "Countdown minutes" },
    { name = "Seconds", label = "Countdown seconds" }
  }) do
    local parameter = page_parameter("Countdown", item.name)
    if parameter ~= nil then
      table.insert(countdown_children, ui.slider {
        label = item.label,
        parameter = parameter.number
      })
    end
  end
end

local root_children = {}
if #control_children > 1 then
  local control_style = "Toggle trigger"
  if start_stop_mode ~= nil and start_stop_mode.value == 0 then
    control_style = "Gate"
  end
  table.insert(root_children, ui.section {
    title = "Controls",
    subtitle = control_style .. " control",
    children = control_children
  })
end
if #setup_children > 0 then
  table.insert(root_children, ui.section {
    title = "Setup",
    subtitle = mode ~= nil and mode.value == 1 and "Countdown" or "Timer",
    children = setup_children
  })
end
if #countdown_children > 0 then
  table.insert(root_children, ui.section {
    title = "Countdown",
    subtitle = "Configured duration",
    children = countdown_children
  })
end

if #root_children == 0 then
  table.insert(root_children, ui.text {
    text = "Stopwatch controls are unavailable in this slot.",
    style = "body"
  })
end

return {
  version = 1,
  title = "Stopwatch",
  root = ui.column {
    gap = 16,
    padding = 16,
    children = root_children
  }
}
