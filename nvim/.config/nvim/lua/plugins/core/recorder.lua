return {
  "chrisgrieser/nvim-recorder",
  dependencies = "rcarriga/nvim-notify",
  keys = {
    { "<leader>q", group = "Recorder" },
    { "q", desc = "Start/Stop Recording" },
    { "Q", desc = "Play Recording" },
    { "<leader>qs", desc = "Switch Slot" },
    {
      "<leader>qv",
      function()
        local slots = { "a", "b", "c", "d" }
        local items = {}
        for _, slot in ipairs(slots) do
          local content = vim.fn.getreg(slot)
          local display = content ~= "" and content or "(leer)"
          table.insert(items, { slot = slot, display = string.format("[%s] %s", slot, display) })
        end
        vim.ui.select(items, {
          prompt = "Makro Register:",
          format_item = function(item) return item.display end,
        }, function(choice)
          if not choice then return end
          local current = vim.g.NvimRecorderSlot or "a"
          if current ~= choice.slot then
            local order = { "a", "b", "c", "d" }
            local cur_idx, target_idx
            for i, s in ipairs(order) do
              if s == current then cur_idx = i end
              if s == choice.slot then target_idx = i end
            end
            local presses = (target_idx - cur_idx) % #order
            for _ = 1, presses do
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<leader>qs", true, false, true), "x", false)
            end
          end
        end)
      end,
      desc = "View & Select Macro Slot",
    },
    { "<leader>qe", desc = "Edit Macro" },
    { "<leader>qy", desc = "Yank Macro" },
    { "<leader>qd", desc = "Delete All Macros" },
  },
  opts = {
    slots = { "a", "b", "c", "d" },
    mapping = {
      startStopRecording = "q",
      playMacro = "Q",
      switchSlot = "<leader>qs",
      editMacro = "<leader>qe",
      deleteAllMacros = "<leader>qd",
      yankMacro = "<leader>qy",
    },
    clear = false,
    logLevel = vim.log.levels.INFO,
    lessNotifications = false,
    useNerdfontIcons = true,
    performanceOpts = {
      countThreshold = 100,
      lazyredraw = true,
      noSystemClipboard = true,
      autocmdEventsIgnore = {
        "TextChangedI",
        "TextChanged",
        "InsertLeave",
        "InsertEnter",
        "InsertCharPre",
      },
    },
    dapSharedKeymaps = false,
  },
}
