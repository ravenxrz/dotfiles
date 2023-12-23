return {
  "DNLHC/glance.nvim",
  cmd = "Glance",
  config = function()
    require("glance").setup {
      height = 30, -- Height of the window
    }
  end,
}
