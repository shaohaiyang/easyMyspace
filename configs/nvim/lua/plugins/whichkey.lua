return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "modern",
        delay = 300,
        icons = { group = "" },
        spec = {
          { "<leader>", group = "Prefix" },
          { "<leader>f", group = "Find" },
          { "<leader>g", group = "Git" },
        },
      })
    end,
  },
}
