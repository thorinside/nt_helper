-- NT Helper companion, executed on the computer, NOT a disting NT Lua algorithm.
-- Install as /programs/helper/ThPh.lua on the NT SD card.
local models = { 'NTX-8CV', 'ES-5', 'ESX-8GT', 'ESX-8CV' }
local companion = {
  api_version = 1,
  guid = 'ThPh',
  render = function(state)
    local groups = {
      { title = 'Inputs', short = 'Inputs', start = 0, count = 12, columns = 4 },
      { title = 'Outputs', short = 'Outputs', start = 12, count = 8, columns = 2 },
    }
    for i, expander in ipairs(state.expanders) do
      groups[#groups + 1] = {
        title = expander.name .. ' · ' .. models[expander.type + 1],
        short = 'E' .. i, start = 20 + (i - 1) * 8, count = 8, columns = 1,
      }
    end
    local choices = {}
    for i, model in ipairs(models) do
      choices[#choices + 1] = { label = model, value = i - 1 }
    end
    local actions = {
        { id = 'add_expander', label = 'Add expander', dialog = {
          type = 'choice_dialog', title = 'Add expander', cancel = 'Cancel',
          choices = choices,
        } },
      }
    local record_sections = {}
    if state.supports_aux then
      local section = {
        id = 'aux', source = 'aux', identity = 'bus', title = 'AUX buses', short = 'AUX',
        row_label = 'AUX', identity_label = 'Bus', after_socket = 19,
        columns = {
          {key = 'bus', type = 'label', label = 'Bus', width = 96, min_width = 72},
          {key = 'description', type = 'text', label = 'Description', max_length = 32, width = 360, min_width = 140, flex = 3},
          {key = 'group', type = 'text', label = 'Group', max_length = 32, width = 280, min_width = 100, flex = 2},
          {key = 'remove', type = 'remove', label = 'Remove', width = 96, min_width = 80},
        },
        remove_event = 'remove_aux', remove_label = 'Remove',
        confirmation = {title = 'Remove {record}?', message = 'This deletes its description and group.', cancel = 'Cancel', confirm = 'Remove'},
      }
      record_sections[1] = section
      local used = {}
      for _, row in ipairs(state.aux) do used[row.bus] = true end
      local aux_choices = {}
      for bus = 1, 44 do
        if not used[bus] then aux_choices[#aux_choices + 1] = {label = 'AUX ' .. bus, value = bus} end
      end
      if #aux_choices > 0 then
        section.add_action = 'add_aux'
        actions[#actions + 1] = {id = 'add_aux', label = 'AUX', dialog = {
          type = 'choice_dialog', title = 'Add AUX bus', cancel = 'Cancel', choices = aux_choices,
        }}
      end
    end
    return {
      actions = actions, record_sections = record_sections,
      table_id = 'sockets',
      columns = {
        {key = 'socket', type = 'label', label = 'Socket', width = 96, min_width = 72},
        {key = 'destination', type = 'text', label = 'Destination', width = 288, min_width = 140, flex = 3},
        {key = 'colour', type = 'colour', label = 'Cable colour', width = 126, min_width = 112},
        {key = 'tag', type = 'integer', label = 'Tag', width = 64, min_width = 48},
        {key = 'group', type = 'text', label = 'Group', width = 220, min_width = 100, flex = 2},
      },
      version = 1, type = 'socket_table', groups = groups,
      labels = { socket = 'Socket', destination = 'Destination', colour = 'Cable colour', tag = 'Tag', group = 'Group' },
    }
  end,
  handle = function(state, event)
    -- Emit declarative requests. Only the host validates and sends writes;
    -- state is an immutable snapshot of the last NT acknowledgement.
    if event.type == 'set_connection' then
      return { type = 'set_connection', connection = event.connection }
    elseif event.type == 'set_title' then
      return { type = 'set_title', title = event.title }
    elseif event.type == 'add_expander' then
      return { type = 'add_expander', model = event.model }
    elseif event.type == 'add_aux' or event.type == 'remove_aux' then
      return { type = event.type, bus = event.bus }
    elseif event.type == 'set_aux' then
      return { type = 'set_aux', record = event.record }
    elseif event.type == 'rename_expander' then
      return { type = 'rename_expander', index = event.index, name = event.name }
    elseif event.type == 'move_expander' then
      return { type = 'move_expander', from = event.from, to = event.to }
    end
    error('Unsupported editor action')
  end,
}

-- Read-only notification: state already contains an authoritative NT snapshot.
-- Returning a document cannot write to the device or create an echo loop.
companion.on_change = function(state, change)
  local document = companion.render(state)
  if change.properties.aux_bus and state.properties.aux_bus > 0 then
    document.focus_record = {source = 'aux', id = state.properties.aux_bus}
  elseif change.properties.first_socket then
    document.focus_socket = state.properties.first_socket - 1
  end
  return document
end
return companion
