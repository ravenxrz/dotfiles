-- load treesitter parser
local path = package.path
local parser_dir = vim.fn.stdpath('config') .. "/parser"
package.path = parser_dir .. '/?.so;' .. path
