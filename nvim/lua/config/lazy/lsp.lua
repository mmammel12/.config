return {
	{
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	{ -- LSP Configuration & Plugins
		"neovim/nvim-lspconfig",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
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
			-- Disable LSP formatting to avoid conflicts with conform.nvim
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-format-disable", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					-- Disable formatting capabilities for each client to prevent conflicts with conform.nvim
					client.server_capabilities.documentFormattingProvider = false
					client.server_capabilities.documentRangeFormattingProvider = false
				end,
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- Document highlighting on cursor hold
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- Inlay hints toggle
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "[T]oggle Inlay [H]ints")
					end

					-- Add additional keymaps for better IDE experience
					map("gd", vim.lsp.buf.definition, "Go to [D]efinition")
					map("gD", vim.lsp.buf.declaration, "Go to [D]eclaration")
					map("gr", vim.lsp.buf.references, "Go to [R]eferences")
					map("gi", vim.lsp.buf.implementation, "Go to [I]mplementation")
					map("K", vim.lsp.buf.hover, "Hover Documentation")
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("<leader>D", vim.lsp.buf.type_definition, "Type [D]efinition")
				end,
			})

			-- Get nvim-cmp capabilities if available
			local capabilities = vim.g.cmp_capabilities or vim.lsp.protocol.make_client_capabilities()

			-- Extend server configurations
			local servers = {
				lua_ls = {
					settings = {
						Lua = {
							completion = {
								callSnippet = "Replace",
							},
							diagnostics = { disable = { "missing-fields" } },
						},
					},
				},
				-- TypeScript server configuration
				tsserver = {
					settings = {
						typescript = {
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
						javascript = {
							inlayHints = {
								includeInlayParameterNameHints = "all",
								includeInlayParameterNameHintsWhenArgumentMatchesName = false,
								includeInlayFunctionParameterTypeHints = true,
								includeInlayVariableTypeHints = true,
								includeInlayPropertyDeclarationTypeHints = true,
								includeInlayFunctionLikeReturnTypeHints = true,
								includeInlayEnumMemberValueHints = true,
							},
						},
					},
				},
				-- Go language server configuration
				gopls = {
					settings = {
						gopls = {
							analyses = {
								unusedparams = true,
							},
							staticcheck = true,
							gofumpt = true,
							usePlaceholders = true,
							hints = {
								assignVariableTypes = true,
								compositeLiteralFields = true,
								compositeLiteralTypes = true,
								constantValues = true,
								functionTypeParameters = true,
								parameterNames = true,
								rangeVariableTypes = true,
							},
						},
					},
				},
				-- ESLint configuration for JS/TS linting
				eslint = {
					-- Modified to not run EslintFixAll on save to prevent conflicts with conform.nvim
					-- Instead, rely on conform.nvim for formatting and use ESLint for diagnostics only
					settings = {
						-- Add ESLint specific settings here if needed
						packageManager = "npm",
						workingDirectory = { mode = "location" },
						rulesCustomizations = {},
						useESLintClass = true,
					},
				},
			}

			-- Ensure all required tools are installed
			local ensure_installed = vim.tbl_keys(servers or {})
			vim.list_extend(ensure_installed, {
				-- Formatters
				"prettierd",
				"stylua",
				-- Linters
				"eslint_d",
				-- Language servers
				"gopls",
				"tsserver",
				"html",
				"cssls",
				"jsonls",
				"eslint",
				"tailwindcss",
				"templ",
				"htmx-lsp",
				-- Debug adapters
				"js-debug-adapter",
				"delve",
			})

			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	-- Keep existing Go configuration
	{
		"ray-x/go.nvim",
		dependencies = {
			"ray-x/guihua.lua",
			"neovim/nvim-lspconfig",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("go").setup({
				-- Enhanced Go settings
				lsp_inlay_hints = {
					enable = true,
					-- Only show parameter hints for long parameter lists
					only_current_line = false,
					-- Show variable type hints
					show_variable_name = true,
					-- Parameter hints prefix
					parameter_hints_prefix = " ",
					-- Other hints prefix
					other_hints_prefix = "=> ",
				},
				-- Go test settings
				test_runner = "go",
				run_in_floaterm = true,
				-- Auto linting and formatting on save
				lsp_codelens = true,
				dap_debug = true,
				dap_debug_gui = true,

				-- Disable gopls's formatting to avoid conflicts with conform.nvim
				gofmt = false, -- Disable gofmt through gopls, let conform.nvim handle it
				lsp_document_formatting = false,

				-- Add keymappings for Go-specific operations
				trouble = true,
				luasnip = true,
			})

			-- Go keymappings
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
			end

			-- Only apply in Go files
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "go", "gomod" },
				callback = function()
					-- Go specific keymaps
					local opts = { buffer = true }
					map("n", "<leader>gfs", "<cmd>GoFillStruct<CR>", "Go Fill Struct")
					map("n", "<leader>gtt", "<cmd>GoTest<CR>", "Go Test")
					map("n", "<leader>gtf", "<cmd>GoTestFunc<CR>", "Go Test Function")
					map("n", "<leader>gie", "<cmd>GoIfErr<CR>", "Go Add If Err")
					map("n", "<leader>gai", "<cmd>GoImport<CR>", "Go Add Import")
					map("n", "<leader>gaa", "<cmd>GoImportAll<CR>", "Go Import All")
				end,
			})
		end,
		event = { "CmdlineEnter" },
		ft = { "go", "gomod" },
		build = ':lua require("go.install").update_all_sync()',
	},

	-- Keep typescript-tools with slight enhancements
	{
		"pmizio/typescript-tools.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			local api = require("typescript-tools.api")
			require("typescript-tools").setup({
				handlers = {
					["textDocument/publishDiagnostics"] = function()
						-- Filter out unnecessary diagnostics
						api.filter_diagnostics({
							-- 80001 = "File is a CommonJS module; it may be converted to an ES module."
							80001,
							-- 7016 = "Could not find a declaration file for module..."
							7016,
						})
					end,
				},
				settings = {
					-- Expose commands to organize imports, fix all, etc.
					expose_as_code_action = { "organize_imports", "remove_unused", "fix_all" },
					-- Faster tsserver
					tsserver_path = nil,
					tsserver_plugins = {},
					tsserver_max_memory = "auto",
					tsserver_format_options = {
						allowIncompleteCompletions = true,
						allowRenameOfImportPath = true,
					},
					-- Enable completions with auto imports
					complete_function_calls = true,
					include_completions_with_insert_text = true,
					-- Disable formatting to avoid conflicts with conform.nvim
					tsserver_file_preferences = {
						includeInlayParameterNameHints = "all",
						includeInlayEnumMemberValueHints = true,
						includeInlayFunctionLikeReturnTypeHints = true,
						includeInlayFunctionParameterTypeHints = true,
						includeInlayPropertyDeclarationTypeHints = true,
						includeInlayVariableTypeHints = true,
					},
				},
			})

			-- Add React and TS-specific keymaps
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
				callback = function()
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = true, desc = desc })
					end

					map("<leader>tso", ":TSToolsOrganizeImports<CR>", "Organize Imports")
					map("<leader>tss", ":TSToolsSortImports<CR>", "Sort Imports")
					map("<leader>tsr", ":TSToolsRemoveUnusedImports<CR>", "Remove Unused Imports")
					map("<leader>tsf", ":TSToolsFixAll<CR>", "Fix All")
					map("<leader>tsd", ":TSToolsGoToSourceDefinition<CR>", "Go To Source Definition")
					map("<leader>tsa", ":TSToolsAddMissingImports<CR>", "Add Missing Imports")
					map("<leader>trr", ":TSToolsRenameFile<CR>", "Rename File")
				end,
			})
		end,
	},

	-- Add React-specific enhancements
	{
		"neovim/nvim-lspconfig",
		ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- Add JSX/TSX specific comment string
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "javascriptreact", "typescriptreact" },
				callback = function()
					vim.bo.commentstring = "{/* %s */}"
				end,
			})
		end,
	},
}
