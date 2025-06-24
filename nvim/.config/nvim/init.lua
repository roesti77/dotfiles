require 'core.options'
require 'core.keymaps'

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
    if vim.v.shell_error ~= 0 then
        error('Error cloning lazy.nvim:\n' .. out)
    end
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
    --- Core
    require 'plugins.core.colortheme',
    require 'plugins.core.neo-tree',
    require 'plugins.core.which-key',
    require 'plugins.core.bufferline',
    require 'plugins.core.lualine',
    require 'plugins.core.telescope',
    require 'plugins.core.noice',
    require 'plugins.core.gitsigns',
    require 'plugins.core.git-stuff',
    require 'plugins.core.git-blame',
    require 'plugins.core.fugitive',
    require 'plugins.core.auto-session',
    require 'plugins.core.autopairs',
    require 'plugins.core.harpoon',
    require 'plugins.core.web-dev-icons',
    require 'plugins.core.ufo',
    require 'plugins.core.zenmode',
    require 'plugins.core.snacks',
    require 'plugins.core.todo-comments',
    require 'plugins.core.zellij',
    require 'plugins.core.surround',
    require 'plugins.core.lazydocker',
    --- AI
    require 'plugins.ai.avante',
    require 'plugins.ai.codeium',
    --- Coding
    require 'plugins.coding.treesitter',
    require 'plugins.coding.lsp',
    require 'plugins.coding.autocompletion',
    require 'plugins.coding.cmp-cmdline',
    require 'plugins.coding.none-ls',
    require 'plugins.coding.navigator',
    require 'plugins.coding.trouble',
    require 'plugins.coding.test',
    require 'plugins.coding.database',
    require 'plugins.coding.outline',
    --- Coding Languages
    require 'plugins.coding-languages.go',
    require 'plugins.coding-languages.taskfile',
    require 'plugins.coding-languages.markdown',
    require 'plugins.coding-languages.yaml-companion',
    require 'plugins.coding-languages.jinja',
    --- Debug
    require 'plugins.debug.dap',
    require 'plugins.debug.dap-ui',
    require 'plugins.debug.virtual-text',
    require 'plugins.debug.go',
    require 'plugins.debug.python',
    --- Tools
    require 'plugins.tools.codesnap',
    require 'plugins.tools.obsidian',
}

require 'core.completition'
