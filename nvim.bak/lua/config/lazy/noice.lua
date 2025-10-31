return {
	"folke/noice.nvim",
	event = "VeryLazy",
	opts = {
		cmdline = {
			enabled = true,
			view = "cmdline_popup",
		},
		messages = {
			enabled = false,
		},
		views = {
			cmdline_popup = {
				position = {
					row = 5,
					col = "50%",
				},
			},
		},
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
}
