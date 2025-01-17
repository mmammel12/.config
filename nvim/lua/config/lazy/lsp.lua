return {
	{
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
			{
				"folke/lazydev.nvim",
				opts = {
					library = {
						{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					},
				},
			},
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup()

			-- After setting up mason-lspconfig you may set up servers via lspconfig
			-- require("lspconfig").lua_ls.setup {}
			-- require("lspconfig").rust_analyzer.setup {}
			-- ...

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			require("lspconfig").lua_ls.setup({ capabilites = capabilities })
		end,
	},
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		opts = {},
	},
}
