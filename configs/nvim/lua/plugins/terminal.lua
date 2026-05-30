return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<leader>/]],
        direction = "horizontal",
        shade_terminals = true,
        start_in_insert = true,
        persist_size = true,
      })
    end,
    keys = {
      { "<leader>/", "<cmd>ToggleTerm<CR>", desc = "Toggle terminal" },
    },
  },
}
