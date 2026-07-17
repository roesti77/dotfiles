-- Local diff review loop: read CC-authored changes like a reviewer.
-- diffview.nvim is already pulled in as an octo/gitlab dependency; this spec
-- adds an explicit setup plus keymaps for reviewing the *working tree* and the
-- *current branch vs origin/main* — the two things you look at after each
-- Claude Code run. All keys live under the free <leader>gd (Diffview) prefix.
return {
  'sindrets/diffview.nvim',
  config = function()
    require('diffview').setup {
      enhanced_diff_hl = true,
    }

    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
      wk.add { { '<leader>gd', group = 'Diffview' } }
    end

    local map = vim.keymap.set
    map('n', '<leader>gdd', '<cmd>DiffviewOpen<cr>', { desc = 'Diff: working tree (uncommitted)' })
    map('n', '<leader>gdm', '<cmd>DiffviewOpen origin/main...HEAD<cr>', { desc = 'Diff: branch vs origin/main (review the session)' })
    map('n', '<leader>gdh', '<cmd>DiffviewFileHistory %<cr>', { desc = 'Diff: current file history' })
    map('n', '<leader>gdH', '<cmd>DiffviewFileHistory<cr>', { desc = 'Diff: repo history' })
    map('n', '<leader>gdq', '<cmd>DiffviewClose<cr>', { desc = 'Diff: close' })
  end,
}
