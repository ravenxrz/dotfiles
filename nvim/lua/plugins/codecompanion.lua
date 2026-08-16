-- codecompanion.nvim driven by TRAE CLI (traex) over ACP (Agent Client Protocol).
--
-- Why a custom ACP adapter instead of one of the presets:
--   `traex acp serve` speaks ACP over stdio and identifies itself as the
--   `traex-acp` agent. It is not one of codecompanion's built-in agents
--   (gemini_cli, claude_code, codex, ...), so we define our own adapter that
--   just launches `traex acp serve` and lets codecompanion drive it.
--
-- Auth:
--   The initialize handshake advertises authMethods (id = "trae-sso", etc.),
--   but `session/new` already succeeds once you've run `traex login` -- the
--   agent carries the SSO session itself. codecompanion's ACP client will only
--   call the AUTHENTICATE RPC when `handlers.auth` does NOT return true, so we
--   return true here to short-circuit it: no method matching, no extra RPC.
--   If you ever `traex logout`, run `traex login` again in a terminal.
--
-- Interaction scope:
--   ACP adapters power the *chat* interaction only (inline/cmd need an HTTP
--   adapter with an API key, which traex does not expose). So the keymaps below
--   cover chat, the action palette, and Code Review -- not `:CodeCompanion`
--   inline edits.
--
-- Keymaps live in the <leader>a namespace, which is free now that avante
-- (lua/plugins/avante.lua) and ai_review (lua/plugins/dev.lua) are disabled.
return {
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion",
      "CodeCompanionChat",
      "CodeCompanionActions",
      "CodeCompanionCmd",
      "CodeCompanionCLI",
      "CodeCompanionCodeReview",
      "CodeCompanionHistory",
      "CodeCompanionSummaries",
    },
    keys = {
      -- Chat -----------------------------------------------------------------
      { "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", desc = "CodeCompanion: toggle chat", mode = { "n", "v" } },
      { "<leader>aa", "<cmd>CodeCompanionActions<cr>", desc = "CodeCompanion: action palette", mode = { "n", "v" } },
      { "<leader>an", "<cmd>CodeCompanionChat<cr>", desc = "CodeCompanion: new chat", mode = "n" },
      { "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "CodeCompanion: browse chat history", mode = "n" },
      { "ga", "<cmd>CodeCompanionChat Add<cr>", desc = "CodeCompanion: add selection to chat", mode = "v" },
      -- Code Review (per-hunk, git-baseline based) ---------------------------
      -- <leader>ar opens the agent's changes in the quickfix, one entry per
      -- hunk. In that quickfix window codecompanion binds a=accept, d=diff,
      -- c=comment, x=ignore-file. <leader>ap advances the baseline so the next
      -- review is a fresh round (see :h CodeCompanionCodeReview).
      { "<leader>ar", "<cmd>CodeCompanionCodeReview<cr>", desc = "CodeCompanion: review changes (per hunk)", mode = "n" },
      { "<leader>aR", "<cmd>CodeCompanionCodeReview All<cr>", desc = "CodeCompanion: review all changes", mode = "n" },
      { "<leader>ap", "<cmd>CodeCompanionCodeReview Approve<cr>", desc = "CodeCompanion: approve / advance baseline", mode = "n" },
      -- The Code Review `d` action opens the hunk in Neovim's *native* diff
      -- (code_review/diff.lua drives two `diffthis` windows: the working file
      -- plus a `codecompanion://baseline/<path>` scratch buffer). The plugin
      -- never runs `diffoff`, so nothing closes that view. <leader>aq tears it
      -- down: wipe the baseline window(s), then diffoff whatever's left. The
      -- provider's cached panes recover on their own on the next `d`.
      {
        "<leader>aq",
        function()
          -- Close every baseline scratch window (bufhidden=wipe cleans up).
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
            if name:match("^codecompanion://baseline/") then
              pcall(vim.api.nvim_win_close, win, true)
            end
          end
          -- Drop diff mode from any window still carrying it.
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) and vim.wo[win].diff then
              vim.api.nvim_win_call(win, function()
                vim.cmd("diffoff")
              end)
            end
          end
        end,
        desc = "CodeCompanion: close native review diff",
        mode = "n",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      -- Persist chat sessions across nvim restarts. CodeCompanion core keeps
      -- chats in-memory only; this extension saves/browses/restores them via
      -- the chat lifecycle events. Config lives in `extensions.history` below.
      "ravitemer/codecompanion-history.nvim",
      {
        -- Render the chat buffer's markdown nicely. render-markdown is already
        -- installed; we just make sure it also targets the `codecompanion`
        -- filetype (the chat buffer's ft).
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "codecompanion" },
        },
        ft = { "markdown", "codecompanion" },
      },
    },
    config = function()
      require("codecompanion").setup({
        adapters = {
          acp = {
            -- Custom ACP adapter for TRAE CLI.
            traex = function()
              local helpers = require("codecompanion.adapters.acp.helpers")
              -- Resolve the absolute path so it works regardless of nvim's
              -- PATH; fall back to bare `traex` if not found on PATH.
              local traex_bin = vim.fn.exepath("traex")
              if traex_bin == "" then
                traex_bin = "traex"
              end
              return {
                name = "traex",
                formatted_name = "TRAE CLI",
                type = "acp",
                roles = {
                  llm = "assistant",
                  user = "user",
                },
                opts = {
                  vision = true, -- agent reports promptCapabilities.image = true
                },
                commands = {
                  default = { traex_bin, "acp", "serve" },
                },
                defaults = {
                  mcpServers = {},
                  timeout = 20000, -- 20s to answer initialize / session RPCs
                },
                parameters = {
                  protocolVersion = 1,
                  clientCapabilities = {
                    fs = { readTextFile = true, writeTextFile = true },
                  },
                  clientInfo = {
                    name = "CodeCompanion.nvim",
                    version = "1.0.0",
                  },
                },
                handlers = {
                  setup = function(self)
                    return true
                  end,
                  -- Return true so codecompanion skips its own authenticate
                  -- step: the traex agent already holds the `traex login`
                  -- session and session/new works without an auth RPC.
                  auth = function(self)
                    return true
                  end,
                  form_messages = function(self, messages, capabilities)
                    return helpers.form_messages(self, messages, capabilities)
                  end,
                  on_exit = function(self, code) end,
                },
              }
            end,
          },
        },
        strategies = {
          chat = {
            adapter = "traex",
            tools = {
              opts = {
                -- We drive approval toasts ourselves in
                -- features/codecompanion_status.lua (richer, per-chat, keyed by
                -- bufnr). Disable the plugin's built-in plain "Tool approval
                -- required" notify so approvals don't double-toast.
                notify_on_approval = false,
              },
            },
          },
        },
        display = {
          chat = {
            -- Using render-markdown for formatting, so let it own separators.
            show_header_separator = true,
          },
        },
        opts = {
          language = "Chinese", -- respond in Chinese
        },
        extensions = {
          -- Chat history persistence (ravitemer/codecompanion-history.nvim).
          -- Saves each chat to stdpath("data")/codecompanion-history and lets
          -- you browse/restore them after a restart.
          --
          -- Note on titles: the extension's auto title generation asks the chat
          -- adapter for a title, but it explicitly refuses ACP adapters
          -- (title_generator.lua bails when `adapter.type == "acp"`). traex is
          -- ACP, so that path is a no-op and the picker would fall back to the
          -- timestamp `save_id`. We disable it here and derive the title from
          -- the first user message ourselves (see the autocmd below).
          history = {
            enabled = true,
            opts = {
              keymap = "gh", -- open history browser from inside a chat buffer
              save_chat_keymap = "sc", -- manual save (auto_save also on)
              auto_save = true,
              picker = "telescope", -- already installed
              auto_generate_title = false, -- no-op for ACP; we title manually below
              -- Restore the last chat automatically when opening a chat on a
              -- fresh nvim start.
              continue_last_chat = true,
              -- Keep history when clearing a chat with gx.
              delete_on_clearing_chat = false,
              dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
            },
          },
        },
      })

      -- Derive a chat title from the first user message.
      --
      -- Because auto title generation is a no-op for the traex ACP adapter (see
      -- the history extension config above), `chat.opts.title` would stay nil
      -- and the CodeCompanionHistory picker would show `save_id` -- a Unix
      -- timestamp. We fill the title ourselves with the opening question so the
      -- picker shows something meaningful.
      local title_group = vim.api.nvim_create_augroup("CodeCompanionTraexTitle", { clear = true })
      vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionChatSubmitted",
        group = title_group,
        callback = function(ev)
          local bufnr = ev.data and ev.data.bufnr
          if not bufnr then
            return
          end
          local chat = require("codecompanion.interactions.chat").buf_get_chat(bufnr)
          if not chat or chat.opts.title then
            return -- already titled (ours, a restored chat, or a manual rename)
          end

          -- First visible, non-tagged user message = the opening question.
          local title
          for _, msg in ipairs(chat.messages or {}) do
            if msg.role == "user" then
              local content = vim.trim(msg.content or "")
              local tagged = msg.opts and (msg.opts.tag or msg.opts.reference or msg.opts.context_id)
              if content ~= "" and not tagged then
                title = content
                break
              end
            end
          end
          if not title then
            return
          end

          -- Keep it to a single, reasonably short line (char-aware for CJK).
          title = title:gsub("\n.*", "")
          if vim.fn.strcharlen(title) > 48 then
            title = vim.fn.strcharpart(title, 0, 48) .. "…"
          end

          chat.opts.title = title
          local history = require("codecompanion").extensions.history
          if history and history.save_chat then
            history.save_chat(chat) -- persist title into the history index
          end
        end,
      })
    end,
  },
}
