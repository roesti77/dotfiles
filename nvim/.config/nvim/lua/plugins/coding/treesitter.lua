return {
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  config = function()
    -- Register TOON custom parser
    vim.api.nvim_create_autocmd('User', {
      pattern = 'TSUpdate',
      callback = function()
        require('nvim-treesitter.parsers').toon = {
          install_info = {
            url = 'https://github.com/3swordman/tree-sitter-toon',
            branch = 'master',
          },
        }
      end,
    })

    -- Install parsers
    require('nvim-treesitter').install {
      'lua',
      'python',
      'javascript',
      'typescript',
      'vimdoc',
      'vim',
      'regex',
      'terraform',
      'hcl',
      'sql',
      'dockerfile',
      'toml',
      'json',
      'java',
      'groovy',
      'go',
      'gitignore',
      'graphql',
      'yaml',
      'make',
      'cmake',
      'markdown',
      'markdown_inline',
      'bash',
      'tsx',
      'css',
      'html',
      'php',
      'mermaid',
    }

    -- Enable highlighting for all filetypes with a parser
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    -- Enable treesitter-based indentation
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })

    -- Textobjects
    require('nvim-treesitter-textobjects').setup {
      select = {
        lookahead = true,
        keymaps = {
          ['aa'] = '@parameter.outer',
          ['ia'] = '@parameter.inner',
          ['af'] = '@function.outer',
          ['if'] = '@function.inner',
          ['ac'] = '@class.outer',
          ['ic'] = '@class.inner',
        },
      },
      move = {
        set_jumps = true,
        goto_next_start = {
          [']m'] = '@function.outer',
          [']]'] = '@class.outer',
        },
        goto_next_end = {
          [']M'] = '@function.outer',
          [']['] = '@class.outer',
        },
        goto_previous_start = {
          ['[m'] = '@function.outer',
          ['[['] = '@class.outer',
        },
        goto_previous_end = {
          ['[M'] = '@function.outer',
          ['[]'] = '@class.outer',
        },
      },
      swap = {
        swap_next = {
          ['<leader>a'] = '@parameter.inner',
        },
        swap_previous = {
          ['<leader>A'] = '@parameter.inner',
        },
      },
    }

    -- Incremental selection
    require('nvim-treesitter-textobjects').setup {
      select = {
        lookahead = true,
      },
    }

    -- Incremental selection keymaps
    vim.keymap.set('n', '<c-space>', function()
      require('nvim-treesitter.incremental_selection').init_selection()
    end, { desc = 'Init treesitter selection' })
    vim.keymap.set('v', '<c-space>', function()
      require('nvim-treesitter.incremental_selection').node_incremental()
    end, { desc = 'Increment treesitter selection' })
    vim.keymap.set('v', '<M-space>', function()
      require('nvim-treesitter.incremental_selection').node_decremental()
    end, { desc = 'Decrement treesitter selection' })

    vim.filetype.add { extension = { yml = 'yaml.ansible' }, pattern = { ['.*playbook.*%.yml'] = 'yaml.ansible', ['.*roles.*%.yml'] = 'yaml.ansible', ['.*tasks.*%.yml'] = 'yaml.ansible' } }
    vim.filetype.add { extension = { tf = 'terraform' } }
    vim.filetype.add { extension = { tfvars = 'terraform' } }
    vim.filetype.add { extension = { pipeline = 'groovy' } }
    vim.filetype.add { extension = { multibranch = 'groovy' } }
    vim.filetype.add { extension = { toon = 'toon' } }
  end,
}
