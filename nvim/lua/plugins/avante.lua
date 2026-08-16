-- avante.nvim driven by TRAE CLI (traex) over ACP (Agent Client Protocol).
--
-- DISABLED: superseded by codecompanion (see lua/plugins/codecompanion.lua),
-- which also drives traex over ACP but adds per-hunk Code Review. The whole
-- spec is kept intact behind `enabled = false` so it can be flipped back on by
-- deleting that one line; nothing here loads while it is disabled.
--
-- `traex acp serve` starts an ACP server on stdio; avante talks to it as an
-- external agent, so no endpoint/api_key is needed here -- auth is whatever
-- `traex login` already established (trae-sso by default).
--
-- Keymap note: avante installs its default `<leader>a*` mappings via
-- `auto_set_keymaps`, which skips keys that already exist. `ai_review` (see
-- lua/plugins/dev.lua) registers `<leader>ar`/`<leader>ao` as lazy stubs at
-- startup, before avante's VeryLazy setup runs, so those stay owned by
-- ai_review and avante simply does not bind refresh onto `<leader>ar`.
--
-- nvim-tree integration: inside the tree, `<leader>a+`/`<leader>a-` add or
-- remove the file under the cursor to/from Avante's selected files. These are
-- buffer-local (ft = "NvimTree") so they never shadow nvim-tree's own `a`
-- (create) mapping. `exclude_auto_select` keeps the tree out of the file picker.
local function get_color(group, attribute, fallback)
  local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
  return highlight[attribute] or fallback
end

local function blend(foreground, background, alpha)
  local function channel(color, shift)
    return math.floor(color / (2 ^ shift)) % 256
  end

  local red = math.floor(channel(foreground, 16) * alpha + channel(background, 16) * (1 - alpha))
  local green = math.floor(channel(foreground, 8) * alpha + channel(background, 8) * (1 - alpha))
  local blue = math.floor(channel(foreground, 0) * alpha + channel(background, 0) * (1 - alpha))
  return red * 0x10000 + green * 0x100 + blue
end

local function set_avante_highlights()
  local normal_background = get_color("Normal", "bg", vim.o.background == "light" and 0xffffff or 0x000000)
  local normal_foreground = get_color("Normal", "fg", vim.o.background == "light" and 0x000000 or 0xffffff)
  local surface = get_color("CursorLine", "bg", get_color("NormalFloat", "bg", normal_background))
  local muted = get_color("Comment", "fg", normal_foreground)
  local green = get_color("DiagnosticOk", "fg", get_color("String", "fg", normal_foreground))
  local blue = get_color("DiagnosticInfo", "fg", get_color("Identifier", "fg", normal_foreground))
  local yellow = get_color("DiagnosticWarn", "fg", get_color("Function", "fg", normal_foreground))
  local red = get_color("DiagnosticError", "fg", get_color("Error", "fg", normal_foreground))
  local magenta = get_color("Title", "fg", get_color("Statement", "fg", normal_foreground))
  local diff_add = get_color("DiffAdd", "bg", surface)
  local diff_delete = get_color("DiffDelete", "bg", surface)

  local highlights = {
    AvanteTitle = { fg = normal_background, bg = green, bold = true },
    AvanteReversedTitle = { fg = green, bg = normal_background },
    AvanteSubtitle = { fg = normal_background, bg = blue, bold = true },
    AvanteReversedSubtitle = { fg = blue, bg = normal_background },
    AvanteThirdTitle = { fg = normal_foreground, bg = surface, bold = true },
    AvanteReversedThirdTitle = { fg = muted, bg = normal_background },
    AvanteToBeDeleted = { fg = red, bg = diff_delete, strikethrough = true },
    AvanteToBeDeletedWOStrikethrough = { fg = red, bg = diff_delete },
    AvanteConfirmTitle = { fg = normal_background, bg = red, bold = true },
    AvanteButtonDefault = { fg = normal_foreground, bg = surface },
    AvanteButtonDefaultHover = { fg = normal_background, bg = green, bold = true },
    AvanteButtonPrimary = { fg = normal_foreground, bg = surface },
    AvanteButtonPrimaryHover = { fg = normal_background, bg = blue, bold = true },
    AvanteButtonDanger = { fg = normal_foreground, bg = surface },
    AvanteButtonDangerHover = { fg = normal_background, bg = red, bold = true },
    AvantePromptInput = { fg = normal_foreground, bg = surface },
    AvantePromptInputBorder = { fg = blue, bg = normal_background },
    AvanteSidebarWinSeparator = { fg = surface, bg = normal_background },
    AvanteSidebarWinHorizontalSeparator = { link = "WinSeparator" },
    AvanteSidebarNormal = { link = "Normal" },
    AvanteStateSpinnerGenerating = { fg = normal_background, bg = magenta, bold = true },
    AvanteStateSpinnerToolCalling = { fg = normal_background, bg = blue, bold = true },
    AvanteStateSpinnerFailed = { fg = normal_background, bg = red, bold = true },
    AvanteStateSpinnerSucceeded = { fg = normal_background, bg = green, bold = true },
    AvanteStateSpinnerSearching = { fg = normal_background, bg = blue, bold = true },
    AvanteStateSpinnerThinking = { fg = normal_background, bg = magenta, bold = true },
    AvanteStateSpinnerCompacting = { fg = normal_background, bg = yellow, bold = true },
    AvanteTaskRunning = { fg = magenta, bg = normal_background },
    AvanteTaskCompleted = { fg = green, bg = normal_background },
    AvanteTaskFailed = { fg = red, bg = normal_background },
    AvanteThinking = { fg = magenta, bg = normal_background },
    AvanteConflictCurrent = { fg = red, bg = diff_delete, bold = true },
    AvanteConflictCurrentLabel = { fg = normal_background, bg = red, bold = true },
    AvanteConflictIncoming = { fg = green, bg = diff_add, bold = true },
    AvanteConflictIncomingLabel = { fg = normal_background, bg = green, bold = true },
  }

  for group, highlight in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, highlight)
  end

  for line = 1, 14 do
    local alpha = 0.9 - (line - 1) * 0.05
    vim.api.nvim_set_hl(0, "AvanteLogoLine" .. line, {
      fg = blend(blue, normal_background, alpha),
      bg = normal_background,
    })
  end
