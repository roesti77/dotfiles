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
      -- Claudes Ink-TUI zeichnet relativ zum Cursor und clearst bei Resize nicht voll,
      -- da bleiben Reste der alten Breite stehen. Der Plugin-Default verstellt die
      -- Terminal-Breite rund um Diffs von selbst -- das abschalten. Absichtliches
      -- Resizen per <C-]> bleibt.
      auto_resize_terminal = false,
    },

    terminal = {
      provider = 'snacks',
      -- Worktree-Workflow: Claude soll im Repo-Root arbeiten, nicht im Buffer-Verzeichnis
      git_repo_cwd = true,
      -- kein snacks_win_opts: der snacks-Default (Float) gibt der Claude-TUI genug
      -- Spalten. Als rechter Split (42%) in einem schon geteilten zellij-Pane blieben
      -- zu wenige uebrig und die TUI rendert zerrissen.
    },
  },
  keys = {
    { '<C-.>', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude Code', mode = { 'n', 't' } },
    -- robuster Toggle auch AUS dem Claude-Terminal heraus: <C-Space> wird von jedem
    -- Terminal uebertragen (im Gegensatz zu <C-.>, das das kitty-Protokoll braucht)
    -- und braucht kein <Esc><Esc>, das sonst in Claudes TUI landet
    { '<C-Space>', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude Code', mode = { 'n', 't' } },
    -- zweiter Weg zum Toggle, auch aus dem <leader>a-Namespace erreichbar
    { '<leader>ai', '<cmd>ClaudeCode<cr>', desc = 'Claude: Toggle sidebar' },
    -- ins Claude-Fenster springen, ohne es zuzuklappen
    { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Claude: Focus window' },
    -- steht die Bruecke? zeigt Server + Verbindung
    { '<leader>a?', '<cmd>ClaudeCodeStatus<cr>', desc = 'Claude: Status' },

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
