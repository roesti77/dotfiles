return {
  'simrat39/symbols-outline.nvim',
  keys = {
    { '<leader>O', '<cmd>SymbolsOutline<CR>', desc = '[S]ymbols Outline Toggle' },
    { '<leader>so', '<cmd>SymbolsOutline<CR>', desc = '[S]ymbols [O]utline Toggle' },
    {
      '<leader>ss',
      function()
        require('telescope.builtin').lsp_document_symbols {
          symbols = { 'Class', 'Function', 'Method', 'Constructor', 'Interface', 'Module', 'Struct', 'Enum' },
        }
      end,
      desc = '[S]earch Document [S]ymbols',
    },
  },
  config = function()
    require('symbols-outline').setup {
      width = 30,
      autofold_depth = 1,
      auto_preview = true,
      position = 'right',
      show_numbers = true,
      show_relative_numbers = true,
      symbol_blacklist = { 'Variable', 'String', 'Number' },
      keymaps = {
        close = { '<Esc>', 'q' },
        goto_location = '<Cr>',
        focus_location = 'o',
        hover_symbol = '<C-space>',
        toggle_preview = 'K',
        rename_symbol = 'r',
        code_actions = 'a',
      },
    }
    -- falls du sicher gehen willst, dass <leader>o frei ist:
    pcall(vim.keymap.del, 'n', '<leader>o')
  end,
}
