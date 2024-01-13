local parser = require("md_section_number.heading.parser")

local M = {}

M.options = {
  width = 30,
  position = "right",
  indent_space_number = 2,
  header_prefix = "- ",
  default_display_level = 6,
  winopts = {
    number = false,
    relativenumber = false,
    wrap = false,
    winfixwidth = true,
    list = false,
    spell = false,
  },
  bufopts = {
    bufhidden = "wipe",
    filetype = "msnumber",
    modifiable = false,
  },
}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.options, opts or {})
end

M.viewBind = {
  MdHeaders = nil,
  displayLevel = nil,
  TocWin = nil,
  TocBuf = nil,
  BindBuf = nil,
  BindWin = nil,
  changeTick = nil,

  -- stat
  allMdHeaders = nil,
  maxLevel = nil,
}

local bindBufGroupName = "MSNbindBufEventGroup"
local tocBufGroupName = "MSNtocBufEventGroup"
local globalGroupName = "MSNGlobalEventGroup"

local tocHlNameSpace = vim.api.nvim_create_namespace("tocHlNameSpace")
local markdownFileType = { markdown = true, md = true }
local move_tbl = {
  left = "H",
  right = "L",
}

-- local buildInEvent = { }

local function clear_all_autocmd()
  local check_buf_valid = function(buf_id)
    return buf_id ~= nil and vim.api.nvim_buf_is_valid(buf_id)
  end
  if check_buf_valid(M.viewBind.BindBuf) then
    vim.api.nvim_clear_autocmds({ group = bindBufGroupName, buffer = M.viewBind.BindBuf })
  end
  if check_buf_valid(M.viewBind.TocBuf) then
    vim.api.nvim_clear_autocmds({ group = tocBufGroupName, buffer = M.viewBind.TocBuf })
  end
  vim.api.nvim_clear_autocmds({ group = globalGroupName })
end

function M.unbind()
  clear_all_autocmd()
  M.viewBind = {}
end

local function create_side_window()
  vim.cmd("vsplit")
  local win = vim.api.nvim_get_current_win()
  local move_to = move_tbl[M.options.position]
  vim.api.nvim_command("wincmd " .. move_to)
  vim.api.nvim_win_set_width(win, M.options.width)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  for k, v in pairs(M.options.bufopts) do
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

local function reload_headers(header_level_offset)
  local change_flag = false
  header_level_offset = header_level_offset or 0
  if not M.viewBind.BindBuf then
    return change_flag
  end
  local current_change_tick = vim.api.nvim_buf_get_changedtick(M.viewBind.BindBuf)
  if M.viewBind.allMdHeaders == nil or (M.viewBind.changeTick ~= current_change_tick) then
    M.viewBind.allMdHeaders = parser.get_heading_lines(vim.api.nvim_buf_get_lines(M.viewBind.BindBuf, 0, -1, false))
    local max_level = 1
    for _, header in ipairs(M.viewBind.allMdHeaders) do
      if header[3] > max_level then
        max_level = header[3]
      end
    end
    M.viewBind.maxLevel = max_level
    change_flag = true
  end
  M.viewBind.changeTick = current_change_tick

  -- display level
  local currentDisplayLevel = M.viewBind.displayLevel
  if M.viewBind.displayLevel == nil then
    M.viewBind.displayLevel = M.viewBind.maxLevel
  end
  if header_level_offset ~= 0 then
    M.viewBind.displayLevel = math.max(1, math.min(M.viewBind.displayLevel + header_level_offset, M.viewBind.maxLevel))
  end
  if change_flag or currentDisplayLevel == nil or currentDisplayLevel ~= M.viewBind.displayLevel then
    change_flag = true
    local display_header = {}
    for _, header in ipairs(M.viewBind.allMdHeaders) do
      if header[3] > M.viewBind.displayLevel then
        goto continue
      end
      table.insert(display_header, header)
      ::continue::
    end
    M.viewBind.MdHeaders = display_header
  end

  return change_flag
end

local function render_headers(header_level_offset)
  -- get change flag, update headers
  local change_flag = reload_headers(header_level_offset)
  if not change_flag then
    return
  end
  -- start update
  vim.api.nvim_buf_set_option(M.viewBind.TocBuf, "modifiable", true)
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

