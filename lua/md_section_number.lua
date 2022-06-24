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

function M.setup(conf)
  local opts = merge_options(conf)
  parser.setup(opts)
  replacer.setup(opts)
end

function M.update_heading_number(is_clear)
  local heading_lines = parser.get_heading_lines(vim.api.nvim_buf_get_lines(0, 0, -1, false))
  heading_lines = replacer.get_heading_number(heading_lines)
  if nil == heading_lines or #heading_lines == 0 then
    return
  end
  for _, heading in ipairs(heading_lines) do
    local line_number = heading[1]
    local heading_content = heading[2]
    local level = heading[3]
    local heading_number = heading[4]
    replacer.update_line(
      line_number - 1,
      string.len(heading_content),
      replacer.replaceHeadingNumber(heading_content, heading_number, level, is_clear)
    )
  end
end

function M.clear_heading_number()
  M.update_heading_number(true)
end

return M
