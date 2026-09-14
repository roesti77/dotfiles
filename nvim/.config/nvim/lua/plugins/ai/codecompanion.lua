-- Continue (hub.continue.dev) als dritter Chat-Adapter. Anders als claude_code
-- und cursor_cli kein ACP-Preset: Continues CLI (`cn`) kennt keinen ACP-Modus.
-- Der Hub bietet stattdessen einen OpenAI-kompatiblen Model-Proxy -- denselben,
-- den Continues eigenes SDK anspricht.
--
-- Ohne die beiden ersten Werte laeuft der Adapter nicht:
local continue_config = {
  -- Vierteiliger Name owner/package/provider/model, z.B.
  -- 'continuedev/default/anthropic/claude-3-haiku-20240307'. Eine blosse
  -- Modell-ID loest nicht auf -- der Proxy liest den Upstream-Provider daraus.
  model = 'FILL-IN-owner/package/provider/model',

  -- Name der Umgebungsvariable mit dem Hub-API-Key (hub.continue.dev ->
  -- Settings -> API Keys). CodeCompanion nimmt hier auch 'cmd:op read op://...'
  -- oder eine Funktion, die den Key liefert -- nie den Key selbst, das Repo ist
  -- oeffentlich.
  api_key = 'CONTINUE_API_KEY',

  -- Beide optional, nil ist der Normalfall: org_scope_id nur bei einem
  -- Org-Assistant, api_key_location nur, wenn der Upstream-Key selbst
  -- hinterlegt ist (etwa 'env.ANTHROPIC_API_KEY'). Continue wertet eine
  -- Konfiguration ohne beides ausdruecklich als gueltig.
  org_scope_id = nil,
  api_key_location = nil,
}

-- Spiegelt extraBodyProperties() von Continues continue-proxy-Provider: der
-- Proxy erwartet das Objekt in jedem Request-Body. vim.NIL haelt orgScopeId als
-- explizites JSON-null drin, statt den Schluessel wegfallen zu lassen.
local continue_properties = {
  orgScopeId = continue_config.org_scope_id or vim.NIL,
  apiKeyLocation = continue_config.api_key_location,
}

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
              api_key = continue_config.api_key,
              url = 'https://api.continue.dev',
              chat_url = '/model-proxy/v1/chat/completions',
              models_endpoint = '/model-proxy/v1/models',
            },
            -- Wird in jeden Request-Body gemergt.
            body = {
              continueProperties = continue_properties,
            },
            schema = {
              -- Gepinnt, damit CodeCompanion fuer den Default nicht erst
              -- models_endpoint abfragen muss.
              model = { default = continue_config.model },
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
