return {
	"tpope/vim-fugitive",
	config = function()
		vim.keymap.set("n", "<leader>ga", function()
			vim.cmd.Git("add %")
		end, { remap = false, desc = "fugitive - add file" })
		vim.keymap.set("n", "<leader>gA", function()
			vim.cmd.Git("add -A")
		end, { remap = false, desc = "fugitive - add -A" })
		vim.keymap.set("n", "<leader>gp", function()
			vim.cmd.Git("push")
		end, { remap = false, desc = "fugitive - push" })

		-- rebase always
		vim.keymap.set("n", "<leader>gl", function()
			vim.cmd.Git({ "pull", "--rebase" })
		end, { remap = false, desc = "fugitive - pull --rebase" })

		-- NOTE: It allows me to easily set the branch i am pushing and any tracking
		-- needed if i did not set the branch up correctly
		vim.keymap.set("n", "<leader>go", ":Git push -u origin ", { remap = false, desc = "fugitive - push -u origin" })
	end,
}
