return {
  'milanglacier/minuet-ai.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'Davidyz/VectorCode',
  },
  config = function()
    local has_vc, vectorcode_config = pcall(require, 'vectorcode.config')
    local vectorcode_cacher = nil
    if has_vc then
      vectorcode_cacher = vectorcode_config.get_cacher_backend()
    end
    local RAG_Context_Window_Size = 8000

    local rag_ignore_ft = { 'yaml', 'json', 'toml', 'terraform', 'hcl', 'helm' }

    require('minuet').setup {
      provider = 'openai_fim_compatible',
      notify = 'warn',
      request_timeout = 5,
      throttle = 1000,
      debounce = 500,
      n_completions = 1,
      context_window = 1024,
      provider_options = {
        openai_fim_compatible = {
          model = 'jolovicdev/qwen2.5-coder-1.5b-lf-fim-heavy',
          end_point = 'http://10.0.10.250:1234/v1/completions',
          stream = false,
          api_key = function()
            local f = io.open(vim.fn.expand '~/.local/secrets/lmstudio', 'r')
            if f then
              local token = f:read '*l'
              f:close()
              return token
            end
            return ''
          end,
          name = 'LM Studio VTRS',
          template = {
            prompt = function(pref, suff, _)
              local prompt_message = ''
              local use_rag = has_vc and vectorcode_cacher and not vim.tbl_contains(rag_ignore_ft, vim.bo.filetype)
              if use_rag then
                for _, file in ipairs(vectorcode_cacher.query_from_cache(0)) do
                  prompt_message = prompt_message .. '<|file_sep|>' .. file.path .. '\n' .. file.document
                end
                prompt_message = vim.fn.strcharpart(prompt_message, 0, RAG_Context_Window_Size)
              end
              return prompt_message .. '<|fim_prefix|>' .. pref .. '<|fim_suffix|>' .. suff .. '<|fim_middle|>'
            end,
            suffix = false,
          },
          optional = {
            max_tokens = 64,
            top_p = 0.95,
            temperature = 0.2,
          },
        },
      },
      enable_predicates = {
        function()
          local filename = vim.fn.expand '%:t'
          if filename:match '^%.env' then
            return false
          end
          if filename:match '%-secret%.yaml$' then
            return false
          end
          if filename:match '^%.env%.' then
            return false
          end
          return true
        end,
      },
      cmp = {
        enable_auto_complete = true,
      },
    }
  end,
}
