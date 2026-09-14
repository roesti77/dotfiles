-- Continue als dritter Chat-Adapter. Anders als claude_code und cursor_cli kein
-- ACP-Preset: Continues CLI (`cn`) kennt keinen ACP-Modus. Angesprochen wird der
-- OpenAI-kompatible Endpoint, auf den die apiBase des Modells zeigt -- hier ein
-- LLM-Gateway.
--
-- Endpoint, Key und Modell-ID stehen bewusst NICHT in dieser Datei: sie kommen
-- aus Continues eigener config.yaml ausserhalb des Repos. Das Repo ist
-- oeffentlich und die Konfiguration dahinter gehoert dem Kunden -- getrackt sind
-- darum nur Pfad und Eintragsname.
local continue_config = {
  path = vim.fn.expand '~/.continue/config.yaml',
  -- Welcher models-Eintrag gilt. Verglichen wird gegen `name` und `model`, damit
  -- beide Schreibweisen der Datei treffen.
  entry = 'continue-code',
}

-- Gelesen wird per yq, statt eine YAML-Bibliothek nach nvim zu holen. Das
-- Ergebnis bleibt im Speicher und wird nie irgendwo hingeschrieben.
local continue_entry, continue_failed

-- `yq` ist der Name zweier unabhaengiger Programme: die Go-Variante (mikefarah,
-- via Homebrew) braucht -o=json, die Python-Variante (kislyuk, in vielen
-- Distributionen) kennt das Flag nicht und gibt ohnehin JSON aus. Welche auf
-- einem Rechner liegt, ist von hier aus nicht feststellbar -- also beide
-- Aufrufe probieren und den ersten nehmen, der verwertbares JSON liefert.
local continue_last_error = ''

local function continue_json()
  for _, argv in ipairs {
    { 'yq', '-o=json', '.', continue_config.path },
    { 'yq', '.', continue_config.path },
  } do
    local out = vim.fn.system(argv)
    if vim.v.shell_error == 0 then
      local ok, parsed = pcall(vim.json.decode, out)
      if ok and type(parsed) == 'table' then
        return parsed
      end
      continue_last_error = 'Ausgabe von `' .. table.concat(argv, ' ') .. '` ist kein JSON-Objekt'
    else
      continue_last_error = vim.trim(out)
    end
  end
  return nil
end

local function continue_fail(msg)
  continue_failed = true
  vim.notify('CodeCompanion/Continue: ' .. msg, vim.log.levels.ERROR)
  return nil
end

-- Liest den Modell-Eintrag aus der config.yaml. Ein Fehler wird einmal gemeldet
-- und dann gemerkt -- sonst kaeme die Meldung bei jedem Feldzugriff erneut.
local function continue_model()
  if continue_entry or continue_failed then
    return continue_entry
  end
  if vim.fn.executable 'yq' == 0 then
    return continue_fail 'yq liegt nicht im PATH, ohne das laesst sich die config.yaml nicht lesen'
  end
  if vim.fn.filereadable(continue_config.path) == 0 then
    return continue_fail(continue_config.path .. ' ist nicht lesbar')
  end
  local parsed = continue_json()
  if not parsed then
    return continue_fail('kein yq-Aufruf lieferte JSON aus ' .. continue_config.path .. ' (zuletzt: ' .. continue_last_error .. ')')
  end
  if type(parsed.models) ~= 'table' then
    return continue_fail(continue_config.path .. ' enthaelt keine models-Liste')
  end
  local seen = {}
  for _, model in ipairs(parsed.models) do
    if model.name == continue_config.entry or model.model == continue_config.entry then
      continue_entry = model
      return model
    end
    table.insert(seen, model.name or model.model or '?')
  end
  return continue_fail(("kein models-Eintrag '%s' in %s -- vorhanden: %s"):format(continue_config.entry, continue_config.path, table.concat(seen, ', ')))
end

-- apiBase ohne Schraegstrich am Ende; leer, solange der Eintrag fehlt.
local function continue_base()
  local model = continue_model()
  if not model or type(model.apiBase) ~= 'string' then
    return ''
  end
  return (model.apiBase:gsub('/+$', ''))
end

-- Continues Konvention ist eine apiBase samt /v1. Fehlt es, ergaenzen wir es,
-- damit auch eine Gateway-URL ohne Versionssegment funktioniert.
local function continue_path(suffix)
  return function()
    return (continue_base():match '/v1$' and '' or '/v1') .. suffix
  end
