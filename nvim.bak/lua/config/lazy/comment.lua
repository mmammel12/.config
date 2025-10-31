return {
	-- Add JSX/TSX comment support
	{
		"JoosepAlviste/nvim-ts-context-commentstring",
		config = function()
			-- Set this to true to avoid the deprecation warning
			vim.g.skip_ts_context_commentstring_module = true

			require("ts_context_commentstring").setup({
				enable_autocmd = false,
				-- Use treesitter to determine the comment string
				languages = {
					javascript = {
						__default = "// %s",
						jsx_element = "{/* %s */}",
						jsx_fragment = "{/* %s */}",
						jsx_attribute = "/* %s */",
						comment = "// %s",
					},
					typescript = {
						__default = "// %s",
						tsx_element = "{/* %s */}",
						tsx_fragment = "{/* %s */}",
						tsx_attribute = "/* %s */",
						comment = "// %s",
					},
				},
			})
		end,
	},

	-- If you're using a comment plugin like Comment.nvim, add the integration
	{
		"numToStr/Comment.nvim",
		dependencies = "JoosepAlviste/nvim-ts-context-commentstring",
		config = function()
			require("Comment").setup({
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
			})
		end,
		-- If you don't use Comment.nvim, you can remove this entry
	},
}
