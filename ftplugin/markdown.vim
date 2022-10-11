" Only do this when not done yet for this buffer
if exists("b:md_section_number")
  finish
endif

" https://stackoverflow.com/questions/10572996/passing-command-range-to-a-function
" https://vi.stackexchange.com/questions/13161/specify-a-range-for-command-but-not-move-cursor
function MdUpdateHeadingNumber(line1, line2) range
  call v:lua.require('md_section_number').update_heading_number(a:line1, a:line2)
endfunction
function MdClearHeadingNumber(line1, line2) range
  call v:lua.require('md_section_number').clear_heading_number(a:line1, a:line2)
endfunction

function MdHeaderDecrease(line1, line2) range
  call v:lua.require('md_section_number').header_decrease(a:line1, a:line2)
endfunction
function MdHeaderIncrease(line1, line2) range
  call v:lua.require('md_section_number').header_increase(a:line1, a:line2)
endfunction

command! -buffer -range=% MDUpdateNumber call MdUpdateHeadingNumber(<line1>,<line2>)
command! -buffer -range=% MDClearNumber call MdClearHeadingNumber(<line1>,<line2>)
command! -buffer -range=% HeaderDecrease call MdHeaderDecrease(<line1>,<line2>)
command! -buffer -range=% HeaderIncrease call MdHeaderIncrease(<line1>,<line2>)

let b:md_section_number = 1
