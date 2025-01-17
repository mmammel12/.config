return {
	{
		"nvim-lua/plenary.nvim",
		name = "plenary",
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		config = function()
			require("ibl").setup({})
		end,
	},
	{ "tpope/vim-surround" },
	{ "tpope/vim-commentary" },
}
