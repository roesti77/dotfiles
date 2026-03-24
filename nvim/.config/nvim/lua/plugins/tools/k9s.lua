return {
  "nvim-telescope/telescope.nvim",
  keys = {
    { "<leader>K", group = "Kubernetes" },
    {
      "<leader>KK",
      function()
        local buf = vim.api.nvim_create_buf(false, true)
        local width = math.floor(vim.o.columns * 0.9)
        local height = math.floor(vim.o.lines * 0.9)
        vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          col = math.floor((vim.o.columns - width) / 2),
          row = math.floor((vim.o.lines - height) / 2),
          style = "minimal",
          border = "rounded",
        })
        vim.fn.termopen("k9s", {
          on_exit = function()
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
          end,
        })
        vim.cmd("startinsert")
      end,
      desc = "K9s",
    },
    {
      "<leader>Kp",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        pickers.new({}, {
          prompt_title = "K8s Pods",
          finder = finders.new_async_job({
            command_generator = function() return { "kubectl", "get", "pods", "--all-namespaces", "--no-headers" } end,
            entry_maker = function(line)
              return { value = line, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local entry = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if entry then
                local parts = vim.split(entry.value, "%s+")
                vim.cmd("terminal kubectl -n " .. parts[1] .. " describe pod " .. parts[2])
                vim.cmd("startinsert")
              end
            end)
            return true
          end,
        }):find()
      end,
      desc = "K8s Pods",
    },
    {
      "<leader>Kd",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        pickers.new({}, {
          prompt_title = "K8s Deployments",
          finder = finders.new_async_job({
            command_generator = function() return { "kubectl", "get", "deployments", "--all-namespaces", "--no-headers" } end,
            entry_maker = function(line)
              return { value = line, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
        }):find()
      end,
      desc = "K8s Deployments",
    },
    {
      "<leader>Ks",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        pickers.new({}, {
          prompt_title = "K8s Services",
          finder = finders.new_async_job({
            command_generator = function() return { "kubectl", "get", "services", "--all-namespaces", "--no-headers" } end,
            entry_maker = function(line)
              return { value = line, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
        }):find()
      end,
      desc = "K8s Services",
    },
    {
      "<leader>Kl",
      function()
        local pod = vim.fn.input("Pod name: ")
        if pod == "" then return end
        local ns = vim.fn.input("Namespace [default]: ")
        if ns == "" then ns = "default" end
        vim.cmd("terminal kubectl -n " .. ns .. " logs -f " .. pod)
        vim.cmd("startinsert")
      end,
      desc = "K8s Logs",
    },
    -- ArgoCD
    {
      "<leader>Ka",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        pickers.new({}, {
          prompt_title = "ArgoCD Applications",
          finder = finders.new_async_job({
            command_generator = function() return { "argocd", "app", "list", "--output", "name" } end,
            entry_maker = function(line)
              return { value = line, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local entry = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if entry then
                vim.cmd("terminal argocd app get " .. entry.value)
                vim.cmd("startinsert")
              end
            end)
            return true
          end,
        }):find()
      end,
      desc = "ArgoCD Apps",
    },
    {
      "<leader>KA",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        pickers.new({}, {
          prompt_title = "ArgoCD Sync App",
          finder = finders.new_async_job({
            command_generator = function() return { "argocd", "app", "list", "--output", "name" } end,
            entry_maker = function(line)
              return { value = line, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local entry = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if entry then
                vim.cmd("terminal argocd app sync " .. entry.value)
                vim.cmd("startinsert")
              end
            end)
            return true
          end,
        }):find()
      end,
      desc = "ArgoCD Sync",
    },
    -- Argo Workflows
    {
      "<leader>Kw",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local ns = vim.fn.input("Namespace [argo]: ")
        if ns == "" then ns = "argo" end
        pickers.new({}, {
          prompt_title = "Argo Workflows",
          finder = finders.new_async_job({
            command_generator = function() return { "argo", "list", "-n", ns, "--no-headers" } end,
            entry_maker = function(line)
              return { value = line, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local entry = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if entry then
                local name = vim.split(entry.value, "%s+")[1]
                vim.cmd("terminal argo get -n " .. ns .. " " .. name)
                vim.cmd("startinsert")
              end
            end)
            return true
          end,
        }):find()
      end,
      desc = "Argo Workflows",
    },
    {
      "<leader>KW",
      function()
        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local conf = require("telescope.config").values
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local ns = vim.fn.input("Namespace [argo]: ")
        if ns == "" then ns = "argo" end
        pickers.new({}, {
          prompt_title = "Argo Workflow Logs",
          finder = finders.new_async_job({
            command_generator = function() return { "argo", "list", "-n", ns, "--no-headers" } end,
            entry_maker = function(line)
              return { value = line, display = line, ordinal = line }
            end,
          }),
          sorter = conf.generic_sorter({}),
          attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
              local entry = action_state.get_selected_entry()
              actions.close(prompt_bufnr)
              if entry then
                local name = vim.split(entry.value, "%s+")[1]
                vim.cmd("terminal argo logs -n " .. ns .. " " .. name)
                vim.cmd("startinsert")
              end
            end)
            return true
          end,
        }):find()
      end,
      desc = "Argo Workflow Logs",
    },
  },
}
