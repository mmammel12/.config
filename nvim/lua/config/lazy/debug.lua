return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			-- UI for DAP
			"rcarriga/nvim-dap-ui",
			-- Virtual text for debugging
			"theHamsta/nvim-dap-virtual-text",
			-- DAP utilities
			"nvim-telescope/telescope-dap.nvim",
			-- JavaScript/TypeScript adapter
			"microsoft/vscode-js-debug",
			-- Go adapter (Delve integration)
			"leoluz/nvim-dap-go",
			-- Required for dap-ui
			"nvim-neotest/nvim-nio",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			-- Setup DAP UI
			dapui.setup({
				icons = { expanded = "▾", collapsed = "▸", current_frame = "→" },
				mappings = {
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				-- Use a tabbed layout with floating windows
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 },
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						size = 40,
						position = "left", -- Can be "left", "right", "top", "bottom"
					},
					{
						elements = {
							{ id = "repl", size = 0.5 },
							{ id = "console", size = 0.5 },
						},
						size = 10,
						position = "bottom", -- Can be "left", "right", "top", "bottom"
					},
				},
				controls = {
					-- Requires Neovim nightly (or 0.8 when released)
					enabled = true,
					-- Display controls in this element
					element = "repl",
					icons = {
						pause = "",
						play = "",
						step_into = "",
						step_over = "",
						step_out = "",
						step_back = "",
						run_last = "",
						terminate = "",
					},
				},
				floating = {
					max_height = nil, -- These can be integers or a float between 0 and 1.
					max_width = nil, -- Floats will be treated as percentage of your screen.
					border = "rounded", -- Border style
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
				windows = { indent = 1 },
				render = {
					max_type_length = nil, -- Can be integer or nil.
					max_value_lines = 100, -- Can be integer or nil.
				},
			})

			-- Enable virtual text for debugging
			require("nvim-dap-virtual-text").setup({
				enabled = true,
				enabled_commands = true,
				highlight_changed_variables = true,
				highlight_new_as_changed = false,
				show_stop_reason = true,
				commented = false,
				only_first_definition = true,
				all_references = false,
				virt_text_pos = "eol",
			})

			-- Configure JS/TS debugging adapter
			require("dap").adapters["pwa-node"] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = {
					command = "node",
					args = {
						-- You'll need to install this globally via npm
						vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
						"${port}",
					},
				},
			}

			-- JavaScript/TypeScript configurations
			dap.configurations.javascript = {
				{
					type = "pwa-node",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					cwd = "${workspaceFolder}",
					sourceMaps = true,
				},
				{
					type = "pwa-node",
					request = "attach",
					name = "Attach",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
					sourceMaps = true,
				},
				{
					type = "pwa-node",
					request = "launch",
					name = "Debug Jest Tests",
					runtimeExecutable = "node",
					runtimeArgs = {
						"./node_modules/jest/bin/jest.js",
						"--runInBand",
					},
					rootPath = "${workspaceFolder}",
					cwd = "${workspaceFolder}",
					console = "integratedTerminal",
					internalConsoleOptions = "neverOpen",
					sourceMaps = true,
				},
			}

			dap.configurations.typescript = dap.configurations.javascript
			dap.configurations.javascriptreact = dap.configurations.javascript
			dap.configurations.typescriptreact = dap.configurations.javascript

			-- Configure Go debugging
			require("dap-go").setup({
				-- Additional dap configurations can be added
				-- dap_configurations = {},
				delve = {
					-- Path to the delve command
					path = "dlv",
					-- Additional args for delve
					args = {},
					-- Build flags for tests (e.g. -tags=unit)
					build_flags = "",
				},
			})

			-- Open and close DAP UI automatically
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end

			-- Key mappings
			vim.keymap.set("n", "<leader>db", function()
				require("dap").toggle_breakpoint()
			end, { desc = "Toggle Breakpoint" })
			vim.keymap.set("n", "<leader>dB", function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end, { desc = "Set Conditional Breakpoint" })
			vim.keymap.set("n", "<leader>dc", function()
				require("dap").continue()
			end, { desc = "Continue" })
			vim.keymap.set("n", "<leader>do", function()
				require("dap").step_over()
			end, { desc = "Step Over" })
			vim.keymap.set("n", "<leader>di", function()
				require("dap").step_into()
			end, { desc = "Step Into" })
			vim.keymap.set("n", "<leader>dt", function()
				require("dap").step_out()
			end, { desc = "Step Out" })
			vim.keymap.set("n", "<leader>dd", function()
				require("dap").disconnect()
			end, { desc = "Disconnect" })
			vim.keymap.set("n", "<leader>dr", function()
				require("dap").repl.open()
			end, { desc = "Open REPL" })
			vim.keymap.set("n", "<leader>dl", function()
				require("dap").run_last()
			end, { desc = "Run Last" })
			vim.keymap.set("n", "<leader>du", function()
				require("dapui").toggle()
			end, { desc = "Toggle UI" })

			-- Workspace-specific configurations
			vim.api.nvim_create_user_command("LoadJSDebugConfig", function()
				-- Load launch.json if it exists
				local launch_json_path = vim.fn.getcwd() .. "/.vscode/launch.json"
				if vim.fn.filereadable(launch_json_path) == 1 then
					-- Parse JSON file content and add to DAP configurations
					local file_content = vim.fn.readfile(launch_json_path)
					local json_content = table.concat(file_content, "\n")
					local status, decoded = pcall(vim.fn.json_decode, json_content)

					if status and decoded and decoded.configurations then
						-- Add all configurations from launch.json
						for _, config in ipairs(decoded.configurations) do
							if config.type and config.name and config.request then
								-- Map VS Code debug type to our adapter
								if config.type == "node" then
									config.type = "pwa-node"
								elseif config.type == "chrome" then
									config.type = "pwa-chrome"
								end

								-- Add to appropriate language configuration
								local lang = config.language or "javascript"
								if not dap.configurations[lang] then
									dap.configurations[lang] = {}
								end
								table.insert(dap.configurations[lang], config)
							end
						end
						print("Loaded VS Code launch configurations")
					else
						print("Failed to parse launch.json")
					end
				else
					print("No launch.json found in .vscode directory")
				end
			end, {})

			-- FORMATTING DEBUG COMMANDS
			-- Check which formatters are available for the current buffer
			vim.api.nvim_create_user_command("ConformInfo", function()
				local conform = require("conform")

				-- Get formatters for current buffer
				local formatters = conform.list_formatters_for_buffer()

				if vim.tbl_isempty(formatters) then
					vim.notify("No formatters available for this buffer", vim.log.levels.WARN)
				else
					local msg = "Available formatters:\n"
					for _, formatter in ipairs(formatters) do
						msg = msg
							.. "- "
							.. formatter.name
							.. " ("
							.. (formatter.available and "available" or "not available")
							.. ")\n"
					end
					vim.notify(msg, vim.log.levels.INFO)
				end
			end, {})

			-- Manually trigger formatting with debug output
			vim.api.nvim_create_user_command("FormatDebug", function()
				local conform = require("conform")

				vim.notify("Attempting to format buffer...", vim.log.levels.INFO)

				local success, error = pcall(function()
					conform.format({
						lsp_fallback = true,
						async = false,
						timeout_ms = 1000, -- Longer timeout for debugging
					})
				end)

				if not success then
					vim.notify("Formatting error: " .. vim.inspect(error), vim.log.levels.ERROR)
				else
					vim.notify("Formatting completed", vim.log.levels.INFO)
				end
			end, {})

			-- Check if formatters are installed
			vim.api.nvim_create_user_command("CheckFormatters", function()
				local formatters = {
					"prettierd",
					"stylua",
				}

				local mason_registry = require("mason-registry")
				local results = {}

				for _, formatter in ipairs(formatters) do
					local package = mason_registry.get_package(formatter)
					local installed = package:is_installed()
					results[formatter] = installed
				end

				local msg = "Formatter installation status:\n"
				for formatter, installed in pairs(results) do
					msg = msg
						.. "- "
						.. formatter
						.. ": "
						.. (installed and "Installed ✓" or "Not installed ✗")
						.. "\n"
				end

				vim.notify(msg, vim.log.levels.INFO)
			end, {})

			-- Command to reinstall formatters
			vim.api.nvim_create_user_command("ReinstallFormatters", function()
				local formatters = {
					"prettierd",
					"stylua",
				}

				for _, formatter in ipairs(formatters) do
					vim.cmd("MasonUninstall " .. formatter)
					vim.cmd("MasonInstall " .. formatter)
				end

				vim.notify("Formatters reinstalled. Restart Neovim for changes to take effect.", vim.log.levels.INFO)
			end, {})
		end,
	},

	-- Add conform.nvim debug utilities
	{
		"stevearc/conform.nvim",
		optional = true,
		config = function()
			-- This is only called if conform.nvim is already loaded elsewhere
			-- Here we can add debugging tools that won't be loaded unless needed
			vim.api.nvim_create_user_command("ConformLog", function()
				vim.cmd("edit " .. vim.fn.stdpath("log") .. "/conform.log")
			end, {})

			-- Add a command to increase logging verbosity for debugging
			vim.api.nvim_create_user_command("ConformDebugMode", function()
				require("conform").setup({
					log_level = vim.log.levels.DEBUG,
					notify_on_error = true,
				})
				vim.notify("Conform.nvim debug mode enabled", vim.log.levels.INFO)
			end, {})
		end,
	},
}
