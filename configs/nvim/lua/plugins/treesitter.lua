return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua",
        "rust",
        "python",
        "go",
        "javascript",
        "typescript",
        "json",
        "yaml",
        "toml",
        "markdown",
        "bash",
        "vim",
        "vimdoc",
        "gitcommit",
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
    },
  },
}
