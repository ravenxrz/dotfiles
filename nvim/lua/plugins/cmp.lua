return {
  {
    "xzbdmw/colorful-menu.nvim",
    config = function()
      require("colorful-menu").setup({})
    end,
  },
  {
    "saghen/blink.cmp",
    -- optional: provides snippets for the snippet source
    dependencies = {

      {
        'L3MON4D3/LuaSnip',
        version = 'v2.*',
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          local ls = require("luasnip")
          require("luasnip.loaders.from_vscode").lazy_load()
          ls.config.set_config({
            history = true,
            updateevents = "TextChanged,TextChangedI",
            enable_autosnippets = true,
          })
        end,
      },
    },

    -- use a release tag to download pre-built binaries
    version = "*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      -- 'default' for mappings similar to built-in completion
      -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
      -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
      -- See the full "keymap" documentation for information on defining your own keymap.
      snippets = { preset = 'luasnip' },
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "fallback" },
        ["<S-Tab>"] = { "fallback" },
      },
      completion = {
        trigger = {
          show_on_blocked_trigger_characters = { ' ', '\n', '\t' },
        },
        menu = {
          auto_show = function()
            local disabled_filetypes = { "TelescopePrompt", "NvimTree", "DressingInput" }
            return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype) and vim.b.completion ~= false
          end,
          draw = {
            -- We don't need label_description now because label and label_description are already
            -- combined together in label by colorful-menu.nvim.
            columns = { { "kind_icon" }, { "label", gap = 1 } },
            components = {
              label = {
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
            },
          },
        },
        accept = { auto_brackets = { enabled = true } },
        -- Show documentation when selecting a completion item
        documentation = { auto_show = true, auto_show_delay_ms = 500 },
        -- Display a preview of the selected item on the current line
        ghost_text = { enabled = false },
      },
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- Will be removed in a future release
        use_nvim_cmp_as_default = false,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = "mono",
      },
      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { "lsp", "lazydev", "path", "snippets", "buffer" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
        },
      },
      -- Disable cmdline completions
      cmdline = {},
      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
  },
  {
    "git@code.byted.org:chenjiaqi.cposture/codeverse.vim.git",
    cond = get_os_platform() == "Linux",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    config = function()
      require("marscode").setup({})
    end,
  },
  -- {
  --  "rcarriga/cmp-dap",
  --  event = "InsertEnter",
  --  config = function()
  --   require("cmp").setup.filetype({ "dap-repl", "dapui_watches", "dapui_hover" }, {
  --    sources = {
  --     { name = "dap" },
  --    },
  --   })
  --  end,
  -- },
}
