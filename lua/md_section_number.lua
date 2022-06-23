local parser = require("md_section_number.parser")
local replacer = require("md_section_number.replacer")

local function update_heading_number()
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
      line_number,
      replacer.replaceHeadingPrefix(heading_content, replacer.heading_number_pattern, heading_number, level)
    )
  end
end

return {
  update_heading_number = update_heading_number,
}
