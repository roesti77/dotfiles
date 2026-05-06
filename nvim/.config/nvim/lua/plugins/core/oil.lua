return {
  {
    'stevearc/oil.nvim',
    opts = {
      -- Standardmäßig öffnet Oil das Verzeichnis, wenn du einen Ordner öffnest.
      -- Da du Neo-tree hast, kannst du hier 'false' setzen, wenn Oil
      -- NICHT den Standard-Netrw (Dateiexplorer) ersetzen soll.
      default_file_explorer = true,

      columns = {
        'icon',
      },
      keymaps = {
        ['g?'] = 'actions.show_help',
        ['<CR>'] = 'actions.select',
        ['<C-c>'] = 'actions.close',
        ['-'] = 'actions.parent',
        ['_'] = 'actions.open_cwd',
      },
      view_options = {
        show_hidden = true, -- Zeige Punkt-Dateien (.gitignore etc.)
      },
    },
    -- Optional: Ein Shortcut, um Oil manuell zu triggern
    keys = {
      { '-', '<CMD>Oil<CR>', desc = 'Open parent directory with Oil' },
    },
  },
}
