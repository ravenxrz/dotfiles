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
    cmd = {
      "CodeCompanion",
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
          -- you browse/restore them after a restart. Titles are generated by
          -- the current chat adapter (traex), so no extra API key is needed.
          history = {
            enabled = true,
            opts = {
              keymap = "gh", -- open history browser from inside a chat buffer
              save_chat_keymap = "sc", -- manual save (auto_save also on)
              auto_save = true,
              picker = "telescope", -- already installed
              auto_generate_title = true,
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
    end,
  },
}
