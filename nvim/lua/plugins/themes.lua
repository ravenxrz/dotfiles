return {
  {
    "EdenEast/nightfox.nvim",
    lazy = false,
    priority = 1000,
  },
  {
    "yorickpeterse/nvim-grey"
  },
  -- {
  --   "sainnhe/sonokai",
  --   priority = 999,
  -- },
  -- {
  --   "eldritch-theme/eldritch.nvim",
  --   lazy = false,
  --   priority = 999,
  --   opts = {},
  -- },
  {
    "miikanissi/modus-themes.nvim",
    priority = 1000,
    config = function()
      require("modus-themes").setup({
        -- Theme comes in two styles `modus_operandi` and `modus_vivendi`
        -- `auto` will automatically set style based on background set with vim.o.background
        style = "modus_operandi",
        variant = "tinted",   -- Theme comes in four variants `default`, `tinted`, `deuteranopia`, and `tritanopia`
        transparent = false,  -- Transparent background (as supported by the terminal)
        dim_inactive = false, -- "non-current" windows are dimmed
        styles = {
          -- Style to be applied to different syntax groups
          -- Value is any valid attr-list value for `:help nvim_set_hl`
          comments = { italic = true },
          keywords = { italic = true },
          functions = {},
          variables = {},
        },
      })
    end,
  },
  {
    "loctvl842/monokai-pro.nvim",
    priority = 1000,
    opts = {
      transparent_background = false,
      terminal_colors = true,
      devicons = true, -- highlight the icons of `nvim-web-devicons`
      styles = {
        comment = { italic = true },
        keyword = { italic = true },       -- any other keyword
        type = { italic = true },          -- (preferred) int, long, char, etc
        storageclass = { italic = true },  -- static, register, volatile, etc
        structure = { italic = true },     -- struct, union, enum, etc
        parameter = { italic = true },     -- parameter pass in function
        annotation = { italic = true },
        tag_attribute = { italic = true }, -- attribute of tag in reactjs
      },
      filter = "pro",                      -- classic | octagon | pro | machine | ristretto | spectrum
      -- Enable this will disable filter option
      day_night = {
        enable = false,            -- turn off by default
        day_filter = "pro",        -- classic | octagon | pro | machine | ristretto | spectrum
        night_filter = "spectrum", -- classic | octagon | pro | machine | ristretto | spectrum
      },
      inc_search = "background",   -- underline | background
      background_clear = {
        -- "float_win",
        "toggleterm",
        "telescope",
        -- "which-key",
        "renamer",
        "notify",
        -- "nvim-tree",
        -- "neo-tree",
        -- "bufferline", -- better used if background of `neo-tree` or `nvim-tree` is cleared
      }, -- "float_win", "toggleterm", "telescope", "which-key", "renamer", "neo-tree", "nvim-tree", "bufferline"
      plugins = {
        bufferline = {
          underline_selected = false,
          underline_visible = false,
        },
        indent_blankline = {
          context_highlight = "default", -- default | pro
          context_start_underline = false,
        },
      },
    }
  }
}
