local Stack = require("md_section_number.common.stack")
local M = {}

M.ignore_pairs = {
  { "```", "```" },
  { "\\~\\~\\~", "\\~\\~\\~" },
  { "<!--", "-->" },
}

M.heading_pattern = "^#+ "

function M.add_pairs(startPair, endPair)
  table.insert(M.ignore_pairs, { startPair, endPair })
end

local function judgeHeadingLine(line)
  local s, e = string.find(line, M.heading_pattern)
  local length = s and e - s or 0
  return nil ~= s, length
end

function M.get_heading_lines(all_lines)
  if nil == all_lines or #all_lines == 0 then
    return {}
  end
  local heading_lines = {}
  local stack = Stack:new({})
  -- find ignore section by ignore_pairs
  for line_number, line in ipairs(all_lines) do
    for pair_index, pair in ipairs(M.ignore_pairs) do
      local start_pair_location = vim.fn.match(line, pair[1])
      local end_pair_location = vim.fn.match(line, pair[2], start_pair_location + 1)
      if pair[1] == pair[2] then
        if stack:is_empty() then
          if -1 ~= start_pair_location and -1 == end_pair_location then
            stack:push(pair_index)
          end
        else
          if -1 ~= start_pair_location and -1 == end_pair_location then
            if pair_index == stack:peek() then
              stack:pop()
            else
              stack:push(pair_index)
            end
          end
        end
      end
      if pair[1] ~= pair[2] then
        if -1 ~= start_pair_location and -1 == end_pair_location then
          stack:push(pair_index)
        end
        if -1 == start_pair_location and -1 ~= end_pair_location then
          if pair_index == stack:peek() then
            stack:pop()
          end
        end
      end
    end
    if stack:is_empty() then
      local is_heading, level = judgeHeadingLine(line)
      if is_heading then
        table.insert(heading_lines, { line_number - 1, line, level })
      end
    end
  end
  return heading_lines
end

function M.setup(opt)
  M.ignore_pairs = opt.ignore_pairs or M.ignore_pairs
end

return M