end

-- Fix for the sidebar getting squished into a thin sliver.
--
-- avante only restores the sidebar width on the `VimResized` autocmd (see
-- avante/init.lua), i.e. when the whole terminal is resized. Any other layout
-- churn while the sidebar is open -- `equalalways` re-balancing on split
-- open/close, an explicit `wincmd =`, opening nvim-tree, etc. -- can shrink the
-- fixed-width column and nothing pulls it back, so it stays a sliver until the
-- next full resize. We add `WinResized`/`WinClosed` hooks to correct it.
--
-- `Sidebar:resize()` is expensive (it re-renders and defers an AvanteRefresh)
-- and these events fire very frequently, so we only act when the sidebar has
-- actually deviated from its expected width. That keeps the common case free
-- and breaks the feedback loop resize() would otherwise trigger via WinResized.
local function fix_avante_sidebar_width()
  local ok, avante = pcall(require, "avante")
  if not ok or type(avante.get) ~= "function" then return end

  local sidebar = avante.get()
  if not sidebar or not sidebar:is_open() then return end

  local ok_cfg, Config = pcall(require, "avante.config")
  if not ok_cfg then return end

  local result = sidebar.containers and sidebar.containers.result
  if not (result and result.winid and vim.api.nvim_win_is_valid(result.winid)) then return end

  local expected = sidebar.is_in_full_view and (vim.o.columns - 1) or Config.get_window_width()
  local actual = vim.api.nvim_win_get_width(result.winid)
  -- 1-column slack: nothing to do when the width is already correct.
  if math.abs(actual - expected) <= 1 then return end

  pcall(function() sidebar:resize() end)
end

-- Same sliver problem, but for nvim-tree. Adding a file from the tree with
-- `<leader>aa` opens the Avante sidebar, and that split churn (plus avante's
-- own deferred resize) shrinks nvim-tree's fixed-width column with nothing to
-- pull it back. `tree.resize()` with no args resets the tree to its configured
-- width and is a no-op when the width already matches (see view.resize), so it
-- is safe to call on every layout event without feeding the WinResized loop.
local function fix_nvim_tree_width()
  local ok, nvim_tree_api = pcall(require, "nvim-tree.api")
  if not ok then return end
  if not nvim_tree_api.tree.is_visible() then return end
  pcall(function() nvim_tree_api.tree.resize() end)
end

