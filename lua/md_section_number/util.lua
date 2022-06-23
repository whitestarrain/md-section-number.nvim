local M = {}

function M.update_line(start_line, line_content)
	vim.api.nvim_buf_set_lines(0, start_line, start_line + 1, false, { line_content })
end

return M
