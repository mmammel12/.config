return {
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			require("dapui").setup()
			require("nvim-dap-virtual-text").setup({})

			vim.fn.sign_define(
				"DapBreakpoint",
				{ text = "🔴", texthl = "DapBreakpoint", linehl = "DapBreakpoint", numhl = "DapBreakpoint" }
			)

			vim.keymap.set("n", "<leader>bt", function()
				require("dapui").toggle()
			end, { desc = "dap - toggle ui" })
			vim.keymap.set(
				"n",
				"<leader>bb",
				":DapToggleBreakpoint<CR>",
				{ noremap = true, desc = "dap - toggle breakpoint" }
			)

			vim.keymap.set("n", "<leader>bc", ":DapContinue<CR>", { noremap = true, desc = "dap - continue/start" })
			vim.keymap.set("n", "<leader>bo", ":DapStepOver<CR>", { noremap = true, desc = "dap - step over" })
			vim.keymap.set("n", "<leader>bi", ":DapStepInto<CR>", { noremap = true, desc = "dap - step into" })
			vim.keymap.set("n", "<leader>bO", ":DapStepOut<CR>", { noremap = true, desc = "dap - step out" })
			vim.keymap.set(
				"n",
				"<leader>br",
				":lua require('dap').restart()<CR>",
				{ noremap = true, desc = "dap - restart" }
			)
			vim.keymap.set("n", "<leader>bs", ":DapTerminate<CR>", { noremap = true, desc = "dap - stop" })
		end,
	},

	"theHamsta/nvim-dap-virtual-text",

	{
		"mxsdev/nvim-dap-vscode-js",
		dependencies = { "mfussenegger/nvim-dap" },
		config = function()
			require("dap-vscode-js").setup({
				adapters = { "pwa-node", "pwa-chrome" },
			})

			require("dap").configurations.javascript = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					skipFiles = { "<node_internals>/**" },
					program = "${file}",
					cwd = "${workspaceFolder}",
				},
				{
					type = "pwa-chrome",
					request = "launch",
					name = "Launch Chrome",
					url = "http://localhost:3000",
					webRoot = "${workspaceFolder}",
					cwd = "${workspaceFolder}",
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
			}
		end,
	},
}
