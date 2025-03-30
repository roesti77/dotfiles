return {
  'folke/noice.nvim',
  event = 'VeryLazy',
  dependencies = {
    'MunifTanjim/nui.nvim',
    'rcarriga/nvim-notify',
  },
  config = function()
    require('notify').setup {
      stages = 'fade',
      render = 'default',
      timeout = 3000,
      max_width = 80,
      background_colour = '#000000',
    }

    vim.notify = require 'notify'
    require('noice').setup {
      notify = {
        enabled = true,
      },
    }

    vim.keymap.set('n', '<leader>m', '<cmd>Noice telescope<cr>', { desc = 'Noice: Messages via Telescope' })
  end,
}
