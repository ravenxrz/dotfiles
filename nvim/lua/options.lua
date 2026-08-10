
-- nvim tree requirements begin
-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true
-- nvim tree requirements end

-- Use OSC52 as the explicit clipboard provider for remote terminal sessions.
-- This lets yanks in server-side Neovim update the local terminal clipboard
-- when the terminal supports OSC52 (for example Ghostty, iTerm2, WezTerm, tmux).
--
-- The correct provider depends on whether we are inside tmux:
--
--   * Direct to iTerm2/Ghostty (no tmux): iTerm2 only acts on a BEL-terminated
--     (\007) OSC 52 sequence.  Neovim's built-in provider emits an ST-terminated
--     (ESC \) form, which iTerm2 ignores -- this is why a bare
--     `ssh -> nvim -> yank` never reached the macOS clipboard.  So we emit BEL
--     via nvim_ui_send.  Ghostty accepts either form and keeps working.
--   * Inside tmux: use a tmux-specific provider that wraps the OSC 52 in tmux's
--     DCS passthrough envelope (ESC P tmux ; ... ESC \, with inner ESCs doubled).
--     This makes tmux forward the sequence verbatim to the outer terminal,
--     bypassing tmux's native set-clipboard forwarding -- which is unreliable
--     here because this host's terminfo has no `Ms` clipboard capability.
--     Requires `set -g allow-passthrough on` in tmux.conf.
if vim.env.SSH_TTY then
  vim.opt.clipboard:append("unnamedplus")

  local function paste()
    return { vim.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end

  -- Build a BEL-terminated OSC 52 payload for the given register.
  local function osc52_seq(reg, lines)
    local sel = reg == "+" and "c" or "p"
    local data = vim.base64.encode(table.concat(lines, "\n"))
    return string.format("\027]52;%s;%s\007", sel, data)
  end

  -- Send raw bytes through the TUI output path (falls back to stderr channel).
  local function tty_send(sequence)
    local ok = pcall(vim.api.nvim_ui_send, sequence)
    if not ok then
      pcall(vim.api.nvim_chan_send, 2, sequence)
    end
  end

  if vim.env.TMUX then
    -- tmux-specific provider: wrap in DCS passthrough so tmux forwards it
    -- verbatim to the outer terminal (iTerm2), which then reads the BEL-
    -- terminated OSC 52.
    local function tmux_copy(reg)
      return function(lines)
        local inner = osc52_seq(reg, lines)
        -- Double every ESC inside the payload, then wrap: ESC P tmux ; ... ESC \
        local wrapped = "\027Ptmux;" .. inner:gsub("\027", "\027\027") .. "\027\\"
        tty_send(wrapped)
      end
    end

    vim.g.clipboard = {
      name = "OSC 52 (tmux passthrough)",
      copy = {
        ["+"] = tmux_copy("+"),
        ["*"] = tmux_copy("*"),
      },
      paste = {
        ["+"] = paste,
        ["*"] = paste,
      },
    }
  else
    -- No tmux (direct iTerm2/Ghostty): emit a BEL-terminated OSC 52 sequence.
    local function osc52_copy(reg)
      return function(lines)
        tty_send(osc52_seq(reg, lines))
      end
    end

    vim.g.clipboard = {
      name = "OSC 52 (BEL)",
      copy = {
        ["+"] = osc52_copy("+"),
        ["*"] = osc52_copy("*"),
      },
      paste = {
        ["+"] = paste,
        ["*"] = paste,
      },
    }
  end
end

local opts = {
  -- eadirection = 'ver',                                                                             -- keep other window to a fixed size when vsplit (keep grug-far plugin to a fixed size)
  backup = false,                                                                                   -- creates a backup file
  clipboard = "unnamedplus",                                                                        -- allows neovim to access the system clipboard
  cmdheight = 1,                                                                                    -- keep status bar position close to bottom
  completeopt = { "menuone", "noselect" },                                                          -- mostly just for cmp
  conceallevel = 0,                                                                                 -- so that `` is visible in markdown files
  fileencoding = "utf-8",                                                                           -- the encoding written to a file
  hlsearch = true,                                                                                  -- highlight all matches on previous search pattern
  ignorecase = true,                                                                                -- ignore case in search patterns
  mouse = "a",                                                                                      -- allow the mouse to be used in neovim
  pumheight = 10,                                                                                   -- pop up menu height
  showmode = false,                                                                                 -- we don't need to see things like -- INSERT -- anymore
  smartcase = true,                                                                                 -- smart case
  smartindent = true,                                                                               -- make indenting smarter again
  splitbelow = true,                                                                                -- force all horizontal splits to go below current window
  splitright = true,                                                                                -- force all vertical splits to go to the right of current window
  swapfile = false,                                                                                 -- creates a swapfile
  termguicolors = true,                                                                             -- set term gui colors (most terminals support this)
  timeoutlen = 500,                                                                                 -- time to wait for a mapped sequence to complete (in milliseconds)
  undofile = true,                                                                                  -- enable persistent undo
  updatetime = 300,                                                                                 -- faster completion (4000ms default)
  writebackup = false,                                                                              -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
  expandtab = true,                                                                                 -- convert tabs to spaces
  shiftwidth = 2,                                                                                   -- the number of spaces inserted for each indentation
  tabstop = 2,                                                                                      -- insert 2 spaces for a tab
  cursorline = true,                                                                                -- highlight the current line
  cursorcolumn = false,                                                                             -- cursor column.
  number = true,                                                                                    -- set numbered lines
  relativenumber = false,                                                                           -- set relative numbered lines
  numberwidth = 2,                                                                                  -- set number column width to 2 {default 4}
  signcolumn = "yes",                                                                               -- always show the sign column, otherwise it would shift the text each time
  wrap = false,                                                                                     -- display lines as one long line
  scrolloff = 8,                                                                                    -- keep 8 height offset from above and bottom
  sidescrolloff = 8,                                                                                -- keep 8 width offset from left and right
  foldmethod = "expr",                                                                              -- fold with nvim_treesitter
  foldexpr = "v:lua.vim.treesitter.foldexpr()",
  foldenable = true,                                                                                -- enable Tree-sitter folds
  foldlevel = 99,                                                                                   -- keep folds open by default
  foldlevelstart = 99,                                                                              -- keep folds open when opening a file
  spell = false,                                                                                    -- add spell support
  spelllang = { "en_us" },                                                                          -- support which languages?
  diffopt = "vertical,filler,internal,context:4",                                                   -- vertical diff split view
  sessionoptions = "blank,buffers,curdir,folds,help,tabpages,terminal,localoptions", -- session
  showtabline = 0,                                                                                  -- disable status line
  inccommand = "",                                                                                  -- disable replace preview
}

for k, v in pairs(opts) do
  vim.opt[k] = v
end
