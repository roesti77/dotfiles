-- Fuzzy Finder (files, lsp, etc)
return {
  'nvim-telescope/telescope.nvim',
  -- kein branch = '0.1.x': der Branch ist seit 2024-05 eingefroren und ruft
  -- ts_parsers.ft_to_lang, das nvim 0.12 entfernt hat. Ab v0.2.x nutzt telescope
  -- die Core-Treesitter-API (get_lang). version = '*' folgt dem letzten Release.
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    -- Fuzzy Finder Algorithm which requires local dependencies to be built.
    -- Only load if `make` is available. Make sure you have the system
    -- requirements installed.
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    {
      'nvim-telescope/telescope-file-browser.nvim',
      dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    },
    'nvim-telescope/telescope-ui-select.nvim',

    -- Useful for getting pretty icons, but requires a Nerd Font.
    'nvim-tree/nvim-web-devicons',

    'prochri/telescope-all-recent.nvim',
    'kkharji/sqlite.lua',
    'nvim-telescope/telescope-dap.nvim',
    'nvim-telescope/telescope-project.nvim',
    'lpoto/telescope-docker.nvim',
    {
      'LukasPietzschmann/telescope-tabs',
      config = true,
    },
  },
  config = function()
    local telescope = require 'telescope'
    local actions = require 'telescope.actions'
    local builtin = require 'telescope.builtin'

    require('telescope').setup {
      defaults = {
        mappings = {
          i = {
            ['<C-k>'] = actions.move_selection_previous, -- move to prev result
            ['<C-j>'] = actions.move_selection_next, -- move to next result
            ['<C-l>'] = actions.select_default, -- open file
          },
          n = {
            ['q'] = actions.close,
          },
        },
      },
      pickers = {
        find_files = {
          file_ignore_patterns = { 'node_modules', '.git', '.venv', '.devbox' },
          hidden = true,
        },
        buffers = {
          initial_mode = 'normal',
          sort_lastused = true,
          -- sort_mru = true,
          mappings = {
            n = {
              ['d'] = actions.delete_buffer,
              ['l'] = actions.select_default,
            },
          },
        },
      },
      live_grep = {
        file_ignore_patterns = { 'node_modules', '.git', '.venv', '.devbox' },
        additional_args = function(_)
          return { '--hidden' }
        end,
      },
      path_display = {
        filename_first = {
          reverse_directories = true,
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
        docker = {
          -- These are the default values
          theme = 'ivy',
          binary = 'docker', -- in case you want to use podman or something
          compose_binary = 'docker compose',
          buildx_binary = 'docker buildx',
          machine_binary = 'docker-machine',
          log_level = vim.log.levels.INFO,
          init_term = 'vsplit new', --- 'tabnew', -- "vsplit new", "split new", ...
          -- NOTE: init_term may also be a function that receives
          -- a command, a table of env. variables and cwd as input.
          -- This is intended only for advanced use, in case you want
          -- to send the env. and command to a tmux terminal or floaterm
          -- or something other than a built in terminal.
        },
      },
      git_files = {
        previewer = false,
      },
    }
    require('telescope').load_extension 'project'
    require('telescope').load_extension 'dap'
    require('telescope').load_extension 'docker'
    require('telescope').load_extension 'telescope-tabs'

    -- Enable telescope fzf native, if installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')

    -- Worktrees des Repos auswaehlen. Jeder Worktree lebt in einem eigenen Tab mit
    -- tab-lokalem cwd (:tcd) -- dieselbe Regel wie zsh/bin/wt-open, damit beide
    -- Einstiege denselben Tab treffen und nicht zwei fuer denselben Pfad entstehen.
    -- telescope.entry_display gibt es in v0.2.x nicht mehr, darum eigene Formatierung.
    local function goto_worktree(path)
      for _, handle in ipairs(vim.api.nvim_list_tabpages()) do
        if vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(handle)) == path then
          vim.api.nvim_set_current_tabpage(handle)
          return
        end
      end
      -- VOR dem tabnew pruefen, sonst bleibt bei fehlendem Verzeichnis ein leerer Tab
      -- stehen und :tcd wirft einen Lua-Fehler (E344).
      if vim.fn.isdirectory(path) == 0 then
        vim.notify('wt: Verzeichnis fehlt: ' .. path .. '  (git worktree prune?)', vim.log.levels.WARN)
        return
      end
      vim.cmd 'tabnew'
      local ok, err = pcall(vim.cmd, 'tcd ' .. vim.fn.fnameescape(path))
      if not ok then
        vim.cmd 'tabclose'
        vim.notify('wt: tcd fehlgeschlagen: ' .. tostring(err), vim.log.levels.ERROR)
        return
      end
      vim.cmd 'edit .'
    end

    local function worktree_picker()
      local out = vim.fn.systemlist { 'git', 'worktree', 'list', '--porcelain' }
      if vim.v.shell_error ~= 0 then
        vim.notify('wt: kein git-Repo', vim.log.levels.WARN)
        return
      end

      local all, cur = {}, nil
      for _, line in ipairs(out) do
        local p = line:match '^worktree (.+)$'
        if p then
          cur = { path = p }
          table.insert(all, cur)
        elseif cur then
          local b = line:match '^branch refs/heads/(.+)$'
          if b then
            cur.branch = b
          elseif line == 'detached' then
            cur.branch = '(detached)'
          elseif line:match '^prunable' then
            cur.prunable = true
          end
        end
      end

      -- git listet Worktrees weiter, deren Verzeichnis weg ist (bis `git worktree prune`).
      -- Solche anzubieten hiess: Auswahl -> :tcd -> E344. Also raus, und einmal sagen warum.
      local items, skipped = {}, 0
      for _, it in ipairs(all) do
        if it.prunable or vim.fn.isdirectory(it.path) == 0 then
          skipped = skipped + 1
        else
          table.insert(items, it)
        end
      end
      if skipped > 0 then
        vim.notify(string.format('wt: %d verwaiste Worktree(s) uebersprungen -- git worktree prune', skipped), vim.log.levels.WARN)
      end
      if #items == 0 then
        vim.notify('wt: keine nutzbaren Worktrees', vim.log.levels.WARN)
        return
      end

      for _, it in ipairs(items) do
        local n = #vim.fn.systemlist { 'git', '-C', it.path, 'status', '--porcelain' }
        it.display = string.format('%-30s %-5s %s', it.branch or '?', n > 0 and ('~' .. n) or '', vim.fn.fnamemodify(it.path, ':~'))
      end

      require('telescope.pickers')
        .new({}, {
          prompt_title = 'Worktrees',
          finder = require('telescope.finders').new_table {
            results = items,
            entry_maker = function(e)
              return { value = e, display = e.display, ordinal = (e.branch or '') .. ' ' .. e.path }
            end,
          },
          sorter = require('telescope.config').values.generic_sorter {},
          attach_mappings = function(bufnr)
            actions.select_default:replace(function()
              actions.close(bufnr)
              local entry = require('telescope.actions.state').get_selected_entry()
              if entry then
                goto_worktree(entry.value.path)
              end
            end)
            return true
          end,
        })
        :find()
    end

    vim.keymap.set('n', '<leader>gw', worktree_picker, { desc = 'Search [G]it [W]orktrees' })

    vim.keymap.set('n', '<C-p>', builtin.find_files, {})
    vim.keymap.set('n', '<space>fb', ':Telescope file_browser<CR>')
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
    vim.keymap.set('n', '<leader>?', builtin.oldfiles, { desc = '[?] Find recently opened files' })
    vim.keymap.set('n', '<leader>sb', builtin.buffers, { desc = '[S]earch existing [B]uffers' })
    vim.keymap.set('n', '<leader>sm', builtin.marks, { desc = '[S]earch [M]arks' })
    vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Search [G]it [F]iles' })
    vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = 'Search [G]it [C]ommits' })
    vim.keymap.set('n', '<leader>gcf', builtin.git_bcommits, { desc = 'Search [G]it [C]ommits for current [F]ile' })
    vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Search [G]it [B]ranches' })
    vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'Search [G]it [S]tatus (diff view)' })
    vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    vim.keymap.set('n', '<leader>sx', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]resume' })
    vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
    vim.keymap.set('n', '<leader>tl', ':Telescope telescope-tabs list_tabs<CR>', { desc = '[T]abs [L]ist' })

    vim.keymap.set('n', '<leader>sds', function()
      builtin.lsp_document_symbols {
        symbols = { 'Class', 'Function', 'Method', 'Constructor', 'Interface', 'Module', 'Property' },
      }
    end, { desc = '[S]each LSP document [S]ymbols' })
    vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
    vim.keymap.set('n', '<leader>s/', function()
      builtin.live_grep {
        grep_open_files = true,
        prompt_title = 'Live Grep in Open Files',
      }
    end, { desc = '[S]earch [/] in Open Files' })
    vim.keymap.set('n', '<leader>/', function()
      -- You can pass additional configuration to telescope to change theme, layout, etc.
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })
  end,
}
