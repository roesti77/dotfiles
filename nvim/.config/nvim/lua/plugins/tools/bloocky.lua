-- Turn a dooing todo into a bloocky time block.
-- bloocky's own dooing integration is read-only and date-based: todos appear in the
-- week header and the day view's "Due this day" section, never in the hour grid.
-- This bridges the gap the plugins leave open. dooing's data is only read.
local function plan_todo_as_block()
  local ok, dstate = pcall(require, 'dooing.state')
  if not ok then
    vim.notify('dooing is not available', vim.log.levels.WARN)
    return
  end
  if type(dstate.todos) ~= 'table' or #dstate.todos == 0 then
    pcall(dstate.load_todos)
  end

  local candidates = {}
  for _, todo in ipairs(dstate.todos or {}) do
    if todo.due_at and not todo.done then
      table.insert(candidates, todo)
    end
  end
  if #candidates == 0 then
    vim.notify('No open todo has a due date yet — set one with H in the dooing window', vim.log.levels.INFO)
    return
  end
  table.sort(candidates, function(a, b)
    return a.due_at < b.due_at
  end)

  vim.ui.select(candidates, {
    prompt = 'Plan which todo?',
    format_item = function(todo)
      local estimate = todo.estimated_hours and (' (≈%gh)'):format(todo.estimated_hours) or ''
      local status = todo.in_progress and '◐ ' or '○ '
      return ('%s  %s%s%s'):format(os.date('%a %d.%m', todo.due_at), status, todo.text, estimate)
    end,
  }, function(todo)
    if not todo then
      return
    end
    vim.ui.input({ prompt = 'Start (HH:MM): ', default = os.date('%H:00', os.time() + 3600) }, function(input)
      if not input or input == '' then
        return
      end
      local hour, minute = input:match '^(%d%d?):(%d%d)$'
      if not hour then
        vim.notify('Expected HH:MM, got ' .. input, vim.log.levels.ERROR)
        return
      end

      local granularity = require('bloocky.config').options.granularity
      local start_min = tonumber(hour) * 60 + tonumber(minute)
      start_min = math.floor(start_min / granularity + 0.5) * granularity
      local duration_min = math.floor((todo.estimated_hours or 1) * 60 + 0.5)

      require('bloocky.state').add_block {
        title = todo.text,
        date = os.date('%Y-%m-%d', todo.due_at),
        start_min = start_min,
        duration_min = duration_min,
      }
      pcall(function()
        require('bloocky.ui').render()
      end)
      vim.notify(('Planned "%s" for %s at %s (%dmin)'):format(todo.text, os.date('%d.%m.', todo.due_at), input, duration_min))
    end)
  end)
end

return {
  'atiladefreitas/bloocky',
  event = 'VeryLazy',
  keys = {
    { '<leader>tP', plan_todo_as_block, desc = 'Plan a dooing todo as a time block' },
  },
  opts = {
    week_start = 'monday',
    -- Read-only: shows dooing todos on their due date, never writes back
    integrations = {
      dooing = { enabled = true },
    },
  },
}
