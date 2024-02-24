local status_ok, distant = pcall(require, "distant")
if not status_ok then
  vim.notify("comment not found!")
  return
end

-- NOTE: 2022-5-25: 目前distant和vscode的remote development比起来还是差很多，作者也长期未更新distant.nvim插件，这里的配置仅做保存。

local actions = require('distant.nav.actions')
distant.setup {
  -- Applies Chip's personal settings to every machine you connect to
  --
  -- 1. Ensures that distant servers terminate with no connections
  -- 2. Provides navigation bindings for remote directories
  -- 3. Provides keybinding to jump into a remote file's parent directory
  ['*'] = {
    distant = {
      args = '--shutdown-after 60',
    },
    file = {
      mappings = {
        ['-'] = actions.up,
      },
    },
    dir = {
      mappings = {
        ['<Return>'] = actions.edit,
        ['o']        = actions.edit,
        ['l']        = actions.edit,
        ['h']        = actions.up,
        ['-']        = actions.up,
        ['K']        = actions.mkdir,
        ['n']        = actions.newfile,
        ['r']        = actions.rename,
        ['d']        = actions.remove,
      }
    },
  },
}
