return {
  'pwntester/octo.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'sindrets/diffview.nvim',
    'stevearc/dressing.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  lazy = false,
  config = function()
    require('octo').setup {
      enable_builtin = true,
      use_local_fs = true,
      default_to_projects_v2 = true,
      default_merge_method = 'squash',
      picker = 'telescope',
    }

    vim.treesitter.language.register('markdown', 'octo')
  end,
}
