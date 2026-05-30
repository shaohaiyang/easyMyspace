return {
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G" },
    keys = {
      { "<leader>g", "<cmd>Git<CR>", desc = "Git" },
      { "<leader>gb", "<cmd>Git blame<CR>", desc = "Git blame" },
      { "<leader>gd", "<cmd>Git diff<CR>", desc = "Git diff" },
      { "<leader>gl", "<cmd>Git log<CR>", desc = "Git log" },
    },
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "┃" },
        change = { text = "┃" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      current_line_blame = true,
      current_line_blame_opts = { delay = 500 },
    },
    keys = {
      { "]h", ":Gitsigns next_hunk<CR>", desc = "Next hunk" },
      { "[h", ":Gitsigns prev_hunk<CR>", desc = "Prev hunk" },
    },
  },
  {
    "kdheepak/lazygit.nvim",
    cmd = "LazyGit",
    keys = {
      { "<leader>g", "<cmd>LazyGit<CR>", desc = "LazyGit" },
    },
  },
}
