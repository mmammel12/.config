return {
	"nvim-focus/focus.nvim",
	version = "*",
	config = function()
		require("focus").setup({
			enable = true,
			commands = true,
			ui = {
				cursorline = true,
				cursorcolumn = true,
			},
			autoresize = {
				enable = false,
			},
		})

		local focusmap = function(direction)
			vim.keymap.set("n", "<Leader>s" .. direction, function()
				require("focus").split_command(direction)
			end, { desc = string.format("Create or move to split (%s)", direction) })
		end

		-- Use `<Leader>s` to split the screen to the left, same as command FocusSplitLeft etc
		focusmap("h")
		focusmap("j")
		focusmap("k")
		focusmap("l")
	end,
}
