return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin-mocha",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = {
            { "filename", path = 1 },
          },
          lualine_x = {
            { "diagnostics", sources = { "nvim_diagnostic" } },
            { "filetype" },
            { "encoding" },
            { "fileformat" },
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },
}