local function get_toc_index(lineNumber)
  if not M.viewBind.MdHeaders or #M.viewBind.MdHeaders == 0 then
    return 1
  end
  lineNumber = lineNumber or vim.api.nvim_win_get_cursor(M.viewBind.BindWin)[1]
  local left = 1
  local right = #M.viewBind.MdHeaders
  if lineNumber < M.viewBind.MdHeaders[left][1] then
    return left
  end
  if lineNumber > M.viewBind.MdHeaders[right][1] then
    return right
  end
  while left <= right do
    local middle = math.floor((left + right) / 2)
    local middleVal = M.viewBind.MdHeaders[middle][1] + 1
    if middleVal == lineNumber then
      return middle
    elseif lineNumber > middleVal then
      left = middle + 1
    elseif lineNumber < middleVal then
      right = middle - 1
    end
  end
  return math.max(math.min(left, right), 1)
end

local function set_toc_position(contentLinenumber)
  local index = get_toc_index(contentLinenumber)
  vim.api.nvim_win_set_cursor(M.viewBind.TocWin, { index, 0 })
  vim.api.nvim_buf_clear_namespace(M.viewBind.TocBuf, tocHlNameSpace, 0, -1)
  vim.api.nvim_buf_add_highlight(M.viewBind.TocBuf, tocHlNameSpace, "Search", index - 1, 0, -1)
end

local function jump_header()
  if not M.viewBind.MdHeaders then
    reload_headers()
  end
  local header_index = math.min(vim.api.nvim_win_get_cursor(0)[1], #M.viewBind.MdHeaders)
  local line_number =
    math.min(M.viewBind.MdHeaders[header_index][1] + 1, vim.api.nvim_buf_line_count(M.viewBind.BindBuf))
  vim.api.nvim_win_set_buf(M.viewBind.BindWin, M.viewBind.BindBuf)
  vim.api.nvim_set_current_win(M.viewBind.BindWin)
  vim.api.nvim_win_set_cursor(M.viewBind.BindWin, { line_number, 0 })
  vim.api.nvim_feedkeys("zz", "n", false)
  set_toc_position()
end

function M.closeToc()
  if not M.viewBind.TocWin then
    return
  end
  vim.api.nvim_win_close(M.viewBind.TocWin, true)
  M.unbind()
end

local function set_mappings()
  local function change_display_level(levelOffset)
    return function()
      local header_index = vim.api.nvim_win_get_cursor(M.viewBind.TocWin)[1]
      local content_linenumber = M.viewBind.MdHeaders[header_index][1] + 1
      render_headers(levelOffset)
      set_toc_position(content_linenumber)
      vim.api.nvim_feedkeys("zz", "n", false)
    end
  end
  local mappings = {
    ["<cr>"] = jump_header,
    q = function()
      M.closeToc()
    end,
    r = function()
      local origin_position = vim.api.nvim_win_get_cursor(M.viewBind.TocWin)
      render_headers()
      local line_count = vim.api.nvim_buf_line_count(M.viewBind.TocBuf)
      if line_count == 0 then
        return
      end
      local row = get_toc_index()
      local line = vim.api.nvim_buf_get_lines(M.viewBind.TocBuf, row - 1, row, false)[1]
      if line == nil then
        line = ""
      end
      local col = math.min(#line, origin_position[2])
      vim.api.nvim_win_set_cursor(M.viewBind.TocWin, { row, col })
    end,
    ["h"] = change_display_level(-1),
    ["l"] = change_display_level(1),
    ["W"] = change_display_level(-5),
    ["E"] = change_display_level(5),
  }
  for k, v in pairs(mappings) do
    vim.keymap.set("n", k, v, { buffer = M.viewBind.TocBuf, silent = true, noremap = true })
  end
end

local function set_bind_buf_autocmd()
  local bindBufEventGroup = vim.api.nvim_create_augroup(bindBufGroupName, { clear = true })
  vim.api.nvim_create_autocmd({ "BufWritePost" }, {
    group = bindBufEventGroup,
    buffer = M.viewBind.BindBuf,
    callback = vim.schedule_wrap(function()
      render_headers()
      set_toc_position()
    end),
  })
  vim.api.nvim_create_autocmd("CursorHold", {
    group = bindBufEventGroup,
    buffer = M.viewBind.BindBuf,
    callback = vim.schedule_wrap(function()
      set_toc_position()
    end),
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = bindBufEventGroup,
    buffer = M.viewBind.BindBuf,
    callback = vim.schedule_wrap(function()
      if vim.api.nvim_get_current_win() == M.viewBind.TocWin then
        return
      end
      M.closeToc()
    end),
  })
end

local function set_toc_buf_autocmd()
  local tocBufEventGroup = vim.api.nvim_create_augroup(tocBufGroupName, { clear = true })
  vim.api.nvim_create_autocmd({ "WinClosed", "QuitPre" }, {
    group = tocBufEventGroup,
    buffer = M.viewBind.TocBuf,
    callback = function()
      M.unbind()
    end,
  })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = tocBufEventGroup,
    buffer = M.viewBind.TocBuf,
    callback = vim.schedule_wrap(function()
      if M.viewBind.BindWin == nil or not vim.api.nvim_win_is_valid(M.viewBind.BindWin) then
        M.unbind()
        return
      end

      local currentBuf = vim.api.nvim_win_get_buf(M.viewBind.BindWin)
      if currentBuf ~= M.viewBind.BindBuf then
        return
      end
      render_headers()
      set_toc_position()
    end),
  })
