return {
  'leoluz/nvim-dap-go',
  config = true,
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  keys = {
    {
      '<leader>dt',
      function()
        require('dap-go').debug_test()
      end,
      desc = 'Debug test',
    },
  },
}
