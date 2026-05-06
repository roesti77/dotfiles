return {
  'AlexandrosAlexiou/kotlin.nvim',
  ft = { 'kotlin' },
  dependencies = {
    'williamboman/mason.nvim',
    'williamboman/mason-lspconfig.nvim',
    'stevearc/oil.nvim',
    -- 'folke/trouble.nvim', -- optional, nur für :KotlinSymbols / :KotlinWorkspaceSymbols
  },
  config = function()
    require('kotlin').setup {
      root_markers = {
        'gradlew',
        'settings.gradle.kts',
        'settings.gradle',
        'build.gradle.kts',
        '.git',
      },
      jvm_args = { '-Xmx4g' },
      inlay_hints = { enabled = true },
    }
  end,
}
