return {
  'ray-x/navigator.lua',
  dependencies = {
    { 'hrsh7th/nvim-cmp' },
    { 'nvim-treesitter/nvim-treesitter' },
    { 'ray-x/guihua.lua', run = 'cd lua/fzy && make' },
    {
      'ray-x/lsp_signature.nvim', -- Show function signature when you type
      event = 'VeryLazy',
      config = function()
        require('lsp_signature').setup()
      end,
    },
  },
  config = function()
    require('navigator').setup {
      lsp_signature_help = true, -- enable ray-x/lsp_signature
      lsp = { format_on_save = true },
    }

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'go' },
      callback = function(ev)
        -- CTRL/control keymaps
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-i>', ':GoImports<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-b>', ':GoBuild %<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<leader>gr', ':GoRun %<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-t>', ':GoTestPkg<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-c>', ':GoCoverage -p<CR>', {})

        -- Opens test files
        vim.api.nvim_buf_set_keymap(0, 'n', 'tt', ":lua require('go.alternate').switch(true, '')<CR>", {}) -- Test
        vim.api.nvim_buf_set_keymap(0, 'n', 'tv', ":lua require('go.alternate').switch(true, 'vsplit')<CR>", {}) -- Test Vertical
        vim.api.nvim_buf_set_keymap(0, 'n', 'th', ":lua require('go.alternate').switch(true, 'split')<CR>", {}) -- Test Split
      end,
      group = vim.api.nvim_create_augroup('go_autocommands', { clear = true }),
    })
  end,
}
