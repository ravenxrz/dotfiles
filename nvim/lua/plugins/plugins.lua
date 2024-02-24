return {
  {
    "miikanissi/modus-themes.nvim",
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme modus_operandi]])
    end
  },
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  {
    "nvim-tree/nvim-tree.lua",
    lazy = false,
    config = function()
      require("nvim-tree").setup({
        sort = {
          sorter = "case_sensitive",
        },
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = true,
        },
      })
    end
  },
}
