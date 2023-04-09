-- for test: vim.cmd([[let &runtimepath.="," . getcwd()]])

local parser = require("md_section_number.title.parser")

local M = {}

M.options = {
  width = 30,
  position = "right",
  indent_space_number = 1,
}

function M.setup(opts)
  M.options.width = opts.width or M.options.width
  M.options.position = opts.position or M.options.position
end

M.global = {
  MdBufNumber = nil,
  MdHeaders = nil,
  CurrentWin = nil,
  BindBuf = nil,
  BindWin = nil,
}

function M.clear_key_value()
  M.global = {}
end

local move_tbl = {
  left = "H",
  right = "L",
}

local function create_side_window()
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  local move_to = move_tbl[M.options.position]
  vim.api.nvim_command("wincmd " .. move_to)
  vim.opt_local["number"] = false
  vim.opt_local["relativenumber"] = false
  vim.opt_local["wrap"] = false
  vim.opt_local["equalalways"] = false
  vim.api.nvim_win_set_width(win, M.options.width)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "tagbar")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  return win, buf
end

local function add_indent_for_header(header)
  local header_str = header[2]
  local indent_str = string.rep(" ", M.options.indent_space_number)
  header_str = vim.trim(header_str:gsub("#", "", header[3]))
  if header[3] > 1 then
    header_str = string.rep(indent_str, header[3] - 1) .. header_str
  end
  return header_str
end

local function reload_headers()
  if not M.global.BindBuf then
    return
  end
  M.global.MdHeaders = parser.get_heading_lines(vim.api.nvim_buf_get_lines(M.global.BindBuf, 0, -1, false))
end

local function render_headers(buf)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  reload_headers()
  local all_headers_with_indent = {}
  for _, header in ipairs(M.global.MdHeaders) do
    table.insert(all_headers_with_indent, add_indent_for_header(header))
  end
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_headers_with_indent)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

function M.jump_header()
  if not M.global.MdHeaders then
    reload_headers()
  end
  local header_index = math.min(vim.api.nvim_win_get_cursor(0)[1], #M.global.MdHeaders)
  local line_number = math.min(M.global.MdHeaders[header_index][1] + 1, vim.api.nvim_buf_line_count(M.global.BindBuf))
  vim.api.nvim_set_current_win(M.global.BindWin)
  vim.api.nvim_win_set_cursor(M.global.BindWin, { line_number, 0 })
  vim.api.nvim_feedkeys("zz", "n", false)
end

function M.close(win)
  if not win then
    return
  end
  M.clear_key_value()
  vim.api.nvim_win_close(win, true)
end

local function set_mappings(win, buf)
  vim.keymap.set("n", "<cr>", M.jump_header, { buffer = buf })
  vim.keymap.set("n", "q", function()
    M.close(win)
  end, { buffer = buf })
end

local function set_autocmd(buf)
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = buf,
    callback = function()
      M.clear_key_value()
    end,
  })
end

function M.open_side_window()
  M.global.BindBuf = vim.api.nvim_get_current_buf()
  M.global.BindWin = vim.api.nvim_get_current_win()

  local win, buf = create_side_window()
  M.global.CurrentWin = win
  render_headers(buf)
  set_mappings(win, buf)
  set_autocmd(buf)
end

function M.toggle()
  if M.global.CurrentWin then
    M.close(M.global.CurrentWin)
  else
    M.open_side_window()
  end
end

-- TODO: when change buffer，reload or close side window
-- TODO: after edit，reparse heading

return M