end
return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  -- Kein lazy=false noetig: anders als claudecode.nvim (das ab Start ein
  -- ~/.claude/ide/*.lock schreiben musste, damit eine fremde CLI nvim findet)
  -- startet CodeCompanion den Agenten selbst -- als Kindprozess von nvim, ohne
  -- Terminal-Pane und ohne Bruecke von aussen.
  cmd = { 'CodeCompanion', 'CodeCompanionChat', 'CodeCompanionActions' },
  -- Voraussetzung je Rechner: `claude` bzw. `agent` (Cursor CLI, per `agent login`
  -- angemeldet) auf dem PATH. Fehlt eines, faellt nur der jeweilige Adapter aus.
  init = function()
    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
      wk.add { { '<leader>a', group = 'AI / CodeCompanion' } }
    end
  end,
  opts = {
    adapters = {
      http = {
        -- Eigener Adapter statt eines extend-Eintrags: openai_compatible ist
        -- eine Vorlage zum Ableiten, kein Preset, das hier ueberschrieben wuerde.
        continue = function()
          return require('codecompanion.adapters').extend('openai_compatible', {
            name = 'continue',
            formatted_name = 'Continue',
            env = {
              api_key = function()
                local model = continue_model()
                return model and model.apiKey or ''
              end,
              url = continue_base,
              chat_url = continue_path '/chat/completions',
              models_endpoint = continue_path '/models',
            },
            schema = {
              -- Gepinnt, damit CodeCompanion fuer den Default nicht erst
              -- models_endpoint abfragen muss.
              model = {
                default = function()
                  local model = continue_model()
                  return model and (model.model or model.name) or ''
                end,
              },
            },
          })
        end,
        extend = {
          ollama = {
            -- Muss gepinnt werden: auf der Linux-Kiste liegt fuers FIM ein
            -- -base-Modell, und das wuerde im Chat Unsinn produzieren. Chat
            -- braucht die instruct-Variante. Auf CPU ist 7b zaeh, aber beim
            -- Chat wartet man auf eine Antwort -- anders als beim Ghost-Text.
            -- Zu langsam? Dann qwen2.5-coder:3b. Vorher `ollama pull`.
            schema = {
              model = { default = 'qwen2.5-coder:7b' },
              -- Ollamas num_ctx ist per Default nil, das Fenster damit
              -- unbekannt -- ohne Zahl gibt es auch keine Auslastung. Explizit
              -- gesetzt dient es beidem: der Anzeige unten und der CPU, der ein
              -- grosses Fenster teuer zu stehen kommt.
              num_ctx = { default = 8192 },
            },
          },
        },
      },
    },
    interactions = {
      chat = {
        -- Sprechende Header statt 'Me' und 'CodeCompanion (Ollama)': auf einen
        -- Blick sichtbar, wer antwortet -- und mit welchem Modell. Den
        -- Modellnamen gibt es nur bei HTTP-Adaptern; ueber ACP ist
        -- adapter.model nil, dann bleibt es beim Adapternamen.
        roles = {
          user = 'Robert',
          llm = function(adapter)
            local model = adapter.model and (adapter.model.formatted_name or adapter.model.name)
            return adapter.formatted_name .. (model and (' · ' .. model) or '')
          end,
        },
        -- claude_code und cursor_cli sind mitgelieferte ACP-Presets: der Agent
        -- laeuft als CLI mit eigenem Tool-Zugriff aufs Repo, kein API-Key -- es
        -- zaehlt das Abo des jeweiligen Rechners. Eine eigene adapters.acp-
        -- Tabelle wuerde die Preset-Aufloesung ersetzen und den Chat brechen;
        -- Abweichungen gehoeren nach adapters.acp.extend.
        --
        -- Default ist, was der jeweilige Rechner hat: auf dem Mac Claude Code
        -- ueber ACP, auf der Linux-Workstation vorerst Ollama ueber HTTP --
        -- dort gibt es weder Claude Code noch (bis auf Weiteres) Cursor.
        --
        -- Uebergangsloesung mit Ansage: ein kleines lokales Modell auf CPU
        -- taugt fuer Fragen und Erklaerungen, agentisches Arbeiten mit Tools
        -- kann es kaum. Sobald Cursor da ist, wird aus dem 'ollama' hier ein
        -- 'cursor_cli' -- der Rest der Konfiguration bleibt.
        adapter = vim.fn.has 'mac' == 1 and 'claude_code' or 'ollama',
      },
      opts = {
        -- Der Agent schreibt Dateien selbst; ohne Watcher zeigt nvim weiter den
        -- alten Buffer-Inhalt an.
        watcher = { enabled = true },
      },
    },
    display = {
      action_palette = { provider = 'telescope' },
      chat = {
        -- Kontextauslastung statt blanker Tokenzahl -- wie im Claude CLI.
        -- Nur HTTP-Adapter (hier Ollama) liefern Zaehlwerte; ueber ACP kommt
        -- keine Usage, dort bleibt die Anzeige leer.
        token_count = function(tokens, adapter)
          local window = adapter and adapter.schema and adapter.schema.num_ctx and adapter.schema.num_ctx.default
          if type(window) ~= 'number' or window <= 0 then
            return string.format(' (%d tokens)', tokens)
          end
          return string.format(' (%.1fk/%.0fk · %d%%)', tokens / 1000, window / 1000, math.floor(tokens / window * 100))
        end,
      },
      -- Aenderungen des Agenten landen als Diff im Buffer: ansehen mit gv,
      -- annehmen mit g2, verwerfen mit g3, alles im Buffer akzeptieren mit g1.
      -- threshold_for_chat bleibt beim Default (6) -- kleine Diffs stehen im
      -- Chat, groessere in einem eigenen Fenster.
      diff = { enabled = true },
    },
  },
  keys = {
    -- <C-.> war der Toggle von claudecode.nvim und bleibt es, damit das
    -- Muskelgedaechtnis passt.
    { '<C-.>', '<cmd>CodeCompanionChat Toggle<cr>', desc = 'CodeCompanion: Toggle chat', mode = { 'n', 'v' } },
    { '<leader>aa', '<cmd>CodeCompanionChat Toggle<cr>', desc = 'AI: Toggle chat' },
    { '<leader>ac', '<cmd>CodeCompanionChat adapter=cursor_cli<cr>', desc = 'AI: Chat with Cursor CLI' },
    { '<leader>ai', '<cmd>CodeCompanionChat adapter=continue<cr>', desc = 'AI: Chat with Continue' },
    { '<leader>ap', '<cmd>CodeCompanionActions<cr>', desc = 'AI: Action palette', mode = { 'n', 'v' } },
    { '<leader>as', '<cmd>CodeCompanionChat Add<cr>', desc = 'AI: Send selection to chat', mode = 'v' },
  },
}
