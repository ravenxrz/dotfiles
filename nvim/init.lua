-- local function disable_markdown_treesitter_start()
--   if vim.g.markdown_treesitter_start_guarded then
--     return
--   end
--   vim.g.markdown_treesitter_start_guarded = true
--
--   local original_start = vim.treesitter.start
--   vim.treesitter.start = function(bufnr, lang)
--     bufnr = bufnr or vim.api.nvim_get_current_buf()
--     local ft = vim.bo[bufnr].filetype
--     local resolved_lang = lang or vim.treesitter.language.get_lang(ft)
--     if ft == "markdown" or ft == "markdown.mdx" or resolved_lang == "markdown" or resolved_lang == "markdown_inline" then
--       return
--     end
--     return original_start(bufnr, lang)
--   end
-- end
--
-- disable_markdown_treesitter_start()

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("utils")
require("parser")
require("options")
require("commands")
require("keymaps")
require("autocmds")
require("remote_dev_sync").setup({})
require("lazy").setup("plugins", {
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- color scheme
vim.cmd([[
  set background=light
]])
vim.cmd.colorscheme("modus_operandi")
vim.cmd.colorscheme("modus_operandi") -- I don't know why I have to call this twice to let bufferline works as expect
-- vim.cmd.colorscheme("catppuccin-latte")
-- vim.cmd.colorscheme("rose-pine-dawn")
-- vim.cmd.colorscheme("tokyonight-day")
-- vim.cmd.colorscheme("gruvbox-baby")
-- vim.cmd.colorscheme "eldritch"
