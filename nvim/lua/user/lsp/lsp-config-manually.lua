-- 如果lsp-installer无法下载，可以使用本文件手动配置lsp server
local status_ok, lspconfig = pcall(require, "lspconfig")
if not status_ok then
  vim.notify("lspconfig not found!")
  return
end

-- local on_attach = require("user.lsp.handlers").on_attach,
-- local capabilities = require("user.lsp.handlers").capabilities,
-- local lsp_flags = {
--   -- This is the default in Nvim 0.7+
--   debounce_text_changes = 150,
-- }

-- local clangd_opts = require("user.lsp.settings.clangd")
-- opts = vim.tbl_deep_extend("force", clangd_opts, opts)
lspconfig.clangd.setup {
  on_attach = require("user.lsp.handlers").on_attach,
  capabilities = require("user.lsp.handlers").capabilities,
  flags = {
    debounce_text_changes = 150,
  }
}
