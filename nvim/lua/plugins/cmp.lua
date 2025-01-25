return {
  -- {
  --   "saadparwaiz1/cmp_luasnip", -- Snippets source for nvim-cmp
  --   event = "InsertEnter",
  -- },
  -- {
  --   "L3MON4D3/LuaSnip", -- Snippets plugin
  --   dependencies = { "rafamadriz/friendly-snippets" },
  --   event = "InsertEnter",
  --   config = function()
  --     require("luasnip.loaders.from_vscode").lazy_load() -- load freindly-snippets
  --   end,
  -- },
  -- {
  --   "hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
  --   event = "InsertEnter",
  -- },
  --
  -- {
  --   "danymat/neogen",
  --   cmd = { "Neogen" },
  --   config = function()
  --     require("neogen").setup({ snippet_engine = "luasnip" })
  --   end,
  --   version = "*",
  -- },
  -- {
  --   "hrsh7th/nvim-cmp", -- Autocompletion plugin
  --   event = "InsertEnter",
  --   dependencies = {
  --     "hrsh7th/cmp-nvim-lsp",
  --     "neovim/nvim-lspconfig",
  --     "hrsh7th/cmp-nvim-lsp-signature-help",
  --     "hrsh7th/cmp-path",
  --     "hrsh7th/cmp-buffer",
  --     -- "onsails/lspkind.nvim",
  --   },
  --   config = function()
  --     local luasnip = require("luasnip")
  --     local cmp = require("cmp")
  --     -- local lspkind = require("lspkind")
  --
  --     local select_next = cmp.mapping(function(fallback)
  --       if cmp.visible() then
  --         cmp.select_next_item()
  --       else
  --         fallback()
  --       end
  --     end, { "i", "s" })
  --     local select_prev = cmp.mapping(function(fallback)
  --       if cmp.visible() then
  --         cmp.select_prev_item()
  --       else
  --         fallback()
  --       end
  --     end, { "i", "s" })
  --
  --     cmp.setup({
  --       formatting = {
  --         format = function(entry, vim_item)
  --           vim_item.menu = ""
  --           -- vim_item.kind = ""
  --           vim_item.abbr = string.sub(vim_item.abbr, 1, 30)
  --           return vim_item
  --         end,
  --
  --       },
  --       snippet = {
  --         expand = function(args)
  --           luasnip.lsp_expand(args.body)
  --         end,
  --       },
  --       mapping = cmp.mapping.preset.insert({
  --         ["<C-u>"] = cmp.mapping.scroll_docs(-4), -- Up
  --         ["<C-d>"] = cmp.mapping.scroll_docs(4),  -- Down
  --         -- C-b (back) C-f (forward) for snippet placeholder navigation.
  --         ["<C-Space>"] = cmp.mapping.complete(),
  --         ["<CR>"] = cmp.mapping.confirm({
  --           select = true,
  --           behavior = cmp.ConfirmBehavior.Insert,
  --         }),
  --         ["<C-n>"] = select_next,
  --         ["<C-p>"] = select_prev,
  --         ["<Tab>"] = select_next,
  --         ["<S-Tab>"] = select_prev,
  --       }),
  --       sources = {
  --         { name = "nvim_lsp" },
  --         { name = "nvim_lsp_signature_help" },
  --         { name = "luasnip" },
  --         { name = "buffer" },
  --         { name = "path" },
  --         { name = "lazydev",                group_index = 0 },
  --       },
  --     })
  --   end,
  -- },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
        auto_trigger = true,
      })
    end,
  },
  {
    'saghen/blink.cmp',
    -- optional: provides snippets for the snippet source
    dependencies = {
      "giuxtaposition/blink-cmp-copilot",
      'rafamadriz/friendly-snippets',
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },

    },

    -- use a release tag to download pre-built binaries
    version = '*',
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
      keymap = { preset = 'enter' },
      completion = {
        accept = { auto_brackets = { enabled = true }, },
        -- Show documentation when selecting a completion item
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        -- Display a preview of the selected item on the current line
        ghost_text = { enabled = false },
      },
      appearance = {
        -- Sets the fallback highlight groups to nvim-cmp's highlight groups
        -- Useful for when your theme doesn't support blink.cmp
        -- Will be removed in a future release
        use_nvim_cmp_as_default = true,
        -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
        -- Adjusts spacing to ensure icons are aligned
        nerd_font_variant = 'mono'
      },
      -- Default list of enabled providers defined so that you can extend it
      -- elsewhere in your config, without redefining it, due to `opts_extend`
      sources = {
        default = { 'lsp', "lazydev", 'path', 'snippets', 'buffer', "copilot" },
        providers = {
          lazydev = {
            name = "LazyDev",
            module = "lazydev.integrations.blink",
            -- make lazydev completions top priority (see `:h blink.cmp`)
            score_offset = 100,
          },
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 99,
            async = true,
          },
        },
        -- Disable cmdline completions
        cmdline = {},
      },
      signature = { enabled = true }
    },
    opts_extend = { "sources.default" }
  }

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
