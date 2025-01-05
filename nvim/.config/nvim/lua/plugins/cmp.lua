return {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp', -- LSP-Quelle für nvim-cmp
    'hrsh7th/cmp-buffer', -- Buffer-Quelle
    'hrsh7th/cmp-path', -- Dateipfad-Vervollständigung
    'hrsh7th/cmp-cmdline', -- Cmdline-Vervollständigung
    'L3MON4D3/LuaSnip', -- Snippet-Engine
    'saadparwaiz1/cmp_luasnip', -- Snippet-Integration für nvim-cmp
  },
  opts = function()
    local cmp = require('cmp')
    local luasnip = require('luasnip')

    return {
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body) -- Für Snippet-Erweiterungen
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ['<C-Space>'] = cmp.mapping.complete(), -- Trigger Vervollständigung
        ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Auswahl bestätigen
        ['<Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { 'i', 's' }),
        ['<S-Tab>'] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { 'i', 's' }),
      }),
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
      }, {
        { name = 'buffer' },
        { name = 'path' },
      }),
    }
  end,
}

