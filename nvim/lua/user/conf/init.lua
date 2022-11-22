

local M = {}

-- local starts_with = require("user.utils").starts_with
local ends_with = require("user.utils").ends_with

M.setup = function()
  local config_dir = vim.fn.stdpath('config') .. '/lua/user/conf'
  -- plugins do not need to load, NOTE: no .lua suffix required
  local unload_plugins = {
    "init", -- we don't need to load init again
    "vgit",
    "nvim-hlslens",
    "auto-session",
    "vim-illuminate",
    "vista",
    -- "aerial",
    "nvim-gps",
    "tabout",
    "hlargs",
    "spellsitter",
    "tabnine",
    "startup",
    "nvim-neoclip",
    "nvim-biscuits",
    "nvim_context_vt",
    "filetype",
    "distant",
    "winshift",
    "toggleterm",
    "nvim-spectre",
    "vim-ultest",
    "tmux",
    "symbols-outline",
    "gitsigns.lua"
  }

  local helper_set = {}
  for _, v in pairs(unload_plugins) do
    helper_set[v] = true
  end
  for _, fname in pairs(vim.fn.readdir(config_dir)) do
    if ends_with(fname, ".lua") then
      local cut_suffix_fname = fname:sub(1, #fname - #'.lua')
      if helper_set[cut_suffix_fname] == nil then
        local file = "user.conf." .. cut_suffix_fname
        local status_ok, _ = pcall(require, file)
        if not status_ok then
          vim.notify('Failed loading ' .. fname, vim.log.levels.ERROR)
        end
      end
    end
  end
end

M.setup()
