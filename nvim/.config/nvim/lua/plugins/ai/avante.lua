return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  lazy = false,
  version = false, -- set this if you want to always pull the latest change
  opts = {
    -- Add the Ollama provider configuration here
    provider = "ollama", -- Use the Ollama provider
    vendors = {
      ollama = {
        __inherited_from = "openai", -- Inherit general OpenAI settings
        api_key_name = "", -- No API key needed for local Ollama server
        endpoint = "http://127.0.0.1:11434/v1", -- Local Ollama endpoint
        model = "llama3.2:1b", -- Use the desired model: qwen2.5-coder:14b
      },
    },
    behaviour = {
      auto_suggestions = false, -- Optional: disable auto suggestions
    },
    mappings = {
      suggestion = {
        accept = "<M-l>",
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
    },
  },
  build = "make", -- build command if you need it
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- The below dependencies are optional
    "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
    "zbirenbaum/copilot.lua", -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
  },
}
