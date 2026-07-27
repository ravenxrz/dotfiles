vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      padding = true,
      sticky = true,
      toggler = {
        line = "gcc",
        block = "gbc",
      },
      opleader = {
        line = "gc",
        block = "gb",
      },
      extra = {
        above = "gcO",
        below = "gco",
        eol = "gcA",
      },
      mappings = {
        basic = true,
        extra = true,
      },
    },
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },
  {
    "ggandor/leap.nvim",
    url = "https://codeberg.org/ggandor/leap.nvim",
    config = function()
      require("leap").init_highlight(true)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    version = "*",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "c", "cpp", "json", "lua", "python", "yaml" },
      highlight = { enable = false },
      indent = { enable = false },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      require("nvim-treesitter-textobjects").setup({
        select = {
          lookahead = true,
          selection_modes = {
            ["@parameter.outer"] = "v",
            ["@function.outer"] = "V",
            ["@class.outer"] = "<c-v>",
          },
          include_surrounding_whitespace = false,
        },
        move = {
          set_jumps = true,
        },
      })

      local ts_select = require("nvim-treesitter-textobjects.select")
      local ts_move = require("nvim-treesitter-textobjects.move")
      vim.keymap.set({ "x", "o" }, "af", function()
        ts_select.select_textobject("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "if", function()
        ts_select.select_textobject("@function.inner", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ac", function()
        ts_select.select_textobject("@class.outer", "textobjects")
      end)
      vim.keymap.set({ "x", "o" }, "ic", function()
        ts_select.select_textobject("@class.inner", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "]m", function()
        ts_move.goto_next_start("@function.outer", "textobjects")
      end)
      vim.keymap.set({ "n", "x", "o" }, "[m", function()
        ts_move.goto_previous_start("@function.outer", "textobjects")
      end)
    end,
  },
})

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

keymap("n", "j", "gj", opts)
keymap("n", "k", "gk", opts)
keymap("n", "H", "^", opts)
keymap("n", "L", "$", opts)
keymap("v", "H", "^", opts)
keymap("v", "L", "$", opts)
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)
keymap("v", "p", '"_dP', opts)
keymap("n", "Q", "q", opts)
keymap("n", "q", "<Nop>", opts)
keymap("n", "<leader>h", "<cmd>nohlsearch<cr>", opts)

keymap("n", "t", "<Plug>(leap-forward)", opts)
keymap("n", "T", "<Plug>(leap-backward)", opts)
keymap("n", "gs", "<Plug>(leap-from-window)", opts)

local vscode = require("vscode")
keymap("n", "<leader>w", function()
  vscode.action("workbench.action.files.saveAll")
end, opts)
keymap("n", "<leader>q", function()
  vscode.action("workbench.action.closeActiveEditor")
end, opts)
keymap("n", "<leader>e", function()
  vscode.action("workbench.view.explorer")
end, opts)
keymap("n", "<leader>o", function()
  vscode.action("workbench.files.action.showActiveFileInExplorer")
end, opts)
keymap("n", "E", function()
  vscode.action("workbench.action.previousEditor")
end, opts)
keymap("n", "R", function()
  vscode.action("workbench.action.nextEditor")
end, opts)
keymap("n", "<leader>ff", function()
  vscode.action("workbench.action.quickOpen")
end, opts)
keymap("n", "<leader>fg", function()
  vscode.action("workbench.action.findInFiles")
end, opts)
keymap("n", "<leader>fb", function()
  vscode.action("workbench.action.showAllEditors")
end, opts)
keymap("n", "gd", function()
  vscode.action("editor.action.revealDefinition")
end, opts)
keymap("n", "gr", function()
  vscode.action("editor.action.goToReferences")
end, opts)
keymap("n", "K", function()
  vscode.action("editor.action.showHover")
end, opts)
keymap("n", "<leader>lr", function()
  vscode.action("editor.action.rename")
end, opts)
keymap({ "n", "v" }, "<leader>la", function()
  vscode.action("editor.action.quickFix")
end, opts)
keymap({ "n", "v" }, "<leader>lf", function()
  vscode.action("editor.action.formatDocument")
end, opts)

local function set_clipboard(text, message)
  vim.fn.setreg("+", text)
  vim.notify(message .. ": " .. text)
end

vim.api.nvim_create_user_command("CopyFileName", function()
  set_clipboard(vim.fn.expand("%:t"), "copy filename")
end, {})

vim.api.nvim_create_user_command("CopyFileNameWoExt", function()
  set_clipboard(vim.fn.fnamemodify(vim.fn.expand("%:t"), ":r"), "copy filename wo ext")
end, {})

vim.api.nvim_create_user_command("CopyFilePath", function()
  set_clipboard(vim.fn.expand("%:p"), "copy file path")
end, {})

vim.api.nvim_create_user_command("CopyFilePathWoExt", function()
  set_clipboard(vim.fn.fnamemodify(vim.fn.expand("%:p"), ":r"), "copy file path wo ext")
end, {})

vim.api.nvim_create_user_command("CopyBreakPoint", function()
  set_clipboard(vim.fn.expand("%:t") .. ":" .. vim.fn.line("."), "copy breakpoint")
end, {})

keymap("n", "yb", "<cmd>CopyBreakPoint<cr>", opts)
keymap("n", "yf", "<cmd>CopyFileName<cr>", opts)
keymap("n", "yF", "<cmd>CopyFilePath<cr>", opts)
keymap("n", "yo", "<cmd>CopyFileNameWoExt<cr>", opts)
keymap("n", "yO", "<cmd>CopyFilePathWoExt<cr>", opts)

vim.api.nvim_create_autocmd("BufRead", {
  pattern = { "*" },
  callback = function()
    local filename = vim.fn.expand("<afile>")
    local patterns = { "link.txt", "%.log$", "DEBUG", "INFO", "WARN", "ERROR" }
    for _, pattern in ipairs(patterns) do
      if string.match(filename, pattern) then
        vim.opt_local.wrap = true
        return
      end
    end
  end,
})
