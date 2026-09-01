return {
  'harrisoncramer/gitlab.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'nvim-lua/plenary.nvim',
    'sindrets/diffview.nvim',
    'stevearc/dressing.nvim',
    'nvim-tree/nvim-web-devicons',
    'folke/which-key.nvim',
  },
  build = function()
    require('gitlab.server').build(true)
  end,
  config = function()
    local gitlab = require 'gitlab'
    gitlab.setup {
      config_path = vim.fn.expand '~/.config/gitlab.nvim/',
      discussion_signs = {
        virtual_text = true,
      },
    }

    -- <leader>rn gehoert LSP-Rename, deshalb hier ausgespart.
    -- Funktionsnamen gegen die installierte Version geprueft (lua/gitlab/init.lua).
    local wk = require 'which-key'
    wk.add {
      { '<leader>r', group = 'Review (GitLab MR)' },

      -- MR waehlen und ansehen
      { '<leader>rx', gitlab.choose_merge_request, desc = 'MR auswaehlen' },
      { '<leader>rs', gitlab.summary, desc = 'MR-Beschreibung' },
      { '<leader>rb', gitlab.open_in_browser, desc = 'MR im Browser' },

      -- Review: Diff-Ansicht auf/zu, Diskussionen daneben
      { '<leader>rr', gitlab.review, desc = 'Review starten' },
      { '<leader>rq', gitlab.close_review, desc = 'Review schliessen' },
      { '<leader>rd', gitlab.toggle_discussions, desc = 'Diskussionen ein/aus' },

      -- Kommentieren; visuell ausgewaehlte Zeilen werden zum Multiline-Kommentar
      { '<leader>rc', gitlab.create_comment, desc = 'Kommentar' },
      { '<leader>rc', gitlab.create_multiline_comment, desc = 'Kommentar (Auswahl)', mode = 'v' },
      { '<leader>ri', gitlab.create_comment_suggestion, desc = 'Suggestion (Auswahl)', mode = 'v' },

      -- Drafts: mehrere Anmerkungen sammeln, dann gemeinsam veroeffentlichen
      { '<leader>rD', gitlab.toggle_draft_mode, desc = 'Draft-Modus' },
      { '<leader>rp', gitlab.publish_all_drafts, desc = 'Drafts veroeffentlichen' },

      -- Verdikt. GitLab kennt kein request-changes, nur approve/revoke.
      { '<leader>ra', gitlab.approve, desc = 'Approve' },
      { '<leader>rA', gitlab.revoke, desc = 'Approve zuruecknehmen' },

      -- Anlegen und Pipeline
      { '<leader>rM', gitlab.create_mr, desc = 'MR anlegen' },
      { '<leader>rP', gitlab.pipeline, desc = 'Pipeline' },
    }
  end,
}
