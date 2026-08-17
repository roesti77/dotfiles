return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' }, -- optional, aber empfohlen
  -- mit nur `keys` laedt das Plugin erst beim Tastendruck: der <C-.>-Pfad geht dann,
  -- aber bis dahin gibt es kein ~/.claude/ide/*.lock -- eine unabhaengig gestartete
  -- claude-CLI (zellij-Pane, Shell) findet nvim also nicht. lazy=false macht nvim
  -- ab dem Start auffindbar.
  lazy = false,
  init = function()
    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
      wk.add { { '<leader>a', group = 'AI / Claude Code' } }
    end
  end,
  opts = {
    -- Server: muss beim Start laufen, sonst kein ~/.claude/ide/<port>.lock
    auto_start = true,
    log_level = 'warn',

    -- nach dem Senden einer Selektion direkt im Claude-Fenster weiterschreiben
    focus_after_send = true,

    diff_opts = {
      layout = 'vertical',
    },

    terminal = {
      provider = 'snacks',
      -- Worktree-Workflow: Claude soll im Repo-Root arbeiten, nicht im Buffer-Verzeichnis
      git_repo_cwd = true,
      -- Sidebar rechts wie im review-Layout; per <C-.> / <leader>ai umschaltbar,
      -- also nicht permanent (auto_insert ist Top-Level und schon default true)
      snacks_win_opts = {
        position = 'right',
        width = 0.42,
      },
    },
  },
  keys = {
    { '<C-.>', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude Code', mode = { 'n', 't' } },
    -- zweiter Weg zum Toggle, auch aus dem <leader>a-Namespace erreichbar
    { '<leader>ai', '<cmd>ClaudeCode<cr>', desc = 'Claude: Toggle sidebar' },

    { '<C-h>', '<cmd>wincmd h<cr>', desc = 'Window left', mode = 't' },
    { '<C-j>', '<cmd>wincmd j<cr>', desc = 'Window down', mode = 't' },
    { '<C-k>', '<cmd>wincmd k<cr>', desc = 'Window up', mode = 't' },
    { '<C-l>', '<cmd>wincmd l<cr>', desc = 'Window right', mode = 't' },
    { '<Esc><Esc>', '<C-\\><C-n>', desc = 'Exit terminal mode', mode = 't' },

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
