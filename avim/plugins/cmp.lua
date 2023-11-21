return {
  "hrsh7th/nvim-cmp",
  -- override the options table that is used in the `require("cmp").setup()` call
  opts = function(_, opts)
    opts.formatting = {
      fields = { "kind", "abbr", "menu" },
      format = function(entry, vim_item)
        vim_item.abbr = string.sub(vim_item.abbr, 1, 20)
        return vim_item
      end,
    }
    -- return the new table to be used
    return opts
  end,
}
