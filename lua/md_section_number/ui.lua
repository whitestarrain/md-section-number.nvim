-- for test: vim.cmd([[let &runtimepath.="," . getcwd()]])

local parser = require("md_section_number.title.parser")

local M = {}

M.options = {
  width = 30,
  position = "right",
  indent_space_number = 2,
  header_prefix = "- ",
}

function M.setup(opts)
  M.options.width = opts.width or M.options.width
  M.options.position = opts.position or M.options.position
end

M.global = {
  MdBufNumber = nil,
  MdHeaders = nil,
  TocWin = nil,
  TocBuf = nil,
  BindBuf = nil,
  BindWin = nil,
}

local bindBufGroup = vim.api.nvim_create_augroup("MdBindBufAutoCmd", {})

function M.unbind()
  if M.global.BindBuf then
    vim.api.nvim_clear_autocmds({
      group = bindBufGroup,
      buffer = M.global.BindBuf,
    })
  end
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
  vim.api.nvim_win_set_width(win, M.options.width)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "filetype", "tagbar")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.opt_local["number"] = false
  vim.opt_local["relativenumber"] = false
  vim.opt_local["wrap"] = false
  vim.opt_local["equalalways"] = false
  vim.opt_local["winfixwidth"] = true
  vim.opt_local["list"] = false
  vim.opt_local["spell"] = false
  return win, buf
end

local function add_indent_for_header(header)
  local header_str = header[2]
  local indent_str = string.rep(" ", M.options.indent_space_number)
  header_str = M.options.header_prefix .. vim.trim(header_str:gsub("#", "", header[3]))
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

local function render_headers()
  vim.api.nvim_buf_set_option(M.global.TocBuf, "modifiable", true)
  reload_headers()
  -- get header text
  local all_headers_with_indent = {}
  for _, header in ipairs(M.global.MdHeaders) do
    table.insert(all_headers_with_indent, add_indent_for_header(header))
  end
  -- clear
  vim.api.nvim_buf_set_lines(M.global.TocBuf, 0, -1, false, {})
  -- reset
  vim.api.nvim_buf_set_lines(M.global.TocBuf, 0, -1, false, all_headers_with_indent)
  vim.api.nvim_buf_set_option(M.global.TocBuf, "modifiable", false)
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
  M.unbind()
  vim.api.nvim_win_close(win, true)
end

local function set_mappings()
  local mappings = {
    ["<cr>"] = M.jump_header,
    q = function()
      M.close(M.global.TocWin)
    end,
    r = function()
      local origin_position = vim.api.nvim_win_get_cursor(M.global.TocWin)
      render_headers()
      local new_line_number = vim.api.nvim_buf_line_count(M.global.TocBuf)
      if new_line_number == 0 then
        return
      end
      local row = math.min(new_line_number, origin_position[1])
      local line = vim.api.nvim_buf_get_lines(M.global.TocBuf, row - 1, row, false)[1]
      if line == nil then
        line = ""
      end
      local col = math.min(#line, origin_position[2])
      vim.api.nvim_win_set_cursor(M.global.TocWin, { row, col })
    end,
  }
  for k, v in pairs(mappings) do
    vim.keymap.set("n", k, v, { buffer = M.global.TocBuf, silent = true, noremap = true })
  end
end

local function set_autocmd()
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = M.global.TocBuf,
    callback = function()
      M.unbind()
    end,
  })
  -- TODO: after write，reparse heading, and rerender
  -- TODO: when move curosr，auto select side bar heading. (CursorHold event)
end

function M.open_side_window()
  M.global.BindBuf = vim.api.nvim_get_current_buf()
  M.global.BindWin = vim.api.nvim_get_current_win()

  local win, buf = create_side_window()
  M.global.TocWin = win
  M.global.TocBuf = buf

  render_headers()
  set_mappings()
  set_autocmd()
end

function M.toggle()
  if M.global.TocWin then
    M.close(M.global.TocWin)
  else
    M.open_side_window()
  end
end

-- TODO: when switch to other buffer，reload or close side window. (global event)
return M
