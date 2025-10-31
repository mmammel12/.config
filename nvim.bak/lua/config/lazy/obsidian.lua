return {
	"epwalsh/obsidian.nvim",
	version = "*",
	lazy = true,
	-- only load obsidian.nvim for markdown files in vault
	event = {
		"BufReadPre " .. vim.fn.expand("~") .. "/dev/Obsidian/**.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/dev/Obsidian/**.md",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {
		workspaces = {
			{
				name = "personal",
				path = "~/dev/Obsidian/Sync Vault",
			},
			{
				name = "work",
				path = "~/dev/Obsidian/FloQast",
			},
		},
		daily_notes = {
			folder = "Timestamps" .. tostring(os.date("/%Y/%m-%B")),
			date_format = "%Y-%m-%d-%A",
			alias_format = "%A, %B %d, %Y",
			template = "Daily Note Template.md",
		},
		templates = { subdir = "Templates" },
	},
}
