-- some utils for dev plugin
-- author: zhangxingrui

local reload_plugin = function(args)
  plugin_name = args.fargs[1]
  if package.loaded[plugin_name] then
    package.loaded[plugin_name] = nil
    local status, msg = pcall(require, plugin_name)
    if not status then
      vim.notify("reload plugin " .. plugin_name .. " failed", vim.log.levels.ERROR)
    end
  else
    vim.notify("no such plugin " .. plugin_name .. " loaded")
  end
end

local source_file = function()
  vim.cmd("write!")
  vim.cmd("source %")
end

vim.api.nvim_create_user_command("ReloadPlugin", reload_plugin, { nargs = 1 })
vim.api.nvim_create_user_command("SourceFile", source_file, { nargs = 0 })
