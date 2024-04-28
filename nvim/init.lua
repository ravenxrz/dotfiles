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

-- 关闭 codeverse 内置自动补全
vim.g.codeverse_disable_autocompletion = true
-- 关闭 codeverse 内置 tab 映射
vim.g.codeverse_no_map_tab = true
-- 关闭 codeverse 内置补全映射
vim.g.codeverse_disable_bindings = true

require("parser")
require("options")
require("keymaps")
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
  }
)
