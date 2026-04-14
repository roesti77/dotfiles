return {
  name = 'nvim.undotree',
  dir = vim.fn.expand '$VIMRUNTIME/pack/dist/opt/nvim.undotree',
  cmd = 'Undotree',
  keys = {
    { '<leader>U', '<cmd>Undotree<cr>', desc = 'Undotree' },
  },
}
