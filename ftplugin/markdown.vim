" load plugin

command! -buffer MDUpdateNumber lua require('md_section_number').update_heading_number()
command! -buffer MDClearNumber lua require('md_section_number').clear_heading_number()
