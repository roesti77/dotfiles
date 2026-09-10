return {
  'MeanderingProgrammer/render-markdown.nvim',
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
  -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    -- Der CodeCompanion-Chat ist Markdown, hat aber den Filetype 'codecompanion'
    -- und lief deshalb ungerendert durch: Rollen-Header als rohe ##-Zeilen,
    -- Codebloecke als Backticks. Mit aufgenommen trennt der Renderer Frage und
    -- Antwort sichtbar. Markdown-Dateien selbst aendern sich dadurch nicht.
    file_types = { 'markdown', 'codecompanion' },
  },
}
