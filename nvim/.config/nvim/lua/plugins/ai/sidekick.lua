-- sidekick startet AI-CLIs in nvim, statt selbst HTTP zu sprechen. Das trifft
-- genau die Lage auf dem Kundenrechner: Cursor und Continue bringen eigene CLIs
-- mit, die ihre Anmeldung und ihre Konfiguration selbst kennen -- `cn` liest
-- ~/.continue/config.yaml nativ, samt apiBase, Key und Modell. Damit entfaellt
-- das Nachbauen von Endpoint und Auth in Lua.
--
-- Loest CodeCompanion ab und uebernimmt dessen Tasten. Voraussetzung je Rechner
-- ist nur die jeweilige CLI im PATH: `claude` privat, `cursor-agent` und `cn`
-- beim Kunden. Fehlt eine, faellt nur sie aus -- `:checkhealth sidekick` zeigt,
-- welche gefunden werden.
return {
  'folke/sidekick.nvim',
  -- snacks liefert die Auswahlliste fuer Tools und Prompts; ohne snacks faellt
  -- sidekick auf vim.ui.select zurueck.
  dependencies = { 'folke/snacks.nvim' },
  cmd = 'Sidekick',
  init = function()
    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
      wk.add { { '<leader>a', group = 'AI / Sidekick' } }
    end
  end,
  opts = {
    -- Next Edit Suggestions brauchen ein GitHub-Copilot-Abo und den
    -- copilot-language-server. Beides gibt es hier nicht, und ohne die Abschaltung
    -- meldet sidekick beim Start einen fehlenden LSP. Ghost-Text macht minuet.
    nes = { enabled = false },
    cli = {
      tools = {
        -- claude und cursor sind vorkonfiguriert und brauchen nur die CLI im
        -- PATH. Continue liefert `cn` mit, ist aber kein Preset.
        cn = { cmd = { 'cn' } },
      },
    },
  },
  keys = {
    -- <C-.> war der Toggle von claudecode.nvim und CodeCompanion und bleibt es.
    -- Ohne Tool-Namen haengt sich sidekick an eine laufende Sitzung oder fragt,
    -- welche gestartet werden soll.
    {
      '<C-.>',
      function()
        require('sidekick.cli').toggle()
      end,
      desc = 'Sidekick: Toggle CLI',
      mode = { 'n', 'v', 't' },
    },
    {
      '<leader>aa',
      function()
        require('sidekick.cli').toggle()
      end,
      desc = 'AI: Toggle CLI',
    },
    {
      '<leader>as',
      function()
        require('sidekick.cli').select { filter = { installed = true } }
      end,
      desc = 'AI: Select CLI',
    },
    {
      '<leader>ac',
      function()
        require('sidekick.cli').toggle { name = 'cursor', focus = true }
      end,
      desc = 'AI: Cursor',
    },
    {
      '<leader>ai',
      function()
        require('sidekick.cli').toggle { name = 'cn', focus = true }
      end,
      desc = 'AI: Continue (cn)',
    },
    {
      '<leader>ap',
      function()
        require('sidekick.cli').prompt()
      end,
      desc = 'AI: Select prompt',
      mode = { 'n', 'x' },
    },
    {
      '<leader>at',
      function()
        require('sidekick.cli').send { msg = '{this}' }
      end,
      desc = 'AI: Send this',
      mode = { 'n', 'x' },
    },
    {
      '<leader>af',
      function()
        require('sidekick.cli').send { msg = '{file}' }
      end,
      desc = 'AI: Send file',
    },
    -- war unter CodeCompanion <leader>as; das heisst hier jetzt "Select CLI"
    {
      '<leader>av',
      function()
        require('sidekick.cli').send { msg = '{selection}' }
      end,
      desc = 'AI: Send selection',
      mode = 'x',
    },
    {
      '<leader>ad',
      function()
        require('sidekick.cli').close()
      end,
      desc = 'AI: Detach session',
    },
  },
}