end

local function switch_bind()
  -- no toc
  if not M.viewBind.TocBuf then
    return
  end
  -- filetype judgment
  local filetype = vim.api.nvim_buf_get_option(0, "filetype")
  if not markdownFileType[filetype] then
    return
  end
  local bind_buf = vim.api.nvim_get_current_buf()
  local bind_win = vim.api.nvim_get_current_win()
  if bind_buf == M.viewBind.BindBuf and bind_win == M.viewBind.BindWin then
    return
  end
  if bind_buf ~= M.viewBind.BindBuf then
    M.viewBind.BindBuf = bind_buf
    M.viewBind.MdHeaders = nil
    render_headers()
  end
  if bind_buf ~= M.viewBind.BindWin then
    M.viewBind.BindWin = bind_win
  end
  set_bind_buf_autocmd()
  set_toc_position()
end

local function set_autocmd()
  -- toc buf autocmd
  set_toc_buf_autocmd()
  -- bind buf autocmd
  set_bind_buf_autocmd()
  -- global autocmd

  local globalEventGroup = vim.api.nvim_create_augroup(globalGroupName, { clear = true })
  vim.api.nvim_create_autocmd("BufEnter", {
    group = globalEventGroup,
    pattern = "*.md,*.markdown",
    callback = vim.schedule_wrap(switch_bind),
  })
  vim.api.nvim_create_autocmd("WinEnter", {
    group = globalEventGroup,
    pattern = "*.md,*.markdown",
    callback = vim.schedule_wrap(function()
      local currentBuf = vim.api.nvim_win_get_buf(0)
      if currentBuf == M.viewBind.BindBuf then
        M.viewBind.BindWin = vim.api.nvim_get_current_win()
        return
      end
    end),
  })
  vim.api.nvim_create_autocmd("QuitPre", {
    group = globalEventGroup,
    pattern = "*.md,*.markdown",
    callback = vim.schedule_wrap(function()
      local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())
      local non_essential_window_flag = #wins == 1 and wins[1] == M.viewBind.TocWin

      -- support for some session function(like vim-startify)
      if non_essential_window_flag then
        local current_buf = M.viewBind.BindBuf
        local toc_win = M.viewBind.TocWin
        M.unbind()
        vim.api.nvim_set_current_buf(current_buf)
        vim.cmd(":quit")
      end
    end),
  })
end

local function focus_origin_position()
  if not M.viewBind.BindWin then
    return
  end
  vim.api.nvim_set_current_win(M.viewBind.BindWin)
end

function M.openToc()
  if M.viewBind.TocWin then
    return
  end
  M.viewBind.BindBuf = vim.api.nvim_get_current_buf()
  M.viewBind.BindWin = vim.api.nvim_get_current_win()

  local win, buf = create_side_window()
  M.viewBind.TocWin = win
  M.viewBind.TocBuf = buf

  render_headers()
  set_mappings()
  set_autocmd()
  focus_origin_position()
end

function M.toggle()
  if M.viewBind.TocWin then
    M.closeToc()
  else
    M.openToc()
  end
end

return M
