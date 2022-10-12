local parser = require("md_section_number.parser")
local replacer = require("md_section_number.replacer")
local M = {}

local DEFAULT_OPTS = {
  max_level = 4,
  ignore_pairs = {
    { "```", "```" },
    { "\\~\\~\\~", "\\~\\~\\~" },
    { "<!--", "-->" },
  },
}

local function merge_options(conf)
  return vim.tbl_deep_extend("force", DEFAULT_OPTS, conf or {})
end

local function judge_heading_by_line_number(start_line, end_line, cur_line)
  if start_line == -1 or end_line == -1 then
    return true
  end
  if start_line == nil or end_line == nil then
    return true
  end
  return start_line <= cur_line and cur_line <= end_line
end

function M.setup(conf)
  local opts = merge_options(conf)
  parser.setup(opts)
  replacer.setup(opts)
end

local function get_headings(...)
  local origin_heading_lines = parser.get_heading_lines(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  local heading_lines = {}
  if select("#", ...) == 3 then
    local start_line, end_line, offset = ...
    for index, heading in ipairs(origin_heading_lines) do
      if judge_heading_by_line_number(start_line, end_line, heading[1] + 1) then
        table.insert(heading_lines, replacer.change_heading_level(heading, offset))
      else
        table.insert(heading_lines, heading)
      end
    end
  else
    heading_lines = origin_heading_lines
  end
  return origin_heading_lines, heading_lines
end

function M._update_heading_number(is_clear, start_line, end_line, ...)
  local origin_heading_lines, heading_lines = get_headings(start_line, end_line, ...)
  heading_lines = replacer.insert_heading_number(heading_lines)
  if nil == heading_lines or #heading_lines == 0 then
    return
  end
  for index, heading in ipairs(heading_lines) do
    local line_index = heading[1]
    local heading_content = heading[2]
    local origin_heading_content = origin_heading_lines[index][2]
    local level = heading[3]
    local heading_number = heading[4]
    local updated_heading_content = replacer.replaceHeadingNumber(heading_content, heading_number, level, is_clear)
    if
      origin_heading_content ~= updated_heading_content
      and judge_heading_by_line_number(start_line, end_line, line_index + 1)
    then
      replacer.update_line(line_index, string.len(origin_heading_content), updated_heading_content)
    end
  end
end

function M.update_heading_number(firstline, lastline)
  M._update_heading_number(false, firstline, lastline)
end

function M.clear_heading_number(firstline, lastline)
  M._update_heading_number(true, firstline, lastline)
end

function M.header_decrease(firstline, lastline)
  M._update_heading_number(true, firstline, lastline, -1)
end

function M.header_increase(firstline, lastline)
  M._update_heading_number(true, firstline, lastline, 1)
end

return M
