
return {
	"nvim-neo-tree/neo-tree.nvim",
	branch = "v3.x",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim",
	},
	config = function()
    require("neo-tree").setup({
      filesystem = {
        filtered_items = {
          visible = true,
          show_hidden_count = true,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {
            -- '.git',
            -- '.DS_Store',
            -- 'thumbs.db',
          },
          never_show = {},
        },
      }
    })
		vim.keymap.set("n", "<C-n>", ":Neotree toggle<CR>")
		vim.keymap.set("n", "<leader>b", ":Neotree buffers reveal float<CR>")
		vim.keymap.set("v", "<leader>b", ":Neotree buffers reveal float<CR>") -- für die versteckten Dateien
		vim.keymap.set("v", "<leader>f", ":Neotree files reveal float<CR>") -- für die versteckten Dateien
		vim.keymap.set("n", "<C-f>", ":Files open in a new window<CR>")
		vim.keymap.set("n", "<C-b>", ":Buffers open in a new window<CR>")
	end
}


