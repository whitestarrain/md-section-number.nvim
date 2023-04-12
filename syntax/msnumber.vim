if exists("b:current_msnumber_syntax")
  finish
endif

syntax match MSNMaxLevelHeader "^- .*"

highlight MSNMaxLevelHeader ctermfg=blue guifg=#268bd2

let b:current_msnumber_syntax = 'msnumber'

