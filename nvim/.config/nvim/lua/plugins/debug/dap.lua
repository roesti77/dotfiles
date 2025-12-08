-- lua/plugins/dap.lua
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
    'theHamsta/nvim-dap-virtual-text',
  },

  keys = {
    {
      '<leader>dc',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<leader>di',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<leader>do',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<leader>dO',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: Toggle Breakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: Set Breakpoint (cond.)',
    },
    {
      '<leader>dC',
      function()
        require('dap').run_to_cursor()
      end,
      desc = 'Debug: Run to Cursor',
    },
    {
      '<leader>dT',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: Terminate',
    },
    {
      '<leader>du',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: Toggle UI',
    },
    {
      '<leader>dt',
      function()
        require('dap-go').debug_test()
      end,
      desc = 'Go: Debug Test',
    },
    {
      '<leader>da',
      function()
        vim.cmd 'DapSkaffoldAttach'
      end,
      desc = 'Attach: Skaffold/Delve',
    },
  },

  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- -------- Settings you may want to adapt --------
    local NS = 'uniparts-chatbot-dev' -- Kubernetes namespace
    local SELECTOR = 'app=gateway' -- Pod selector label
    local REMOTE_PATHS = { '/workspace/gateway', '/workspace' } -- build-time paths
    -- ------------------------------------------------

    local function tbl_deep_get(t, ks)
      local cur = t
      for _, k in ipairs(ks) do
        if type(cur) ~= 'table' then
          return nil
        end
        cur = cur[k]
      end
      return cur
    end

    local function detect_dlv_port()
      local jsonpath = '{.items[0].metadata.annotations.debug\\.cloud\\.google\\.com/config}'
      local cmd = string.format("kubectl -n %s get pod -l %s -o jsonpath='%s'", NS, SELECTOR, jsonpath)
      local out = vim.fn.system(cmd)
      if vim.v.shell_error ~= 0 or not out or out == '' then
        return nil
      end
      local ok, cfg = pcall(vim.json.decode, out)
      if not ok then
        return nil
      end
      -- Try a few common shapes of the annotation payload
      -- Shape A: { "container": { "runtime":"go", "ports":{"dlv": xxxxx}, ... }, ... }
      -- Shape B: [ { "runtime":"go", "ports":{"dlv": xxxxx} }, ... ]
      local function scan(v)
        if type(v) ~= 'table' then
          return nil
        end
        -- direct map with runtime/ports
        if v.runtime == 'go' then
          local p = tbl_deep_get(v, { 'ports', 'dlv' })
          if p then
            return tonumber(p)
          end
        end
        -- nested tables
        for _, vv in pairs(v) do
          local p = scan(vv)
          if p then
            return p
          end
        end
        return nil
      end
      return scan(cfg)
    end

    require('mason').setup()
    require('mason-nvim-dap').setup {
      automatic_installation = true,
      ensure_installed = { 'delve' },
      handlers = {},
    }

    require('nvim-dap-virtual-text').setup {}
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Signs
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local nf = vim.g.have_nerd_font
    local icons = nf and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for t, ic in pairs(icons) do
      local hl = (t == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define('Dap' .. t, { text = ic, texthl = hl, numhl = hl })
    end

    -- Auto open/close UI
    dap.listeners.after.event_initialized['dapui'] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated['dapui'] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited['dapui'] = function()
      dapui.close()
    end

    -- Go adapter: connect to Delve that skaffold debug runs
    dap.adapters.go = {
      type = 'server',
      host = '127.0.0.1',
      port = function()
        local p = os.getenv 'DLV_PORT'
        if p and #p > 0 then
          return tonumber(p)
        end
        local det = detect_dlv_port()
        if det then
          return det
        end
        return tonumber(vim.fn.input 'dlv port: ')
      end,
    }

    -- Base Go configurations
    dap.configurations.go = {
      {
        type = 'go',
        name = 'Attach (Skaffold)',
        request = 'attach',
        mode = 'remote',
        substitutePath = (function()
          local subs, cwd = {}, vim.fn.getcwd()
          for _, rp in ipairs(REMOTE_PATHS) do
            table.insert(subs, { from = cwd, to = rp })
          end
          return subs
        end)(),
      },
      {
        type = 'go',
        name = "Debug current file's folder",
        request = 'launch',
        program = function()
          return vim.fn.expand '%:p:h'
        end,
      },
    }

    -- Language-specific helpers
    require('dap-go').setup {
      delve = { detached = (vim.fn.has 'win32' == 0) },
    }
    -- Python is available if you need it later
    -- require('dap-python').setup('python')

    -- User command to quickly attach to skaffold/Delve
    vim.api.nvim_create_user_command('DapSkaffoldAttach', function()
      local port = os.getenv 'DLV_PORT' or detect_dlv_port() or vim.fn.input 'dlv port: '
      if not port or tostring(port) == '' then
        vim.notify('No dlv port found', vim.log.levels.ERROR)
        return
      end
      -- Force the adapter to use the detected/entered port once
      local old = dap.adapters.go
      dap.adapters.go = {
        type = 'server',
        host = '127.0.0.1',
        port = function()
          return tonumber(port)
        end,
      }
      dap.continue()
      -- Restore the dynamic adapter for future runs
      dap.adapters.go = old
    end, {})
  end,
}
