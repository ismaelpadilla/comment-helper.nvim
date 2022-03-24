Everything is subject to change, including repo name!

The end goal is to have language-agnostic support for adding useful comments to pieces of code. The main plugin (this repo) would expose useful functions for other plugins to provide language-specific comments.

The idea is to support adding basic text comments and [LuaSnip](https://github.com/L3MON4D3/LuaSnip) snippets.

<p align="center">
  <img alt="Preview" src="https://i.imgur.com/7k7ofRb.gif">
</p>

### Installation

Requires `nvim-treesitter`.

Using [vim-plug](https://github.com/junegunn/vim-plug)

```viml
Plug 'ismaelpadilla/comment-helper.nvim'
```

### Configuration

Default config: 
```lua
require('comment_helper').setup({
    -- Enable luasnip snippets.
    -- Set to true if you have LuaSnip installed.
    luasnip_enabled = false,

    -- If luasnip isn't supported and we receive a snippet as a comment,
    -- attempt to turn it into text and insert it.
    snippets_to_text = false,

    -- Function to call after a comment is placed.
    post_hook = nil
})
```

### Usage

Add keybinding for commenting:

```lua
vim.api.nvim_set_keymap('n', '<leader>cl', '<cmd> lua require("comment_helper").CommentLine()', {})
```
### See it in action

The following examples are using [comment-helper-rust.nvim](https://github.com/ismaelpadilla/comment-helper-rust.nvim) to document Rust functions:

With LuaSnip:
<p align="center">
  <img alt="Preview" src="https://i.imgur.com/7k7ofRb.gif">
</p>

Text comments:
<p align="center">
  <img alt="Preview" src="https://i.imgur.com/Skz8fDc.gif">
</p>
