return {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons', "yavorski/lualine-macro-recording.nvim" },
    config = function()
        require('lualine').setup {
            options = {
                theme = 'material',
                sections = {
                  lualine_c = { "macro_recording", "%S" },
            }
          }
        }
    end
}

