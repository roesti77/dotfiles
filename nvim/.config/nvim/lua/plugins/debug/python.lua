return {
  'mfussenegger/nvim-dap-python',
  config = function()
    local venv = vim.fn.expand '~/.virtualenvs/debugpy/bin/python'
    require('dap-python').setup(vim.fn.executable(venv) == 1 and venv or 'python3')
  end,
  dependencies = {
    'mfussenegger/nvim-dap',
  },
  keys = {
    {
      '<leader>dm',
      function()
        require('dap-python').test_method()
      end,
      desc = 'Debug Python test method',
    },
    {
      '<leader>dM',
      function()
        require('dap-python').test_class()
      end,
      desc = 'Debug Python test class',
    },
  },
}
