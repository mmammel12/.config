return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			-- We keep the dependency here but configure it separately
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				-- A list of parser names, or "all"
				ensure_installed = {
					"comment",
					"go",
					"gomod", -- For Go mod files
					"gowork", -- For Go work files
					"gosum", -- For Go sum files
					"javascript",
					"typescript", -- Add TypeScript
					"tsx", -- For TSX (React)
					-- "jsx" has been removed as it's included in "javascript" parser
					"jsdoc",
					"html", -- For HTML in React projects
					"css", -- For CSS in React projects
					"json", -- For package.json, etc.
					"yaml", -- For configuration files
					"lua",
					"markdown",
					"markdown_inline",
					"regex",
					"vimdoc",
				},

				-- Install parsers synchronously (only applied to `ensure_installed`)
				sync_install = false,

				-- Automatically install missing parsers when entering buffer
				auto_install = true,

				indent = { enable = true },

				highlight = {
					-- `false` will disable the whole extension
					enable = true,
					-- Disable slow treesitter highlight for large files
					disable = function(_, buf)
						local max_filesize = 100 * 1024 -- 100 KB
						local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
							return true
						end
					end,
					additional_vim_regex_highlighting = false,
				},

				-- IMPORTANT: Remove the context_commentstring module to avoid deprecation warnings
				-- We'll configure it separately in comment.lua

				-- Enable auto-tag for JSX/TSX
				autotag = {
					enable = true,
				},

				textobjects = {
					select = {
						enable = true,
						lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
						keymaps = {
							-- You can use the capture groups defined in textobjects.scm
							["aa"] = "@parameter.outer",
							["ia"] = "@parameter.inner",
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							["ac"] = "@class.outer",
							["ic"] = "@class.inner",
							["ii"] = "@conditional.inner",
							["ai"] = "@conditional.outer",
							["il"] = "@loop.inner",
							["al"] = "@loop.outer",
							["at"] = "@comment.outer",
						},
					},
					-- Better movement between functions and classes
					move = {
						enable = true,
						set_jumps = true, -- whether to set jumps in the jumplist
						goto_next_start = {
							["]m"] = "@function.outer",
							["]]"] = "@class.outer",
						},
						goto_next_end = {
							["]M"] = "@function.outer",
							["]["] = "@class.outer",
						},
						goto_previous_start = {
							["[m"] = "@function.outer",
							["[["] = "@class.outer",
						},
						goto_previous_end = {
							["[M"] = "@function.outer",
							["[]"] = "@class.outer",
						},
					},
					-- Code folding based on treesitter
					fold = {
						enable = true,
					},
				},
			})

			-- Set foldmethod based on treesitter
			vim.opt.foldmethod = "expr"
			vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
			vim.opt.foldenable = false -- Don't fold by default when opening files
		end,
	},

	-- Keep treesitter context
	{ "nvim-treesitter/nvim-treesitter-context" },

	-- Note: Rainbow delimiters removed since mini.nvim may have similar functionality
}
