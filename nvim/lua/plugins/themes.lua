return {
  {
    "miikanissi/modus-themes.nvim",
    lazy = false,
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

  -- Catppuccin (soothing pastel; `catppuccin-latte` is the light variant)
  -- Activate light with: `:colorscheme catppuccin-latte`
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "auto",         -- auto: latte on light bg, mocha on dark bg
        background = {
          light = "latte",
          dark = "mocha",
        },
        transparent_background = false,
        styles = {
          comments = { "italic" },
          keywords = { "italic" },
          functions = {},
          variables = {},
        },
        integrations = {
          treesitter = true,
          native_lsp = { enabled = true },
          telescope = { enabled = true },
          nvimtree = true,
          gitsigns = true,
        },
      })
    end,
  },

  -- Rose Pine (elegant, muted; `rose-pine-dawn` is the light variant)
  -- Activate light with: `:colorscheme rose-pine-dawn`
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        variant = "auto",       -- auto picks dawn/main by vim.o.background
        dark_variant = "main",
        styles = {
          italic = true,
          transparency = false,
        },
      })
    end,
  },
}
