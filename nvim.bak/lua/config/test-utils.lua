local M = {}

-- Function to parse the test file and extract test names
function M.parse_test_file()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local tests = {}

	-- Look for patterns like 'it('test name', function() {'
	for i, line in ipairs(lines) do
		local test_name = line:match("it%(['\"](.-)['\"]")
		if test_name then
			table.insert(tests, {
				name = test_name,
				line = i - 1, -- 0-based index for nvim API
			})
		end

		-- Also catch describe blocks
		local describe_name = line:match("describe%(['\"](.-)['\"]")
		if describe_name then
			table.insert(tests, {
				name = describe_name,
				line = i - 1,
				is_describe = true,
			})
		end
	end

	return tests
end

-- Function to run the test at current cursor position
function M.run_test_at_cursor()
	local tests = M.parse_test_file()
	if #tests == 0 then
		vim.notify("No tests found in current file", vim.log.levels.WARN)
		return
	end

	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based index
	local closest_test = nil
	local min_distance = math.huge

	-- Find the test closest to the cursor
	for _, test in ipairs(tests) do
		local distance = math.abs(cursor_line - test.line)
		if distance < min_distance then
			min_distance = distance
			closest_test = test
		end
	end

	-- Get the test name
	if closest_test then
		local file_path = vim.fn.expand("%:p")
		local test_name = closest_test.name

		-- If using toggleterm
		if package.loaded["toggleterm"] then
			if _G.run_jest_test then
				_G.run_jest_test(file_path, test_name)
			end
		else
			-- Fallback to running with standard terminal
			local cmd = string.format("npm test -- %s -t '%s'", file_path, test_name)
			vim.cmd("split | terminal " .. cmd)
			vim.cmd("startinsert")
		end
	end
end

-- Function to jump to the next test
function M.jump_to_next_test()
	local tests = M.parse_test_file()
	if #tests == 0 then
		vim.notify("No tests found in current file", vim.log.levels.WARN)
		return
	end

	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based index
	local next_test = nil

	-- Find the next test after cursor
	for _, test in ipairs(tests) do
		if test.line > cursor_line then
			next_test = test
			break
		end
	end

	-- If no test found after cursor, wrap around to the first test
	if not next_test and #tests > 0 then
		next_test = tests[1]
	end

	-- Jump to the test
	if next_test then
		vim.api.nvim_win_set_cursor(0, { next_test.line + 1, 0 }) -- 1-based line index
		vim.cmd("normal! zz") -- Center the screen on the test
	end
end

-- Function to jump to the previous test
function M.jump_to_prev_test()
	local tests = M.parse_test_file()
	if #tests == 0 then
		vim.notify("No tests found in current file", vim.log.levels.WARN)
		return
	end

	local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-based index
	local prev_test = nil

	-- Find the previous test before cursor
	for i = #tests, 1, -1 do
		if tests[i].line < cursor_line then
			prev_test = tests[i]
			break
		end
	end

	-- If no test found before cursor, wrap around to the last test
	if not prev_test and #tests > 0 then
		prev_test = tests[#tests]
	end

	-- Jump to the test
	if prev_test then
		vim.api.nvim_win_set_cursor(0, { prev_test.line + 1, 0 }) -- 1-based line index
		vim.cmd("normal! zz") -- Center the screen on the test
	end
end

-- Creates a test template at cursor position
function M.create_test_template()
	local test_name = vim.fn.input("Test name: ")
	if test_name == "" then
		return
	end

	local template = {
		"it('" .. test_name .. "', () => {",
		"  // Arrange",
		"  ",
		"  // Act",
		"  ",
		"  // Assert",
		"  expect().toBe();",
		"});",
		"",
	}

	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line = cursor_pos[1] - 1 -- 0-based index

	vim.api.nvim_buf_set_lines(0, line, line, false, template)
	vim.api.nvim_win_set_cursor(0, { line + 3, 2 }) -- Position cursor at "Arrange" section
	vim.cmd("normal! zz") -- Center the screen
end

-- Setup keymappings
function M.setup_keymaps()
	local opts = { noremap = true, silent = true }

	-- Test navigation
	vim.keymap.set("n", "]t", M.jump_to_next_test, { desc = "Jump to next test" })
	vim.keymap.set("n", "[t", M.jump_to_prev_test, { desc = "Jump to previous test" })

	-- Run test at cursor
	vim.keymap.set("n", "<leader>tc", M.run_test_at_cursor, { desc = "Run test at cursor" })

	-- Create test template
	vim.keymap.set("n", "<leader>tn", M.create_test_template, { desc = "Create new test" })
end

return M
