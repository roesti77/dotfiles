return {
    'epwalsh/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = 'markdown',
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre path/to/my-vault/*.md",
    --   "BufNewFile path/to/my-vault/*.md",
    -- },
    dependencies = {
        -- Required.
        'nvim-lua/plenary.nvim',

        -- see below for full list of optional dependencies 👇
    },
    opts = {
        -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:

        workspaces = {
            {
                name = 'work',
                path = '/Users/robertschneider/repos/davitec-intern/knowledge-base-dv',
                overrides = {
                    templates = {
                        folder = '_Pool/Vorlagen',
                    },
                },
            },
        },

        callbacks = {
            -- Runs right before writing the buffer for a note.
            ---@param client obsidian.Client
            ---@param note obsidian.Note
            ---@diagnostic disable-next-line: unused-local
            pre_write_note = function(client, note)
                note:add_field('date modified', os.date())
            end,
        },

        -- see below for full list of options 👇
    },
}
