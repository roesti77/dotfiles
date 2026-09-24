-- sidekick startet AI-CLIs in nvim, statt selbst HTTP zu sprechen. Das trifft
-- genau die Lage auf dem Kundenrechner: Cursor und Continue bringen eigene CLIs
-- mit, die ihre Anmeldung und ihre Konfiguration selbst kennen -- `cn` liest
-- ~/.continue/config.yaml nativ, samt apiBase, Key und Modell. Damit entfaellt
-- das Nachbauen von Endpoint und Auth in Lua.
return {
  'folke/sidekick.nvim',
  -- snacks liefert die Auswahlliste fuer Tools und Prompts; ohne snacks faellt
  -- sidekick auf vim.ui.select zurueck.
  dependencies = { 'folke/snacks.nvim' },
  cmd = 'Sidekick',
  init = function()
    local wk_ok, wk = pcall(require, 'which-key')
    if wk_ok then
      -- <leader>a gehoert CodeCompanion, solange beide nebeneinander laufen.
      wk.add { { '<leader>A', group = 'AI / Sidekick' } }
    end
  end,
  opts = {
    -- Next Edit Suggestions brauchen ein GitHub-Copilot-Abo und den
    -- copilot-language-server. Beides gibt es hier nicht, und ohne die Abschaltung
    -- meldet sidekick beim Start einen fehlenden LSP. Ghost-Text macht minuet.
    nes = { enabled = false },
    cli = {
      tools = {
        -- cursor ist vorkonfiguriert und braucht nur die CLI im PATH.
        -- Continue liefert `cn` mit, ist aber kein Preset -- eine Zeile genuegt.
        cn = { cmd = { 'cn' } },
      },
    },
  },
  keys = {
    {
      '<leader>AA',
      function()
        require('sidekick.cli').toggle()
      end,
      desc = 'Sidekick: Toggle CLI',
    },
    {
      '<leader>As',
      function()
        require('sidekick.cli').select { filter = { installed = true } }
      end,
      desc = 'Sidekick: Select CLI',
    },
    {
      '<leader>Ac',
      function()
        require('sidekick.cli').toggle { name = 'cursor', focus = true }
      end,
      desc = 'Sidekick: Cursor',
    },
    {
      '<leader>An',
      function()
        require('sidekick.cli').toggle { name = 'cn', focus = true }
      end,
      desc = 'Sidekick: Continue (cn)',
    },
    {
      '<leader>Ap',
      function()
        require('sidekick.cli').prompt()
      end,
      desc = 'Sidekick: Prompt',
      mode = { 'n', 'x' },
    },
    {
      '<leader>At',
      function()
        require('sidekick.cli').send { msg = '{this}' }
      end,
      desc = 'Sidekick: Send this',
      mode = { 'n', 'x' },
    },
    {
      '<leader>Af',
      function()
        require('sidekick.cli').send { msg = '{file}' }
      end,
      desc = 'Sidekick: Send file',
    },
    {
      '<leader>Av',
      function()
        require('sidekick.cli').send { msg = '{selection}' }
      end,
      desc = 'Sidekick: Send selection',
      mode = 'x',
    },
  },
}
