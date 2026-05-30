return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false,
        term_colors = true,
        styles = { comments = { "italic" } },
        integrations = {
          telescope = true,
          lualine = true,
          gitsigns = true,
          treesitter = true,
          indent_blankline = { enabled = true },
          native_lsp = { enabled = true },
          cmp = true,
          which_key = true,
          noice = true,
          notify = true,
          neo_tree = true,
          bufferline = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
