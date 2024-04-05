return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    dependencies = {
      "mfussenegger/nvim-dap",
      "williamboman/mason.nvim",
    },
    config = function()
      require("mason-nvim-dap").setup({
        -- ['python'] = 'debugpy',
        -- ['cppdbg'] = 'cpptools',
        -- ['delve'] = 'delve',
        -- ['node2'] = 'node-debug2-adapter',
        -- ['chrome'] = 'chrome-debug-adapter',
        -- ['firefox'] = 'firefox-debug-adapter',
        -- ['php'] = 'php-debug-adapter',
        -- ['coreclr'] = 'netcoredbg',
        -- ['js'] = 'js-debug-adapter',
        -- ['codelldb'] = 'codelldb',
        -- ['bash'] = 'bash-debug-adapter',
        -- ['javadbg'] = 'java-debug-adapter',
        -- ['javatest'] = 'java-test',
        -- ['mock'] = 'mockdebug',
        -- ['puppet'] = 'puppet-editor-services',
        -- ['elixir'] = 'elixir-ls',
        -- ['kotlin'] = 'kotlin-debug-adapter',
        -- ['dart'] = 'dart-debug-adapter',
        -- ['haskell'] = 'haskell-debug-adapter',
        ensure_installed = { "cppdbg" },
        handlers = {
          -- function(config)
          --   -- all sources with no handler get passed here
          --
          --   -- Keep original functionality
          --   require('mason-nvim-dap').default_setup(config)
          -- end,
          cppdbg = function(config)
            local pick_file = function()
              local label_fn = function(exec_file)
                return string.format("%s", exec_file)
              end
              -- 执行 find 命令并获取结果
              local command = "find " .. vim.fn.getcwd() .. " -type d -name '.git' -prune -o -type f -executable | grep -vE 'third_party|thirdparty|3rdparty'"
              local handle = io.popen(command)
              local result = handle:read("*a")
              handle:close()
              -- 将结果分割成文件路径
              local files = {}
              for path in result:gmatch("[^\n]+") do
                table.insert(files, path)
              end
              -- 去除文件路径中的 vim.fn.getcwd() 前缀
              local relative_files = {}
              local cwd_length = string.len(vim.fn.getcwd()) + 1
              for _, file in ipairs(files) do
                table.insert(relative_files, string.sub(file, cwd_length + 1))
              end
              local co = coroutine.running()
              if co then
                return coroutine.create(function()
                  require('dap.ui').pick_one(relative_files, "Select file: ", label_fn, function(choice)
                    coroutine.resume(co, choice)
                  end)
                end)
              else
                return require('dap.ui').pick_one_sync(relative_files, "Select file: ", label_fn)
              end
            end

            config.configurations = {
              {
                name = "Launch file",
                type = "cppdbg",
                request = "launch",
                program = function()
                  local file = pick_file()
                  if file then
                    return file
                  else
                    return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                  end
                end,
                cwd = "${workspaceFolder}",
                stopAtEntry = false,
                setupCommands = {
                  {
                    text = "-enable-pretty-printing",
                    description = "enable pretty printing",
                    ignoreFailures = false,
                  },
                },
              },
              {
                name = "Attach process",
                type = "cppdbg",
                request = "attach",
                processId = require("dap.utils").pick_process,
                cwd = "${workspaceFolder}",
                setupCommands = {
                  {
                    description = "enable pretty printing",
                    text = "-enable-pretty-printing",
                    ignoreFailures = false,
                  },
                },
              },
              {
                name = "Debug coredump",
                type = "cppdbg",
                request = "launch",
                program = function()
                  return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                end,
                cwd = "${workspaceFolder}",
                coreDumpPath = function()
                  return vim.fn.input("Path to coredump: ", vim.fn.getcwd() .. "/", "file")
                end,
                stopAtEntry = false,
                setupCommands = {
                  {
                    text = "-enable-pretty-printing",
                    description = "enable pretty printing",
                    ignoreFailures = false,
                  },
                },
              },
              {
                name = "Attach to gdbserver :1234",
                type = "cppdbg",
                request = "launch",
                MIMode = "gdb",
                miDebuggerServerAddress = "localhost:1234",
                miDebuggerPath = vim.fn.exepath("gdb"),
                cwd = "${workspaceFolder}",
                program = function()
                  return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                end,
                setupCommands = {
                  {
                    text = "-enable-pretty-printing",
                    description = "enable pretty printing",
                    ignoreFailures = false,
                  },
                },
              },
            }
            require("mason-nvim-dap").default_setup(config) -- don't forget this!
          end,
        },
      })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      require("dapui").setup({
        controls = {
          element = "repl",
          enabled = true,
          icons = {
            disconnect = "",
            pause = "",
            play = "",
            run_last = "",
            step_back = "",
            step_into = "",
            step_out = "",
            step_over = "",
            terminate = "",
          },
        },
        element_mappings = {},
        expand_lines = true,
        floating = {
          border = "single",
          mappings = {
            close = { "q", "<Esc>" },
          },
        },
        force_buffers = true,
        icons = {
          collapsed = "",
          current_frame = "",
          expanded = "",
        },
        layouts = {
          {
            elements = {
              {
                id = "scopes",
                size = 0.6,
              },
              {
                id = "watches",
                size = 0.4
              }
            },
            position = "left",
            size = 40,
          },
          {
            elements = {
              {
                id = "stacks",
                size = 0.7,
              },
              {
                id = "breakpoints",
                size = 0.3,
              },
            },
            position = "right",
            size = 40,
          },
          {
            elements = {
              {
                id = "repl",
                size = 0.7,
              },
              {
                id = "console",
                size = 0.3,
              },
            },
            position = "bottom",
            size = 10,
          },
        },
        mappings = {
          edit = "e",
          expand = { "o", "<2-LeftMouse>" },
          open = "<CR>",
          remove = "d",
          repl = "r",
          toggle = "t",
        },
        render = {
          indent = 1,
          max_value_lines = 100,
        },
      })
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
  },
}
