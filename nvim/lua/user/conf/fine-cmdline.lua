
local status_ok, fine_cmdline = pcall(require, "fine-cmdline")
if not status_ok then
  vim.notify("fine_cmdline not found!")
  return
end

fine_cmdline.setup({
    cmdline = {
        enable_keymaps = true,
        smart_history = true,
        prompt = ':'
    },
    popup = {
        position = {
            row = '80%',
            col = '50%'
        },
        size = {
            width = '60%',
            height = '80%'
        },
        border  = {
            style = 'double'
        }
    }
})
