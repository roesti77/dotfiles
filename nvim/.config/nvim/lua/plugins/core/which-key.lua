return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts_extend = { "spec", "disable.ft", "disable.bt" },
  opts = {
    icons = {
      group = vim.g.icons_enabled ~= false and "" or "+",
      rules = false,
      separator = "-",
    },
  },
  config = function()
    local wk = require "which-key"
    wk.add {
      { "<leader>gh", "<cmd>Octo<cr>", desc = "GitHub" },
    }
  end,
}
