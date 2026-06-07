return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        enable_git_status = true,
        enable_diagnostics = true,
        sort_case_insensitive = true,
        sort_function = function(a, b)
          if a.type == "directory" and b.type ~= "directory" then return true end
          if a.type ~= "directory" and b.type == "directory" then return false end
          local aname = a.name or ""
          local bname = b.name or ""
          return aname < bname
        end,
        filesystem = {
          follow_current_file = { enabled = true },
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = { ".DS_Store" },
          },
        },
        window = {
          position = "left",
          width = 30,
        },
      })
      vim.keymap.set("n", "<leader>n", "<cmd>Neotree toggle<CR>", { desc = "Toggle file tree" })
    end,
  },
}
