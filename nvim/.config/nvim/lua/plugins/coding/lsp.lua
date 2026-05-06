return { -- LSP Configuration & Plugins
  'neovim/nvim-lspconfig',
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'b0o/schemastore.nvim',
    {
      'j-hui/fidget.nvim',
      tag = 'v1.4.0',
      opts = {
        progress = {
          display = {
            done_icon = '✓',
          },
        },
        notification = {
          window = {
            winblend = 0,
          },
        },
      },
    },
  },
  config = function()
    local original_show_message = vim.lsp.handlers['window/showMessage']
    vim.lsp.handlers['window/showMessage'] = function(err, result, ctx, config)
      if ctx and ctx.client_id then
        local client = vim.lsp.get_client_by_id(ctx.client_id)
        if client and client.name == 'terraformls' and result and result.message and result.message:match 'single file' then
          return
        end
      end
      original_show_message(err, result, ctx, config)
    end

    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
        map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
        map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
        map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        map('K', vim.lsp.buf.hover, 'Hover Documentation')
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        map('gh', vim.lsp.buf.hover, 'Show hover information')
        map('gH', function()
          vim.diagnostic.open_float(0, { scope = 'cursor' })
        end, 'Show line diagnostics')

        map('gR', function()
          require('telescope.builtin').lsp_references {
            show_line = true,
            include_declaration = true,
            trim_text = true,
          }
        end, 'Show detailed references')

        map('gU', function()
          require('telescope.builtin').lsp_incoming_calls {
            show_line = true,
            layout_strategy = 'vertical',
            layout_config = { width = 0.9, height = 0.9 },
          }
        end, 'Show incoming calls/usages')

        map('gO', function()
          require('telescope.builtin').lsp_document_symbols {
            symbols = {
              'Class',
              'Function',
              'Method',
              'Constructor',
              'Interface',
              'Module',
              'Struct',
              'Enum',
            },
            symbol_width = 50,
          }
        end, 'Show document symbols')

        map('gS', function()
          require('telescope.builtin').lsp_dynamic_workspace_symbols {
            symbol_type = { 'class', 'function', 'method' },
            show_line = true,
            ignore_filename = false,
          }
        end, 'Search workspace symbols')

        map('gi', function()
          require('telescope.builtin').lsp_implementations {
            show_line = true,
            trim_text = true,
            layout_strategy = 'vertical',
            layout_config = { width = 0.9, height = 0.9 },
          }
        end, 'Show implementations with details')

        map('[d', vim.diagnostic.goto_prev, 'Go to previous diagnostic')
        map(']d', vim.diagnostic.goto_next, 'Go to next diagnostic')
        map('<leader>q', vim.diagnostic.setloclist, 'Open diagnostics quicklist')

        map('<leader>fc', function()
          require('telescope.builtin').grep_string {
            prompt_title = '🔍 Find Code References',
            search = vim.fn.input 'Search Code: ',
            use_regex = true,
            additional_args = { '-i' },
          }
        end, 'Find Code References')

        map('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
        map('<leader>wd', require('telescope.builtin').diagnostics, '[W]orkspace [D]iagnostics')
        map('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
        map('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
        map('<leader>wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, '[W]orkspace [L]ist Folders')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('cmp_nvim_lsp').default_capabilities())

    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            workspace = {
              checkThirdParty = false,
              library = {
                '${3rd}/luv/library',
                unpack(vim.api.nvim_get_runtime_file('', true)),
              },
            },
            completion = {
              callSnippet = 'Replace',
            },
            telemetry = { enable = false },
            diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
      pylsp = {
        settings = {
          pylsp = {
            plugins = {
              pyflakes = { enabled = false },
              pycodestyle = { enabled = false },
              autopep8 = { enabled = false },
              yapf = { enabled = false },
              mccabe = { enabled = false },
              pylsp_mypy = { enabled = false },
              pylsp_black = { enabled = false },
              pylsp_isort = { enabled = false },
            },
          },
        },
      },
      ruff = {
        commands = {
          RuffAutofix = {
            function()
              vim.lsp.buf.execute_command {
                command = 'ruff.applyAutofix',
                arguments = {
                  { uri = vim.uri_from_bufnr(0) },
                },
              }
            end,
            description = 'Ruff: Fix all auto-fixable problems',
          },
          RuffOrganizeImports = {
            function()
              vim.lsp.buf.execute_command {
                command = 'ruff.applyOrganizeImports',
                arguments = {
                  { uri = vim.uri_from_bufnr(0) },
                },
              }
            end,
            description = 'Ruff: Format imports',
          },
        },
      },
      jsonls = {
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      },
      sqlls = {},
      terraformls = {
        init_options = {
          ignoreSingleFileWarning = true,
          experimentalFeatures = {
            validateOnSave = true,
            prefillRequiredFields = true,
          },
        },
        settings = {
          ['terraform-ls'] = {
            terraformExecPath = vim.fn.exepath 'tofu',
          },
        },
      },
      ansiblels = {},
      yamlls = {
        settings = {
          yaml = {
            schemaStore = { enable = false, url = '' },
            schemas = require('schemastore').yaml.schemas(),
          },
        },
      },
      bashls = {},
      dockerls = {},
      docker_compose_language_service = {},
      intelephense = {
        settings = {
          intelephense = {
            files = {
              maxSize = 5000000,
            },
          },
        },
      },
    }

    require('mason').setup()

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua',
      'intelephense',
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
        kotlin_lsp = function() end,
      },
    }
  end,
}
