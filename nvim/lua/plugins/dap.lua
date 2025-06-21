return {
  {
    "sakhnik/nvim-gdb",
    config = function()
      vim.cmd([[
       let g:nvimgdb_use_cmake_to_find_executables = 0
       let g:nvimgdb_use_find_executables = 0
       let g:nvimgdb_config = {
        \ 'sign_current_line': '▶',
        \ 'sign_breakpoint': [ '●', '●²', '●³', '●⁴', '●⁵', '●⁶', '●⁷', '●⁸', '●⁹', '●ⁿ' ],
        \ 'sign_breakpoint_priority': 10,
        \ 'termwin_command': 'rightbelow vnew',
        \ 'codewin_command': 'vnew',
        \ 'set_scroll_off': 5,
        \ 'jump_bottom_gdb_buf': v:false,
        \ }
     ]])
     -- 对于一些非常复杂的程序，需要使用高版本的gdb
     -- 编译时需要带上python扩展
     --[[
       wget https://ftp.gnu.org/gnu/gdb/gdb-13.2.tar.xz
       tar xf gdb-13.2.tar.xz
       cd gdb-13.2
       mkdir build && cd build
       ../configure \
        --prefix=$HOME/.local \
        --with-system-readline \
        --with-python=/usr/bin/python3 \
        --enable-tui \
        --enable-gdbserver \
        --enable-werror=no
       make -j
       make install
     ]]--
     -- 如果安装gdb无法方便调试stl, 尝试以下命令
     -- ln -s /usr/share/gdb/auto-load ~/.local/share/gdb/auto-load/
     
      -- nvim gdb debug
      local opts = { noremap = true, silent = true }
      vim.keymap.set("n", "<F5>", ":GdbBreakpointToggle<cr>", opts)
      vim.keymap.set("n", "<leader>dc", "<cmd>ElfCoreDebug<cr>", opts)
      vim.keymap.set("n", "<leader>dt", "<cmd>GdbDebugUt<cr>", opts)
    end
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- event = "VeryLazy",
    dependencies = {
      "mfussenegger/nvim-dap",
      {
        "williamboman/mason.nvim",
        -- cmd = { "Mason" },
      },
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
        ensure_installed = { "cppdbg", "python" },
        handlers = {
          function(config)
            -- all sources with no handler get passed here

            -- Keep original functionality
            require("mason-nvim-dap").default_setup(config)
          end,
          python = function(config)
            config.adapters = {
              type = "executable",
              command = "/usr/bin/python3",
              args = {
                "-m",
                "debugpy.adapter",
              },
            }
            require("mason-nvim-dap").default_setup(config) -- don't forget this!
          end,
          cppdbg = function(config)
            local pick_file = function()
              local label_fn = function(exec_file)
                return string.format("%s", exec_file)
              end
              -- 执行 find 命令并获取结果
              local command = "find "
                  .. vim.fn.getcwd()
                  .. " -type d -name '.git' -prune -o -type f -executable | grep -vE 'third_party|thirdparty|3rdparty'"
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
                  require("dap.ui").pick_one(relative_files, "Select file: ", label_fn, function(choice)
                    coroutine.resume(co, choice)
                  end)
                end)
              else
                return require("dap.ui").pick_one_sync(relative_files, "Select file: ", label_fn)
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
                program = function()
                  return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                end,
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
  }
}
