return {
  'huggingface/llm.nvim',
  opts = {
    providers = {
      ollama = {
        url = 'http://localhost:11434', -- Adresse des Ollama-Servers
        models = {
          default = 'codellama:7b', -- Code-optimiertes Modell, ggf. anpassen
        },
      },
    },
    default_provider = 'ollama', -- Standardmäßig Ollama verwenden
    keymaps = {
      submit = '<C-Enter>', -- Zum Absenden eines Prompts
      complete = '<Tab>',   -- Zum Auto-Completen
    },
  }
}
