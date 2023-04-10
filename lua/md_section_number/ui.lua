-- for test: vim.cmd([[let &runtimepath.="," . getcwd()]])

local parser = require("md_section_number.title.parser")

local M = {}

M.options = {
  width = 30,
  position = "right",
  indent_space_number = 2,
  header_prefix = "- ",
  winopts = {
    number = false,
    relativenumber = false,
    wrap = false,
    equalalways = false,
    winfixwidth = true,
    list = false,
    spell = false,
  },
  bufopts = {
    bufhidden = "wipe",
    filetype = "tagbar",
    modifiable = false,
  },
}

function M.setup(opts)
  M.options.width = opts.width or M.options.width
  M.options.position = opts.position or M.options.position
end

M.viewBind = {
  MdBufNumber = nil,
  MdHeaders = nil,
  TocWin = nil,
  TocBuf = nil,
  BindBuf = nil,
  BindWin = nil,
}

local bindBufGroup = vim.api.nvim_create_augroup("MdBindBufAutoCmd", {})

function M.unbind()
  if M.viewBind.BindBuf then
    vim.api.nvim_clear_autocmds({
      group = bindBufGroup,
      buffer = M.viewBind.BindBuf,
    })
  end
  M.viewBind = {}
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
  for k,v in pairs(M.options.bufopts) do
    vim.api.nvim_buf_set_option(buf, k, v)
  end
  for k, v in pairs(M.options.winopts) do
    vim.opt_local[k] = v
  end
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
  if not M.viewBind.BindBuf then
    return
  end
  M.viewBind.MdHeaders = parser.get_heading_lines(vim.api.nvim_buf_get_lines(M.viewBind.BindBuf, 0, -1, false))
end

local function render_headers()
  vim.api.nvim_buf_set_option(M.viewBind.TocBuf, "modifiable", true)
  reload_headers()
  -- get header text
  local all_headers_with_indent = {}
  for _, header in ipairs(M.viewBind.MdHeaders) do
    table.insert(all_headers_with_indent, add_indent_for_header(header))
  end
  -- clear
  vim.api.nvim_buf_set_lines(M.viewBind.TocBuf, 0, -1, false, {})
  -- reset
  vim.api.nvim_buf_set_lines(M.viewBind.TocBuf, 0, -1, false, all_headers_with_indent)
  vim.api.nvim_buf_set_option(M.viewBind.TocBuf, "modifiable", false)
end

function M.jump_header()
  if not M.viewBind.MdHeaders then
    reload_headers()
  end
  local header_index = math.min(vim.api.nvim_win_get_cursor(0)[1], #M.viewBind.MdHeaders)
  local line_number =
    math.min(M.viewBind.MdHeaders[header_index][1] + 1, vim.api.nvim_buf_line_count(M.viewBind.BindBuf))
  vim.api.nvim_set_current_win(M.viewBind.BindWin)
  vim.api.nvim_win_set_cursor(M.viewBind.BindWin, { line_number, 0 })
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
      M.close(M.viewBind.TocWin)
    end,
    r = function()
      local origin_position = vim.api.nvim_win_get_cursor(M.viewBind.TocWin)
      render_headers()
      local new_line_number = vim.api.nvim_buf_line_count(M.viewBind.TocBuf)
      if new_line_number == 0 then
        return
      end
      local row = math.min(new_line_number, origin_position[1])
      local line = vim.api.nvim_buf_get_lines(M.viewBind.TocBuf, row - 1, row, false)[1]
      if line == nil then
        line = ""
      end
      local col = math.min(#line, origin_position[2])
      vim.api.nvim_win_set_cursor(M.viewBind.TocWin, { row, col })
    end,
  }
  for k, v in pairs(mappings) do
    vim.keymap.set("n", k, v, { buffer = M.viewBind.TocBuf, silent = true, noremap = true })
  end
end

local function set_autocmd()
  vim.api.nvim_create_autocmd("WinClosed", {
    buffer = M.viewBind.TocBuf,
    callback = function()
      M.unbind()
    end,
  })
  -- TODO: after write，reparse heading, and rerender
  -- TODO: when move curosr，auto select side bar heading. (CursorHold event)
end

function M.open_side_window()
  M.viewBind.BindBuf = vim.api.nvim_get_current_buf()
  M.viewBind.BindWin = vim.api.nvim_get_current_win()

  local win, buf = create_side_window()
  M.viewBind.TocWin = win
  M.viewBind.TocBuf = buf

  render_headers()
  set_mappings()
  set_autocmd()
end

function M.toggle()
  if M.viewBind.TocWin then
    M.close(M.viewBind.TocWin)
  else
    M.open_side_window()
  end
end

-- TODO: when switch to other buffer，reload or close side window. (global event)
return M
