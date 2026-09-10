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
        extend = {
          ollama = {
            -- Muss gepinnt werden: auf der Linux-Kiste liegt fuers FIM ein
            -- -base-Modell, und das wuerde im Chat Unsinn produzieren. Chat
            -- braucht die instruct-Variante. Auf CPU ist 7b zaeh, aber beim
            -- Chat wartet man auf eine Antwort -- anders als beim Ghost-Text.
            -- Zu langsam? Dann qwen2.5-coder:3b. Vorher `ollama pull`.
            schema = { model = { default = 'qwen2.5-coder:7b' } },
          },
        },
      },
    },
    interactions = {
      chat = {
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
    { '<leader>ap', '<cmd>CodeCompanionActions<cr>', desc = 'AI: Action palette', mode = { 'n', 'v' } },
    { '<leader>as', '<cmd>CodeCompanionChat Add<cr>', desc = 'AI: Send selection to chat', mode = 'v' },
  },
}
