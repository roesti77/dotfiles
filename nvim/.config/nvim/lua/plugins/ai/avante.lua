-- avante spricht beide Seiten direkt an: das LLM-Gateway des Kunden ueber HTTP
-- (in dessen config.yaml als `provider: openai` mit apiBase auf /v1 hinterlegt)
-- und Cursor ueber ACP. Ein CLI dazwischen braucht es fuer keines von beiden.
--
-- Endpoint, Key und Modell stehen nicht in dieser Datei -- das Repo ist
-- oeffentlich und die Konfiguration gehoert dem Kunden. Gelesen wird beim Start
-- aus Continues eigener config.yaml; der Key landet nur in der Prozess-Umgebung
-- dieses nvim.
local continue_yaml = vim.fn.expand '~/.continue/config.yaml'
local continue_entry = 'continue-code'

-- `yq` ist der Name zweier unabhaengiger Programme: die Go-Variante (mikefarah)
-- braucht -o=json, die Python-Variante (kislyuk, auf dem Kundenrechner) kennt
-- das Flag nicht und gibt ohnehin JSON aus. Also beide probieren.
local function continue_model()
  if vim.fn.executable 'yq' == 0 or vim.fn.filereadable(continue_yaml) == 0 then
    return nil
  end
  for _, argv in ipairs { { 'yq', '-o=json', '.', continue_yaml }, { 'yq', '.', continue_yaml } } do
    local out = vim.fn.system(argv)
    if vim.v.shell_error == 0 then
      local ok, parsed = pcall(vim.json.decode, out)
      if ok and type(parsed) == 'table' and type(parsed.models) == 'table' then
        for _, model in ipairs(parsed.models) do
          if model.name == continue_entry or model.model == continue_entry then
            return model
          end
        end
        return nil
      end
    end
  end
  return nil
end

local continue = continue_model()
if continue and continue.apiKey then
  -- avante nimmt hier nur einen Variablennamen oder ein `cmd:`. Der Key geht
  -- darum in die Umgebung dieses Prozesses -- nicht auf die Platte.
  vim.fn.setenv('CONTINUE_API_KEY', continue.apiKey)
end

return {
  'yetone/avante.nvim',
  -- Pflicht laut Doku: laedt das vorkompilierte Binary per curl/tar, oder baut
  -- es mit cargo (`make BUILD_FROM_SOURCE=true`).
  build = 'make',
  event = 'VeryLazy',
  -- niemals '*' -- avante warnt ausdruecklich davor
  version = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    -- optional, aber ohnehin im Stack: Dateiauswahl, Eingabe, Icons
    'nvim-telescope/telescope.nvim',
    'folke/snacks.nvim',
    'nvim-tree/nvim-web-devicons',
  },
  init = function()
    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
      wk.add { { '<leader>a', group = 'AI / Avante' } }
    end
  end,
  opts = {
    -- Kein Default per has('mac'): das trennt die beiden Ubuntu-Rechner nicht.
    -- Stattdessen einmal pro Rechner `:AvanteSwitchProvider --save` -- die Wahl
    -- ueberlebt Neustarts, und ohne Wahl nimmt avante den zuletzt genutzten.
    -- Legacy statt agentic: keine 27 Tool-Definitionen im Request und kein
    -- Reminder-Loop, der eine Chat-Eingabe zu bis zu vier Anfragen macht.
    -- Preis: keine automatisch ausgefuehrten Aenderungen, Vorschlaege kommen
    -- als Diff. Fuer ein Gateway mit engem Limit der tragfaehige Modus.
    mode = 'legacy',
    behaviour = {
      -- haengt sonst den aktuellen Buffer an jeden neuen Chat
      auto_add_current_file = false,
    },
    providers = {
      continue = {
        __inherited_from = 'openai',
        endpoint = continue and continue.apiBase or '',
        model = continue and (continue.model or continue.name) or '',
        api_key_name = 'CONTINUE_API_KEY',
        -- Tools kosten pro Anfrage 28 KB an Definitionen. Ohne sie und ohne den
        -- agentischen Reminder-Loop faellt der Body von 44 KB auf 15 KB.
        -- `disable_tools` gilt nur pro Provider, global warnt avante.
        disable_tools = true,
        -- context_window begrenzt NICHT die ausgehende Groesse: es senkt nur die
        -- Schwelle, ab der avante den Verlauf komprimiert -- und das kostet
        -- zusaetzliche Requests. Ein kleiner Wert ist hier also schaedlich.
        -- Reservierte Antwortgroesse dagegen zaehlen viele Gateways vorab aufs
        -- Minutenbudget, die bleibt klein.
        extra_request_body = {
          max_completion_tokens = 4096,
        },
      },
    },
    -- Skills und Agenten aus ~/.claude/ als `#name` im Chat. Siehe
    -- lua/avante_harness.lua -- laeuft ohne Claude Code, mit jedem Provider.
    -- Der eingebaute Auswaehler ist vim.ui.select; telescope liegt ohnehin im
    -- Stack und macht @file brauchbar.
    file_selector = { provider = 'telescope' },
    shortcuts = require('avante_harness').shortcuts(),
    acp_providers = {
      -- Cursors CLI heisst `agent` und spricht ACP mit dem Unterbefehl `acp`.
      cursor = {
        command = 'agent',
        args = { 'acp' },
      },
    },
  },
  -- Nur, was avante nicht selbst setzt: ask/edit/toggle bringt es als
  -- <leader>aa/ae/at schon mit (event = 'VeryLazy' laedt es rechtzeitig).
  keys = {
    { '<leader>ac', '<cmd>AvanteChat<cr>', desc = 'AI: Chat' },
    { '<leader>ap', '<cmd>AvanteSwitchProvider<cr>', desc = 'AI: Switch provider' },
    { '<leader>am', '<cmd>AvanteModels<cr>', desc = 'AI: Select model' },
    { '<C-.>', '<cmd>AvanteToggle<cr>', desc = 'AI: Toggle sidebar', mode = { 'n', 'v' } },
  },
}
