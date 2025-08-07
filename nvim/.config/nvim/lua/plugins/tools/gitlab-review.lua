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
      config_path = '/Users/robertschneider/.config/gitlab.nvim/',
      discussion_signs = {
        virtual_text = true,
      },
    }

    local wk = require 'which-key'
    wk.register({
      r = {
        name = '+Review',
        x = { gitlab.choose_merge_request, 'Switch Merge Request' },
      },
    }, { prefix = '<leader>' })
  end,
}
