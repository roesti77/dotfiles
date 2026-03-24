return {
  {
    "ANGkeith/telescope-terraform-doc.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    keys = {
      {
        "<leader>Td",
        function()
          require("telescope").load_extension("terraform_doc")
          vim.cmd("Telescope terraform_doc")
        end,
        desc = "Terraform Docs",
      },
      {
        "<leader>Tp",
        function()
          require("telescope").load_extension("terraform_doc")
          local providers = {
            { name = "AWS", full_name = "hashicorp/aws" },
            { name = "VMware vSphere", full_name = "hashicorp/vsphere" },
            { name = "Hetzner Cloud", full_name = "hetznercloud/hcloud" },
            { name = "Talos", full_name = "siderolabs/talos" },
          }
          vim.ui.select(providers, {
            prompt = "Terraform Provider:",
            format_item = function(item) return item.name .. " (" .. item.full_name .. ")" end,
          }, function(choice)
            if not choice then return end
            vim.cmd("Telescope terraform_doc full_name=" .. choice.full_name)
          end)
        end,
        desc = "Terraform Provider Docs",
      },
    },
  },
  {
    "towolf/vim-helm",
    ft = "helm",
  },
}
