local M = {}

M.heading_number_base_pattern = "%d+%."
M.max_level = 4

local function get_pattern(level)
  local pattern = ""
  if not level then
    return pattern
  end
  for _ = 1, level do
    pattern = pattern .. M.heading_number_base_pattern
  end
  return pattern
end

function M.update_line(start_line, line_length, line_content)
  vim.api.nvim_buf_set_text(0, start_line, 0, start_line, line_length, { line_content })
end

function M.replaceHeadingNumber(str, heading_number, level, is_clear)
  local max_level = M.max_level
  if is_clear then
    max_level = 0
  end
  if level > max_level then
    heading_number = ""
  end
  if string.len(heading_number) > 0 then
    heading_number = " " .. heading_number
  end
  local pattern = get_pattern(level)
  local s, e = string.find(str, pattern)
  if nil == s or s ~= level + 2 then
    return string.rep("#", level) .. heading_number .. " " .. vim.trim(string.sub(str, level + 1, -1))
  end
  return string.rep("#", level) .. heading_number .. " " .. vim.trim(string.sub(str, e + 1, -1))
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

function M.setup(opts)
  M.max_level = opts.max_level or M.max_level
end

return M
