# About

A plugin to add heading number in neovim

# Requires

- `neovim`>=0.7

# Install

- vim-plug

  ```
  Plug 'whitestarrain/md-section-number.nvim'
  ```

# SetUp

```lua
require("md_section_number").setup({
  max_level = 4,
  ignore_pairs = {
    { "```", "```" },
    { "\\~\\~\\~", "\\~\\~\\~" },
    { "<!--", "-->" },
  },
})
```

# Show


