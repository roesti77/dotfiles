-- Set lualine as statusline
return {
  'nvim-lualine/lualine.nvim',
  config = function()
    -- Adapted from: https://github.com/nvim-lualine/lualine.nvim/blob/master/lua/lualine/themes/onedark.lua
    local colors = {
      blue = '#61afef',
      green = '#98c379',
      purple = '#c678dd',
      cyan = '#56b6c2',
      red1 = '#e06c75',
      red2 = '#be5046',
      yellow = '#e5c07b',
      fg = '#abb2bf',
      bg = '#282c34',
      gray1 = '#828997',
      gray2 = '#2c323c',
      gray3 = '#3e4452',
    }

    local onedark_theme = {
      normal = {
        a = { fg = colors.bg, bg = colors.green, gui = 'bold' },
        b = { fg = colors.fg, bg = colors.gray3 },
        c = { fg = colors.fg, bg = colors.gray2 },
      },
      command = { a = { fg = colors.bg, bg = colors.yellow, gui = 'bold' } },
      insert = { a = { fg = colors.bg, bg = colors.blue, gui = 'bold' } },
      visual = { a = { fg = colors.bg, bg = colors.purple, gui = 'bold' } },
      terminal = { a = { fg = colors.bg, bg = colors.cyan, gui = 'bold' } },
      replace = { a = { fg = colors.bg, bg = colors.red1, gui = 'bold' } },
      inactive = {
        a = { fg = colors.gray1, bg = colors.bg, gui = 'bold' },
        b = { fg = colors.gray1, bg = colors.bg },
        c = { fg = colors.gray1, bg = colors.gray2 },
      },
    }

    -- Import color theme based on environment variable NVIM_THEME
    local env_var_nvim_theme = os.getenv 'NVIM_THEME' or 'catppuccin'

    -- Define a table of themes
    local themes = {
      onedark = onedark_theme,
      catppuccin = catppuccin,
    }

    local mode = {
      'mode',
      fmt = function(str)
        return ' ' .. str
      end,
    }

    local filename = {
      'filename',
      file_status = true,
      path = 0,
    }

    local hide_in_width = function()
      return vim.fn.winwidth(0) > 100
    end

    local diagnostics = {
      'diagnostics',
      sources = { 'nvim_diagnostic' },
      sections = { 'error', 'warn' },
      symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
      colored = false,
      update_in_insert = false,
      always_visible = false,
      cond = hide_in_width,
    }

    local diff = {
      'diff',
      colored = false,
      symbols = { added = ' ', modified = ' ', removed = ' ' },
      cond = hide_in_width,
    }

    local minuet_status = {
      require 'minuet.lualine',
      display_name = 'model',
      display_on_idle = false,
    }

    local trouble = require 'trouble'
    local symbols = trouble.statusline {
      mode = 'lsp_document_symbols',
      groups = {},
      title = false,
      filter = { range = true },
      format = '{kind_icon}{symbol.name:Normal}',
      hl_group = 'lualine_c_normal',
    }

    local recorder = require 'recorder'

    require('lualine').setup {
      options = {
        icons_enabled = true,
        theme = themes[env_var_nvim_theme],
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
        disabled_filetypes = { 'alpha', 'neo-tree' },
        always_divide_middle = true,
      },
      sections = {
        lualine_a = { mode },
        lualine_b = { 'branch' },
        lualine_c = { filename, { symbols.get, cond = symbols.has } },
        lualine_x = {
          { recorder.displaySlots, color = { fg = colors.yellow } },
          { recorder.recordingStatus, color = { fg = colors.red1 } },
          diagnostics,
          diff,
          minuet_status,
          { 'encoding', cond = hide_in_width },
          { 'filetype', cond = hide_in_width },
        },
        lualine_y = { 'location' },
        lualine_z = { 'progress' },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { { 'filename', path = 1 } },
        lualine_x = { { 'location', padding = 0 } },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      extensions = { 'fugitive' },
    }
  end,
}
