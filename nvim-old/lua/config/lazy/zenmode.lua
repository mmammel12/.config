return {
	"folke/zen-mode.nvim",
	config = function()
		vim.keymap.set("n", "<leader>zz", function()
			require("zen-mode").setup({
				window = {
					width = 150,
					options = {
						wrap = true,
						linebreak = true,
					},
				},
			})
			require("zen-mode").toggle()
		end, { desc = "zen-mode - Toggle zen mode" })
	end,
}
