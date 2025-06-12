return {
    'Exafunction/codeium.vim',
    event = 'BufEnter',
    config = function()
        vim.keymap.set('i', '<C-f>', function()
            return vim.fn['codeium#CycleCompletions'](1)
        end, { expr = true })
        vim.keymap.set('i', '<C-b>', function()
            return vim.fn['codeium#CycleCompletions'](-1)
        end, { expr = true })
        vim.keymap.set('i', '<C-]>', function()
            return vim.fn['codeium#Clear']()
        end, { expr = true })
    end,
}
