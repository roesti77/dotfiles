return {
  'milanglacier/minuet-ai.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
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
            prompt = function(context_before_cursor, context_after_cursor)
              return '<|fim_prefix|>' .. context_before_cursor .. '<|fim_suffix|>' .. context_after_cursor .. '<|fim_middle|>'
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
      cmp = {
        enable_auto_complete = true,
      },
    }
  end,
}
