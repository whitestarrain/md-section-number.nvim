local M = {}

M.heading_number_base_pattern = "%d+%."
M.max_level = 4
M.min_level = 1

local function get_heading_number_index(str)
  local pattern = M.heading_number_base_pattern
  local max_s, max_e
  repeat
    local s, e = string.find(str, pattern)
    pattern = pattern .. M.heading_number_base_pattern
    if s ~= nil then
      max_s = s
      max_e = e
    end
  until s == nil

  return max_s, max_e
end

function M.update_line(start_line, line_length, line_content)
  vim.api.nvim_buf_set_text(0, start_line, 0, start_line, line_length, { line_content })
end

function M.replaceHeadingNumber(source_heading, heading_number, level, is_clear)
  local max_level = M.max_level
  if is_clear then
    max_level = 0
  end
  if level > max_level or level < M.min_level then
    heading_number = ""
  end
  if string.len(heading_number) > 0 then
    heading_number = " " .. heading_number
  end
  local s, e = get_heading_number_index(source_heading)
  if nil == s or s ~= level + 2 then
    return string.rep("#", level) .. heading_number .. " " .. vim.trim(string.sub(source_heading, level + 1, -1))
  end
  return string.rep("#", level) .. heading_number .. " " .. vim.trim(string.sub(source_heading, e + 1, -1))
end

-- @table heading_lines {{heading_line_index,heading_line_content,heading_level},{}}
function M.insert_heading_number(heading_lines)
  local level_depth = {}

  for i = 1, #heading_lines do
    local level = heading_lines[i][3]
    if i == 1 then
      level_depth[level] = 1
      goto continue
    end

    if not level_depth[level] then
      level_depth[level] = 0
    end
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

    ::continue::
    local heading_number = ""
    for j = M.min_level, level do
      heading_number = heading_number .. (level_depth[j] or 0) .. "."
    end
    table.insert(heading_lines[i], heading_number)
  end
  return heading_lines
end

-- @table heading_lines {heading_line_index,heading_line_content,heading_level}
function M.change_heading_level(heading_line, offset)
  local target_level
  if offset < 0 and math.abs(offset) >= heading_line[3] then
    target_level = 1
  else
    target_level = heading_line[3] + offset
  end
  local _, e = get_heading_number_index(heading_line[1])
  local heading_content
  if e == nil then
    heading_content = string.rep("#", target_level)
      .. " "
      .. vim.trim(string.sub(heading_line[2], heading_line[3] + 1, -1))
  else
    heading_content = string.rep("#", target_level) .. vim.trim(string.sub(heading_line[2], e + 1, -1))
  end
  return {
    heading_line[1],
    heading_content,
    target_level,
  }
end

function M.setup(opts)
  M.max_level = opts.max_level or M.max_level
  if M.max_level < 0 then
    M.max_level = 4
  end
  M.min_level = opts.min_level or M.min_level
  if M.min_level < 1 then
    M.min_level = 1
  end
end

return M
