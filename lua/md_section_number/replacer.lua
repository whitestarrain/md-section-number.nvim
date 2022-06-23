local parser = require("md_section_number.parser")

local M = {}

M.heading_number_pattern = "[%d%.]+"

function M.update_line(start_line, line_content)
  vim.api.nvim_buf_set_lines(0, start_line, start_line + 1, false, { line_content })
end

function M.replaceHeadingPrefix(str, pattern, prefix, level)
  local s, e = string.find(str, pattern)
  if nil == s or s ~= level + 2 then
    return prefix .. " " .. str
  end
  return string.sub(str, 0, s - 1) .. prefix .. string.sub(str, e, -1)
end

function M.get_heading_number(heading_lines)
  local level_depth = {}

  for i = 1, #heading_lines do
    local level = heading_lines[i][3]
    if i == 1 then
      level_depth[i] = 1
      goto continue
    end

    if not level_depth[level] or 0 == level_depth[level] then
      level_depth[level] = 1
    else
      if heading_lines[i][3] < heading_lines[i - 1][3] then
        level_depth[level] = level_depth[level] + 1
      end
      if heading_lines[i][3] == heading_lines[i - 1][3] then
        level_depth[level] = level_depth[level] + 1
      end
      if heading_lines[i][3] > heading_lines[i - 1][3] then
        for inner_level = heading_lines[i - 1][3] + 1, heading_lines[i][3] - 1 do
          level_depth[inner_level] = 0
        end
        level_depth[level] = 1
      end
    end

    ::continue::
    local heading_number = ""
    for j = 1, level do
      heading_number = heading_number .. (level_depth[j] or 0) .. "."
    end
    table.insert(heading_lines[i], heading_number)
  end
  return heading_lines
end

function M.update_heading_number()
  local heading_lines = parser.get_heading_lines(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  heading_lines = M.get_heading_number(heading_lines)
  if nil == heading_lines or #heading_lines == 0 then
    return
  end
  for _, heading in ipairs(heading_lines) do
    local line_number = heading[1]
    local heading_content = heading[2]
    local level = heading[3]
    local heading_number = heading[4]
    M.update_line(line_number, M.replaceHeadingPrefix(heading_content, M.heading_number_pattern, heading_number, level))
  end
end

return M