-- Jump between parallel avante sessions with a single key. Each avante sidebar
-- lives in its own tabpage (buffers are global, so every session still sees the
-- same files), so "switch session" == "switch tabpage". This lists every tab,
-- annotates the ones holding an open avante session plus the current tab, and
-- jumps to whichever you pick.
local function switch_session()
  local tabs = vim.api.nvim_list_tabpages()
  if #tabs <= 1 then
    vim.notify("Only one tab open", vim.log.levels.INFO)
    return
  end

  local ok, avante = pcall(require, "avante")
  local sidebars = (ok and type(avante.sidebars) == "table") and avante.sidebars or {}
  local current_tab = vim.api.nvim_get_current_tabpage()

  local items = {}
  for index, tab in ipairs(tabs) do
    local sidebar = sidebars[tab]
    local is_avante = false
    if sidebar then
      local ok_open, open = pcall(function() return sidebar:is_open() end)
      is_avante = ok_open and open
    end

    local label
    if is_avante then
      label = "Avante session"
    else
      -- Fall back to the focused window's file name for plain tabs.
      local win = vim.api.nvim_tabpage_get_win(tab)
      local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
      label = name ~= "" and vim.fn.fnamemodify(name, ":t") or "[No Name]"
    end

    local marker = tab == current_tab and "  (current)" or ""
    table.insert(items, {
      tab = tab,
      text = string.format("%d: %s%s", index, label, marker),
    })
  end

  vim.ui.select(items, {
    prompt = "Switch avante session / tab",
    format_item = function(item) return item.text end,
  }, function(choice)
    if choice then vim.api.nvim_set_current_tabpage(choice.tab) end
  end)
end

return {
  {
    "yetone/avante.nvim",
    enabled = false, -- disabled in favour of codecompanion; config retained
    build = "make",
    event = "VeryLazy",
    version = false, -- never pin to "*"
    keys = {
      {
        -- Override avante's default new_ask: start a fresh session in a NEW tab
        -- so multiple avante conversations can run in parallel (avante keeps one
        -- sidebar per tabpage). Buffers are global in Neovim, so the new session
        -- still sees every file you have open. Registering this here makes
        -- avante's safe_keymap_set skip its own <leader>an default.
        "<leader>an",
        function()
          local buf = vim.api.nvim_get_current_buf()
          local buftype = vim.bo[buf].buftype
          -- `tab split` keeps the current file visible (so auto_add_current_file
          -- can pick it up); fall back to a blank tab for non-file buffers.
          if buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
            vim.cmd("tab split")
          else
            vim.cmd("tabnew")
          end
          require("avante.api").ask({ new_chat = true })
        end,
        desc = "Avante: new chat in a new tab",
        mode = { "n", "v" },
      },
      {
        -- Switch between parallel avante sessions (one per tab). `ao` was freed
        -- when ai_review was disabled; using it here keeps session controls in
        -- the <leader>a namespace.
        "<leader>ao",
        switch_session,
        desc = "Avante: switch session / tab",
        mode = "n",
      },
      {
        "<leader>aa",
        function()
          require("avante.extensions.nvim_tree").add_file()
        end,
        desc = "Avante: select file in NvimTree",
        ft = "NvimTree",
      },
      {
        "<leader>ad",
        function()
          require("avante.extensions.nvim_tree").remove_file()
        end,
        desc = "Avante: deselect file in NvimTree",
        ft = "NvimTree",
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("AvanteThemeHighlights", { clear = true }),
        callback = set_avante_highlights,
      })
      set_avante_highlights()

      -- Pull the sidebar back to its configured width after layout churn that
      -- avante itself only handles on VimResized. Deferred so it runs after
      -- Neovim has finished re-balancing windows for this event.
      vim.api.nvim_create_autocmd({ "WinResized", "WinClosed" }, {
        group = vim.api.nvim_create_augroup("AvanteFixSidebarWidth", { clear = true }),
        callback = function()
          vim.schedule(function()
            fix_avante_sidebar_width()
            fix_nvim_tree_width()
          end)
        end,
      })
    end,
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      -- Route avante through the traex ACP agent by default.
      provider = "traex",
      -- Keep the nvim-tree buffer out of Avante's own file picker; files are
      -- added from the tree via the `<leader>a+`/`<leader>a-` keys above.
      selector = {
        exclude_auto_select = { "NvimTree" },
      },
      acp_providers = {
        ["traex"] = {
          -- Resolve the absolute path so it works regardless of how nvim's
          -- PATH is set up; fall back to bare `traex` if not found.
          command = vim.fn.exepath("traex") ~= "" and vim.fn.exepath("traex") or "traex",
          args = { "acp", "serve" },
          env = {
            HOME = os.getenv("HOME"),
            PATH = os.getenv("PATH"),
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        -- image pasting support
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            use_absolute_path = true,
          },
        },
      },
      {
        -- render the Avante sidebar/markdown nicely
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
