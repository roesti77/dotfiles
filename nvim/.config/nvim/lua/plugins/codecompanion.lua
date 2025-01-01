return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("codecompanion").setup({
        model = "ollama",
        endpoint = "http://localhost:11434/api/generate", -- Ollama API-Endpunkt
        model_name = "llama3.2:latest", -- Anpassen an das gewünschte Modell
        context_size = 4096,         -- Kontextgröße
        temperature = 0.7,          -- Kreativität
        max_tokens = 2048,          -- Maximale Token-Anzahl
        language = "de",
        strategies = {
          chat = {
            adapter = "ollama",
          },
          inline = {
            adapter = "ollama",
          },
        },
      })
    end
  }
}

