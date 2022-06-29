" Only do this when not done yet for this buffer
if exists("b:md_section_number")
  finish
endif

command! -buffer MDUpdateNumber lua require('md_section_number').update_heading_number()
command! -buffer MDClearNumber lua require('md_section_number').clear_heading_number()

let b:md_section_number = 1
