return {
	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"antoinemadec/FixCursorHold.nvim",
			"haydenmeade/neotest-jest",
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local neotest = require("neotest")

			neotest.setup({
				adapters = {
					require("neotest-jest")({
						jestCommand = "npm test --",
						jestConfigFile = "jest.config.js",
						env = { CI = true },
						cwd = function()
							return vim.fn.getcwd()
						end,
					}),
				},
				status = {
					virtual_text = true,
					signs = true,
				},
				summary = {
					enabled = true,
					expand_errors = true,
					follow = true,
					mappings = {
						expand = { "<CR>", "<2-LeftMouse>" },
						expand_all = "e",
						output = "o",
						run = "r",
						debug = "d",
						mark = "m",
					},
				},
				icons = {
					running = "🔄",
					passed = "✅",
					failed = "❌",
					skipped = ">>",
				},
				quickfix = {
					enabled = true,
					open = true,
				},
				discovery = {
					enabled = true,
				},
				output = {
					enabled = true,
					open_on_run = true,
				},
				diagnostics = {
					enabled = true,
					severity = 1, -- Error level
				},
			})

			-- Create keymappings for Jest test running
			vim.keymap.set("n", "<leader>tr", function()
				neotest.run.run()
			end, { desc = "Run nearest test" })

			vim.keymap.set("n", "<leader>tf", function()
				neotest.run.run(vim.fn.expand("%"))
			end, { desc = "Run current file tests" })

			vim.keymap.set("n", "<leader>ts", function()
				neotest.summary.toggle()
			end, { desc = "Toggle test summary" })

			vim.keymap.set("n", "<leader>to", function()
				neotest.output.open({ enter = true })
			end, { desc = "Show test output" })

			vim.keymap.set("n", "<leader>tO", function()
				neotest.output_panel.toggle()
			end, { desc = "Toggle output panel" })

			-- These keybindings integrate with nvim-dap for debugging
			vim.keymap.set("n", "<leader>td", function()
				neotest.run.run({ strategy = "dap" })
			end, { desc = "Debug nearest test" })

			vim.keymap.set("n", "<leader>tD", function()
				neotest.run.run({ vim.fn.expand("%"), strategy = "dap" })
			end, { desc = "Debug file tests" })

			-- For watching tests (uses jest --watch)
			vim.keymap.set("n", "<leader>tw", function()
				-- Create a command string that includes --watch
				local file_path = vim.fn.expand("%:p")
				local cmd = "npm run test:watch -- " .. file_path
				vim.cmd("split | terminal " .. cmd)
				vim.cmd("startinsert")
			end, { desc = "Watch current file tests" })
		end,
	},

	-- Integration with existing DAP setup
	{
		"mfussenegger/nvim-dap",
		dependencies = { "nvim-neotest/neotest" },
		config = function()
			-- Ensure Jest configuration is in place
			local dap = require("dap")

			-- Make sure we have the Jest configuration
			if not dap.configurations.javascript then
				dap.configurations.javascript = {}
			end

			-- Add or update Jest configuration
			local jest_config = {
				type = "pwa-node",
				request = "launch",
				name = "Debug Jest Test",
				runtimeExecutable = "node",
				runtimeArgs = {
					"./node_modules/jest/bin/jest.js",
					"--runInBand",
					"--testTimeout=10000",
					"--colors",
				},
				rootPath = "${workspaceFolder}",
				cwd = "${workspaceFolder}",
				console = "integratedTerminal",
				internalConsoleOptions = "neverOpen",
				trace = true,
				sourceMaps = true,
			}

			-- Make sure we don't duplicate configurations
			local config_exists = false
			for _, config in ipairs(dap.configurations.javascript) do
				if config.name == "Debug Jest Test" then
					config_exists = true
					break
				end
			end

			if not config_exists then
				table.insert(dap.configurations.javascript, jest_config)
			end

			-- Apply the same to TypeScript
			if not dap.configurations.typescript then
				dap.configurations.typescript = vim.deepcopy(dap.configurations.javascript)
			else
				local ts_config_exists = false
				for _, config in ipairs(dap.configurations.typescript) do
					if config.name == "Debug Jest Test" then
						ts_config_exists = true
						break
					end
				end

				if not ts_config_exists then
					table.insert(dap.configurations.typescript, vim.deepcopy(jest_config))
				end
			end

			-- Create a global function to debug the current test file
			_G.debug_jest_file = function()
				local file_path = vim.fn.expand("%:p")

				-- Set the program to the current file
				local config = vim.deepcopy(jest_config)
				table.insert(config.runtimeArgs, file_path)

				dap.run(config)
			end

			-- Map to debug current test file
			vim.keymap.set("n", "<leader>dj", function()
				_G.debug_jest_file()
			end, { desc = "Debug current Jest file" })

			-- Integration with other DAP configs happens automatically through neotest
		end,
	},

	-- Terminal integration with Toggleterm (optional but recommended)
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		opts = {
			open_mapping = [[<c-\>]],
			direction = "float",
			float_opts = {
				border = "curved",
			},
		},
		config = function()
			local Terminal = require("toggleterm.terminal").Terminal

			-- Create a dedicated terminal for running tests
			local test_term = Terminal:new({
				cmd = "npm test",
				dir = "git_dir",
				hidden = true,
				direction = "float",
				float_opts = {
					border = "double",
				},
				close_on_exit = false,
				on_open = function()
					vim.cmd("startinsert!")
				end,
			})

			-- Function to run a specific test file with optional test name pattern
			_G.run_jest_test = function(file, pattern)
				local cmd = "npm test -- " .. file
				if pattern then
					cmd = cmd .. " -t '" .. pattern .. "'"
				end

				local custom_term = Terminal:new({
					cmd = cmd,
					dir = "git_dir",
					hidden = true,
					direction = "float",
					float_opts = {
						border = "double",
					},
					close_on_exit = false,
					on_open = function()
						vim.cmd("startinsert!")
					end,
				})

				custom_term:toggle()
			end

			-- Keybinding to run current file in terminal
			vim.keymap.set("n", "<leader>tt", function()
				local file_path = vim.fn.expand("%:p")
				_G.run_jest_test(file_path)
			end, { desc = "Run current test file in terminal" })

			-- Open test terminal with default command
			vim.keymap.set("n", "<leader>tT", function()
				test_term:toggle()
			end, { desc = "Toggle test terminal" })
		end,
	},
}
