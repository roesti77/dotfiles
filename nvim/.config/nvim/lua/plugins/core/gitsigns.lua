return {
  'lewis6991/gitsigns.nvim',
  config = function()
    require('gitsigns').setup {
      -- Maps buffer-lokal, damit sie nur dort existieren wo gitsigns wirklich laeuft
      on_attach = function(bufnr)
        local gs = require 'gitsigns'
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- Hunk-Navigation. In einem echten Diff behaelt ]c/[c die eingebaute Bedeutung.
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal { ']c', bang = true }
          else
            gs.nav_hunk 'next'
          end
        end, 'Naechster Hunk')
        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal { '[c', bang = true }
          else
            gs.nav_hunk 'prev'
          end
        end, 'Voriger Hunk')

        -- Hunk uebernehmen/verwerfen, visuell auf die Auswahl begrenzt
        map('n', '<leader>ga', gs.stage_hunk, 'Hunk stagen')
        map('n', '<leader>gr', gs.reset_hunk, 'Hunk verwerfen')
        map('v', '<leader>ga', function()
          gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'Auswahl stagen')
        map('v', '<leader>gr', function()
          gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, 'Auswahl verwerfen')
        map('n', '<leader>gu', gs.undo_stage_hunk, 'Stage ruecknehmen')

        -- ganzer Buffer
        map('n', '<leader>gA', gs.stage_buffer, 'Buffer stagen')
        map('n', '<leader>gR', gs.reset_buffer, 'Buffer verwerfen')

        -- ansehen
        map('n', '<leader>gl', function()
          gs.blame_line { full = true }
        end, 'Blame dieser Zeile')
        map('n', '<leader>gD', function()
          gs.diffthis '~'
        end, 'Diff gegen HEAD~')
      end,
    }

    vim.keymap.set('n', '<leader>gp', ':Gitsigns preview_hunk<CR>', {})
    vim.keymap.set('n', '<leader>gt', ':Gitsigns toggle_current_line_blame<CR>', {})
  end,
}
