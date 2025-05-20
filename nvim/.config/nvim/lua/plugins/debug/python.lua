return {
  'mfussenegger/nvim-dap-python',
  config = function()
    require('dap-python').setup '~/.virtualenvs/debugpy/bin/python' -- Pfad anpassen!
  end,
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  keys = {
    {
      '<leader>dt',
      function()
        require('dap-python').test_method()
      end,
      desc = 'Debug Python test method',
    },
    {
      '<leader>dC',
      function()
        require('dap-python').test_class()
      end,
      desc = 'Debug Python test class',
    },
  },
}
