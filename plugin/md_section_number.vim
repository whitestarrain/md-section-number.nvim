" load plugin

if exists('g:md_section_number') | finish | endif

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

if !has('nvim')
    echohl Error
    echom "Sorry this plugin only works with versions of neovim that support lua"
    echohl clear
    finish
endif

command! mdSectionNumber lua require('md_section_number').update_heading_number()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:md_section_number = 1
