# Example

![](./image/show.gif)

# About

A plugin to update heading number and change heading level for markdown

# Requires

- `neovim`>=0.7

# Install

- vim-plug

  ```
  Plug 'whitestarrain/md-section-number.nvim'
  ```

# SetUpp

```lua
require("md_section_number").setup({
--[[
  max_level = 4,
  ignore_pairs = {
    { "```", "```" },
    { "\\~\\~\\~", "\\~\\~\\~" },
    { "<!--", "-->" },
  },
]]
})
```

# Use

- `:MDClearNumber`
- `:MDUpdateNumber`
- `:HeaderDecrease `
- `:HeaderIncrease `

# developing

> developing functions, but can try using

- `:MdTocToggle`: open a markdown toc
  - why:
    - when i use tagbar with this [config_file](https://github.com/whitestarrain/dotfiles/blob/master/nvim/others/.ctags.d/markdown.ctags), ctags recognizes `#include` as a title
  - mappings:
    - r: update
    - q: quit
    - enter: jump
  - todo
    - after write，reparse heading, and rerender
    - when move curosr，auto select the heading that in side window.
    - when switch to other buffer，reload side window.
