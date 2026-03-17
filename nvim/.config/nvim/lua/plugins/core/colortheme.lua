return {
  'catppuccin/nvim',
  lazy = false,
  name = 'catppuccin',
  priority = 1000,
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha', -- oder 'latte', 'frappe', 'macchiato'
      integrations = {
        cmp = true,
        nvimtree = true,
        treesitter = true,
        telescope = true,
      },
    }
  end,
  init = function()
    vim.cmd 'colorscheme catppuccin'
  end,
}
