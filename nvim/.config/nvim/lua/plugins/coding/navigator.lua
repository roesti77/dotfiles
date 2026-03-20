return {
  'ray-x/navigator.lua',
  dependencies = {
    { 'hrsh7th/nvim-cmp' },
    { 'nvim-treesitter/nvim-treesitter' },
    { 'ray-x/guihua.lua', run = 'cd lua/fzy && make' },
    {
      'ray-x/lsp_signature.nvim',
      event = 'VeryLazy',
      config = function()
        require('lsp_signature').setup()
      end,
    },
  },
  config = function()
    require('navigator').setup {
      lsp_signature_help = true,
      lsp = {
        format_on_save = true,
      },
    }

    -- Monkey-patch navigator's on_filetype to skip ClaudeCode scratch buffers.
    -- The BufEnter autocmd approach doesn't work because navigator resumes
    -- its coroutine after our guard fires. Patching the function itself is reliable.
    local ok, clients = pcall(require, 'navigator.lspclient.clients')
    if ok and clients.on_filetype then
      local orig = clients.on_filetype
      clients.on_filetype = function(...)
        local name = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
        if name:match '%[Claude Code%]' or name:match 'claudecode' then
          return
        end
        return orig(...)
      end
    end

    vim.api.nvim_create_autocmd('FileType', {
      pattern = { 'go' },
      callback = function(ev)
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-i>', ':GoImports<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-b>', ':GoBuild %<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<leader>gr', ':GoRun %<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-t>', ':GoTestPkg<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', '<C-c>', ':GoCoverage -p<CR>', {})
        vim.api.nvim_buf_set_keymap(0, 'n', 'tt', ":lua require('go.alternate').switch(true, '')<CR>", {})
        vim.api.nvim_buf_set_keymap(0, 'n', 'tv', ":lua require('go.alternate').switch(true, 'vsplit')<CR>", {})
        vim.api.nvim_buf_set_keymap(0, 'n', 'th', ":lua require('go.alternate').switch(true, 'split')<CR>", {})
      end,
      group = vim.api.nvim_create_augroup('go_autocommands', { clear = true }),
    })
  end,
}
