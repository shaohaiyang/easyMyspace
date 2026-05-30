return {
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gc", mode = { "n", "v" }, desc = "Comment line" },
      { "gb", mode = { "n", "v" }, desc = "Comment block" },
    },
    opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "BufRead",
    opts = {
      indent = { char = "│" },
      scope = { enabled = false },
    },
  },
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufRead",
    config = function()
      require("colorizer").setup({ "*" }, {
        RGB = true,
        RRGGBB = true,
        names = false,
      })
    end,
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = {
      { "<leader>-", "<cmd>Oil<CR>", desc = "Oil file manager" },
    },
    opts = {
      view_options = { show_hidden = true },
    },
  },
}
