return {
  {
    'saadparwaiz1/cmp_luasnip' -- Snippets source for nvim-cmp
  },
  {
    'L3MON4D3/LuaSnip' -- Snippets plugin
  },
  {
    'hrsh7th/cmp-nvim-lsp' -- LSP source for nvim-cmp
  },
  {
    'hrsh7th/nvim-cmp', -- Autocompletion plugin
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'neovim/nvim-lspconfig',
      "hrsh7th/cmp-nvim-lsp-signature-help",
    },
    config = function()
      local lspconfig = require('lspconfig')
      local luasnip = require 'luasnip'
      local cmp = require 'cmp'
      local select_next = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' })
      local select_prev = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' })

      cmp.setup {
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = ""
            -- vim_item.kind = ""
            vim_item.abbr = string.sub(vim_item.abbr, 1, 30)
            return vim_item
          end
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-u>'] = cmp.mapping.scroll_docs(-4), -- Up
          ['<C-d>'] = cmp.mapping.scroll_docs(4),  -- Down
          -- C-b (back) C-f (forward) for snippet placeholder navigation.
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm {
            select = true,
            behavior = cmp.ConfirmBehavior.Replace,
          },
          ['<C-n>'] = select_next,
          ['<C-p>'] = select_prev,
          ['<Tab>'] = select_next,
          ['<S-Tab>'] = select_prev
        }),
        sources = {
          { name = 'nvim_lsp' },
          { name = 'nvim_lsp_signature_help' },
          { name = 'luasnip' },
        },
      }
    end
  },
}
