return {
  'rcarriga/nvim-dap-ui',
  config = true,
  keys = {
    {
      '<leader>du',
      function()
        require('dapui').toggle {}
      end,
      desc = 'Dap UI',
    },
    {
      '<leader>dr',
      function()
        require('dapui').close()
        vim.cmd('sleep 100m')
        require('dapui').open()
      end,
      desc = 'Reset Dap UI layout',
    },
  },
  dependencies = {
    'jay-babu/mason-nvim-dap.nvim',
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
  },
}
