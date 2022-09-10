" Only do this when not done yet for this buffer
if exists("b:md_section_number")
  finish
endif

" https://stackoverflow.com/questions/10572996/passing-command-range-to-a-function
function MdUpdateHeadingNumber() range
  call v:lua.require('md_section_number').update_heading_number(a:firstline, a:lastline)
endfunction
function MdClearHeadingNumber() range
  call v:lua.require('md_section_number').clear_heading_number(a:firstline, a:lastline)
endfunction

command! -buffer -range=% MDUpdateNumber <line1>,<line2>call MdUpdateHeadingNumber()
command! -buffer -range=% MDClearNumber <line1>,<line2>call MdClearHeadingNumber()

let b:md_section_number = 1
