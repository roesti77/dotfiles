return {
  'ThePrimeagen/99',
  -- Telescope powers the model/provider pickers; nvim-cmp provides the
  -- `#` (rules) and `@` (files) completion source.
  dependencies = {
    'nvim-telescope/telescope.nvim',
    'hrsh7th/nvim-cmp',
  },
  config = function()
    local _99 = require '99'

    _99.setup {
      -- `claude` CLI is already on PATH (used by claudecode.nvim too).
      -- Swap to _99.Providers.OpenCodeProvider to drive `opencode` instead.
      provider = _99.Providers.ClaudeCodeProvider,
      completion = {
        source = 'cmp', -- matches the nvim-cmp setup in coding/autocompletion.lua
      },
    }

    -- `<leader>9*` namespace is free (AI lives on `<leader>a*` / opencode on <C-a>).
    vim.keymap.set('v', '<leader>9v', _99.visual, { desc = '99: Replace selection with AI' })
    vim.keymap.set('n', '<leader>9s', _99.search, { desc = '99: Search project with AI' })
    vim.keymap.set('n', '<leader>9o', _99.open, { desc = '99: Open recent interactions' })
    vim.keymap.set('n', '<leader>9p', _99.select_provider, { desc = '99: Select provider' })
    vim.keymap.set('n', '<leader>9m', _99.select_model, { desc = '99: Select model' })
    vim.keymap.set('n', '<leader>9x', _99.stop_all_requests, { desc = '99: Stop all requests' })
    vim.keymap.set('n', '<leader>9l', _99.view_logs, { desc = '99: View logs' })
  end,
}
