-- load themes config
require ("user.themes.github-nvim-theme")
-- require ("user.themes.onedark")
require ("user.themes.catppuccin")

-- cursor color: #61AFEF
-- local colorscheme = "vscode"
-- local colorscheme = "darkplus"
local colorscheme = "darkplus"
-- require "user.conf.github-nvim-theme"

local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)
if not status_ok then
  vim.notify("colorscheme " .. colorscheme .. " not found!")
  return
end

-- if colorscheme == "onedark" then
--   require "user.themes.onedark"
-- elseif colorscheme == "catppuccin" then
--   require "user.themes.catppuccin"
-- end
