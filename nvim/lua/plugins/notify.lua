-- notify.lua — 右上角 toast 通知(rcarriga/nvim-notify)
--
-- 作为全局 `vim.notify` 的后端: 所有 vim.notify(...) 调用都会以右上角动画 toast 呈现,
-- 支持 `replace` 句柄原地更新同一条通知(codecompanion_status 用它让每个 chat 只占一条,
-- 多 chat 并行时不会刷屏)。配合 light 主题使用。

return {
  "rcarriga/nvim-notify",
  lazy = false, -- 尽早接管 vim.notify, 保证启动早期的通知也走 toast
  priority = 900,
  opts = {
    stages = "fade_in_slide_out",
    timeout = 3000,
    top_down = true, -- 从顶部往下堆叠(右上角)
    render = "wrapped-compact",
    max_width = 60,
    fps = 30,
    background_colour = "#ffffff", -- light 主题: 避免透明度警告
  },
  config = function(_, opts)
    local notify = require("notify")
    notify.setup(opts)
    -- 右上角: nvim-notify 默认即贴右上; top_down=true 控制堆叠方向。
    vim.notify = notify
  end,
}
