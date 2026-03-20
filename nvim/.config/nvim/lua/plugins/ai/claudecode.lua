return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' }, -- optional, aber empfohlen
  opts = {
    -- Server
    auto_start = true,
    log_level = 'warn',

    -- Terminal: snacks (wie dein bisheriges opencode-Setup)
    terminal = {
      provider = 'snacks',
      snacks = {
        auto_insert = true,
        win = {
          -- position = 'right', -- 'left', 'right', 'bottom', 'float'
        },
      },
    },
  },
  keys = {
    { '<C-.>', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude Code', mode = { 'n', 't' } },

    { '<C-h>', '<cmd>wincmd h<cr>', desc = 'Window left', mode = 't' },
    { '<C-j>', '<cmd>wincmd j<cr>', desc = 'Window down', mode = 't' },
    { '<C-k>', '<cmd>wincmd k<cr>', desc = 'Window up', mode = 't' },
    { '<C-l>', '<cmd>wincmd l<cr>', desc = 'Window right', mode = 't' },

    { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Claude: Resume Session' },
    { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Claude: Continue Session' },

    { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Claude: Add current buffer' },
    { '<leader>as', '<cmd>ClaudeCodeSend<cr>', desc = 'Claude: Send selection', mode = 'v' },

    { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Claude: Select Model' },

    { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Claude: Accept Diff' },
    { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Claude: Deny Diff' },

    {
      '<leader>at',
      '<cmd>ClaudeCodeTreeAdd<cr>',
      desc = 'Claude: Add file from tree',
      ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw' },
    },
  },
}
