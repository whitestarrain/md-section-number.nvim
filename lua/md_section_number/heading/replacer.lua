local M = {}

M.heading_number_base_pattern = "%d+%."
M.max_level = nil
M.min_level = nil
M.start_section_number = nil
M.start_subsection_number = nil
M.remove_trailing_dot = nil

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
  -- Extract the hash part first
  local hash_part = string.rep("#", level)
  -- Extract title content, removing hashes and possible existing numbering
  local content_part = string.match(source_heading, "^#+%s*(.*)")
  if not content_part then
    content_part = ""
  end
  -- Remove leading numbering pattern (like "1.2.3. ")
  content_part = string.gsub(content_part, "^[%d%.]+%s+", "")
  content_part = vim.trim(content_part)
  -- Handle numbering format
  local number_part = ""
  if not is_clear and string.len(heading_number) > 0 then
    number_part = " " .. heading_number
  end
  -- Rebuild the heading
  return hash_part .. number_part .. " " .. content_part
end

function M.insert_heading_number(heading_lines)
  local level_depth = {}

  for i = 1, #heading_lines do
    local level = heading_lines[i][3]
    
    if i == 1 then
      -- First heading: initialize with start_section_number
      level_depth[level] = M.start_section_number
    else
      local prev_level = heading_lines[i - 1][3]
      
      if level == prev_level then
        -- Same level: increment counter
        level_depth[level] = level_depth[level] + 1
      elseif level < prev_level then
        -- Going to higher level (less #): increment existing counter and reset deeper levels
        if level_depth[level] then
          level_depth[level] = level_depth[level] + 1
        else
          -- If this level hasn't been seen before, start from appropriate value
          if level == M.min_level then
            level_depth[level] = M.start_section_number
          else
            level_depth[level] = M.start_subsection_number
          end
        end
        -- Reset all deeper levels to nil (will be initialized when needed)
        for reset_level = level + 1, prev_level do
          level_depth[reset_level] = nil
        end
      else
        -- Going to deeper level (more #): handle level jumps
        -- Initialize all skipped intermediate levels
        for skip_level = prev_level + 1, level - 1 do
          level_depth[skip_level] = M.start_subsection_number
        end
        -- Set current level to start_subsection_number
        level_depth[level] = M.start_subsection_number
      end
    end

    -- Generate heading number
    local heading_number = ""
    for j = M.min_level, level do
      local number
      if level_depth[j] then
        number = level_depth[j]
      else
        -- Initialize missing levels
        if j == M.min_level then
          number = M.start_section_number
          level_depth[j] = number
        else
          number = M.start_subsection_number
          level_depth[j] = number
        end
      end
      heading_number = heading_number .. number .. "."
    end
    
    if M.remove_trailing_dot and string.sub(heading_number, -1) == "." then
      heading_number = string.sub(heading_number, 1, -2)
    end
    table.insert(heading_lines[i], heading_number)
  end
  return heading_lines
end

function M.change_heading_level(heading_line, offset)
  local target_level
  if offset < 0 and math.abs(offset) >= heading_line[3] then
    target_level = 1
  else
    target_level = heading_line[3] + offset
  end

  -- Extract title content, removing hashes and possible existing numbering (using same logic as replaceHeadingNumber)
  local content_part = string.match(heading_line[2], "^#+%s*(.*)")
  if not content_part then
    content_part = ""
  end

  -- Remove leading numbering pattern (like "1.2.3. ")
  content_part = string.gsub(content_part, "^[%d%.]+%s+", "")
  content_part = vim.trim(content_part)

  local heading_content = string.rep("#", target_level) .. " " .. content_part

  return {
    heading_line[1],
    heading_content,
    target_level,
  }
end

function M.setup(opts)
  -- Set all configuration values from opts
  M.max_level = opts.max_level
  M.min_level = opts.min_level
  M.start_section_number = opts.start_section_number
  M.start_subsection_number = opts.start_subsection_number
  M.remove_trailing_dot = opts.remove_trailing_dot
  
  -- Validate and apply constraints
  if M.max_level < 0 then
    M.max_level = 4
  end
  if M.min_level < 1 then
    M.min_level = 1
  end
  if M.start_section_number < 0 then
    M.start_section_number = 0
  end
  if M.start_subsection_number < 0 then
    M.start_subsection_number = 0
  end
end

return M
