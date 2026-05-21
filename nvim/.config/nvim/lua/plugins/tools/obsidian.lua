local vault = '$HOME/Library/Mobile Documents/com~apple~CloudDocs/Second Brain'

local GERMAN_WEEKDAYS = {
  [0] = 'Sonntag',
  [1] = 'Montag',
  [2] = 'Dienstag',
  [3] = 'Mittwoch',
  [4] = 'Donnerstag',
  [5] = 'Freitag',
  [6] = 'Samstag',
}

local function note_time(ctx)
  if ctx and ctx.partial_note and ctx.partial_note.id then
    local y, m, d = tostring(ctx.partial_note.id):match('^(%d%d%d%d)-(%d%d)-(%d%d)$')
    if y then
      return os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
    end
  end
  return os.time()
end

local function format_moment(fmt, t)
  local out = fmt
  out = out:gsub('YYYY', os.date('%Y', t))
  out = out:gsub('MM', os.date('%m', t))
  out = out:gsub('DD', os.date('%d', t))
  out = out:gsub('HH', os.date('%H', t))
  out = out:gsub('mm', os.date('%M', t))
  out = out:gsub('ss', os.date('%S', t))
  out = out:gsub('dddd', GERMAN_WEEKDAYS[tonumber(os.date('%w', t))])
  return out
end

return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  lazy = true,
  ft = 'markdown',
  cmd = { 'Obsidian', 'NewMeeting', 'MoveTo' },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  opts = {
    ui = { enable = false }, -- render-markdown.nvim handles markdown rendering
    legacy_commands = false, -- nur :Obsidian <sub>, keine :ObsidianFoo Aliase
    workspaces = {
      {
        name = 'Second Brain',
        path = vault,
        overrides = {
          notes_subdir = '00_Inbox',
          new_notes_location = 'notes_subdir',
          daily_notes = {
            folder = '00_Inbox',
            date_format = '%Y-%m-%d',
            template = 'T_Daily.md',
          },
          templates = {
            folder = '90_Meta/Templates',
            date_format = '%Y-%m-%d',
            time_format = '%H:%M',
            substitutions = {
              -- {{date}} / {{date:YYYY-MM-DD}} / {{date:YYYY-MM-DD HH:mm}} / {{date:dddd}} ...
              -- Bei Daily-Notes wird das Datum der Note (today/yesterday/tomorrow) genutzt.
              date = function(ctx, suffix)
                local t = note_time(ctx)
                if not suffix or suffix == '' then
                  return os.date('%Y-%m-%d', t)
                end
                return format_moment(suffix, t)
              end,
              time = function(_, suffix)
                local t = os.time()
                if not suffix or suffix == '' then
                  return os.date('%H:%M', t)
                end
                return format_moment(suffix, t)
              end,
            },
          },
        },
      },
    },
  },
  config = function(_, opts)
    require('obsidian').setup(opts)

    -- Top-Level-Ordner die nie als Move-Ziel sinnvoll sind
    local IGNORE_TOPLEVEL = {
      ['90_Meta'] = true,
      ['99_Attachments'] = true,
    }

    -- Rekursiv alle Unterordner sammeln, relativ zum Vault
    local function walk_dirs(abs_root, rel_prefix, out, skip_toplevel)
      for name, ftype in vim.fs.dir(abs_root) do
        if ftype == 'directory' and not name:match('^%.') then
          if not (skip_toplevel and IGNORE_TOPLEVEL[name]) then
            local rel_path = rel_prefix and (rel_prefix .. '/' .. name) or name
            table.insert(out, rel_path)
            walk_dirs(abs_root .. '/' .. name, rel_path, out, false)
          end
        end
      end
    end

    local function list_project_dirs()
      local dirs = {}
      walk_dirs(vault .. '/01_Projects', '01_Projects', dirs, false)
      table.sort(dirs)
      return dirs
    end

    local function list_vault_dirs()
      local dirs = {}
      walk_dirs(vault, nil, dirs, true)
      table.sort(dirs)
      return dirs
    end

    local function new_meeting()
      vim.ui.input({ prompt = 'Meeting-Name: ' }, function(name)
        if not name or name == '' then
          return
        end
        local date = os.date('%Y-%m-%d')
        local filename = date .. '-' .. name:gsub('%s+', '-') .. '.md'

        local choices = { '00_Inbox  (Default — später sortieren)' }
        vim.list_extend(choices, list_project_dirs())

        vim.ui.select(choices, { prompt = 'Wohin?' }, function(choice)
          if not choice then
            return
          end
          local target = choice:match('^00_Inbox') and '00_Inbox' or choice
          local full_path = vault .. '/' .. target .. '/' .. filename
          vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
          vim.cmd('Obsidian template T_Meeting')
        end)
      end)
    end

    local function do_move(target_dir)
      local current = vim.api.nvim_buf_get_name(0)
      if vim.bo.modified then
        vim.cmd('write')
      end

      local filename = vim.fn.fnamemodify(current, ':t')
      local new_rel = target_dir .. '/' .. filename
      local new_abs = vault .. '/' .. new_rel

      if new_abs == current then
        vim.notify('Datei liegt bereits dort', vim.log.levels.INFO)
        return
      end

      vim.fn.mkdir(vault .. '/' .. target_dir, 'p')

      local note = require('obsidian').api.current_note(0)
      if not note then
        vim.notify('Aktueller Buffer ist keine Obsidian-Note', vim.log.levels.WARN)
        return
      end

      -- Direct rename via internal API — :Obsidian rename behält nur den Basename
      -- und ignoriert opts.new_path, deshalb der Low-Level-Call.
      local rename = require('obsidian.lsp.handlers._rename').rename
      local stem = filename:gsub('%.md$', '')
      rename(note, stem, function(_, edit)
        if edit then
          vim.lsp.util.apply_workspace_edit(edit, 'utf-8')
        end
      end, {
        old_path = current,
        new_path = new_abs,
      })
      vim.notify('→ ' .. new_rel, vim.log.levels.INFO)
    end

    local function move_to()
      local current = vim.api.nvim_buf_get_name(0)
      if current == '' or not current:find(vault, 1, true) then
        vim.notify('Aktuelle Datei liegt nicht im Vault', vim.log.levels.WARN)
        return
      end

      local choices = list_vault_dirs()
      table.insert(choices, 1, '+ Neuer Ordner...')

      vim.ui.select(choices, { prompt = 'Verschieben nach: ' }, function(choice)
        if not choice then
          return
        end

        if choice == '+ Neuer Ordner...' then
          vim.ui.input({
            prompt = 'Neuer Ordner (relativ zum Vault): ',
            completion = 'dir',
          }, function(new_dir)
            if not new_dir or new_dir == '' then
              return
            end
            do_move(new_dir)
          end)
        else
          do_move(choice)
        end
      end)
    end

    vim.api.nvim_create_user_command('NewMeeting', new_meeting, {})
    vim.api.nvim_create_user_command('MoveTo', move_to, {})
    vim.keymap.set('n', '<leader>nm', new_meeting, { desc = 'New Meeting (Obsidian)' })
    vim.keymap.set('n', '<leader>nM', move_to, { desc = 'Move Note (PARA, Obsidian)' })
  end,
}
