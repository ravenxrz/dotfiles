# ============================================================================
# Mutagen workspace 配置模板 (由 remote-dev init 生成)
#
# 工作流模型: 单边 VCS (本地 = master, 远端 = slave)
#   - .git 只在本地; 所有 git 操作(含 git submodule update)只在本地执行
#   - Mutagen 只同步工作树, 不同步 .git
#   - 远端不跑 git, 只负责 build/test
#
# 配置步骤:
#   1) 修改下方 sync: 段, 每个 project 填 alpha(本地绝对路径) 和 beta(远端 host:路径)
#   2) 首灌用 one-way-safe(见 mode 注释), 排查 ignore 是否齐全 (remote-dev bootstrap)
#   3) 两端一致后改 mode 为 two-way-resolved, remote-dev restart
#
# 命令: remote-dev start|stop|flush|status|build ...
# ============================================================================

sync:
  defaults:
    # ---- 同步模式 ----
    # 首灌阶段(推荐先用): 本地 -> 远端, 只新增/更新, 不删除远端多余文件。
    #   最安全, 不会误删远端已有的编译环境。用来观察哪些文件产生冲突, 补 ignore。
    mode: "one-way-safe"
    #
    # 若首灌想让远端严格等于本地(会删除远端多余文件, 注意远端 root 文件删不动会报错):
    # mode: "one-way-replica"
    #
    # 日常使用(两端一致后切换到这个): 双向, 冲突时以本地(alpha)为准。
    # mode: "two-way-resolved"

    ignore:
      vcs: true                  # 忽略 .git 目录 (注意: 只匹配目录!)
      paths:
        # ---- .git 显式忽略 (含 submodule 的 .git 文件, 任意深度) ----
        # 关键: vcs:true 只忽略 .git *目录*, 而 git submodule 的 .git 是*文件*(gitlink),
        # 不带 / 后缀的 ".git" 会匹配任意深度、任意类型的 .git, 必须显式加。
        - ".git"

        # ---- 通用构建产物 / 输出目录 ----
        - "build/"
        - "/build/"
        - "output/"
        - "deploy_build/"
        - "cmake-build-debug/"
        - "cmake-build-*/"
        - "build64_debug/"
        - "build64_release/"

        # ---- C/C++ 编译中间产物 (源码同步, 产物不同步) ----
        - "*.a"
        - "*.o"
        - "*.so"
        - "*.lo"
        - "*.la"
        - "*.d"
        - ".libs/"
        - "config.log"
        - "config.status"
        - "CMakeFiles/"
        - "CMakeCache.txt"

        # ---- 代码索引 / tags (本地和远端各自生成, 不该同步) ----
        - "GPATH"
        - "GRTAGS"
        - "GTAGS"
        - "tags"
        - "cscope.*"
        - "compile_commands.json"

        # ---- 编辑器 / 缓存 ----
        - ".DS_Store"
        - ".vscode/"
        - ".idea/"
        - ".cache/"
        - ".claude/"
        - ".trae/"
        - "__pycache__/"
        - "*.pyc"
        - "*.swp"
        - "*.orig"

        # ---- 日志 ----
        - "*.log"

        # ============================================================
        # 以下为 **项目特定** 排除, 按需增删。规则: 带 / 前缀 = 从 workspace
        # 根算起的精确路径(只影响对应 project); 不带 / = 任意子目录同名都匹配。
        #
        # 首灌 (remote-dev bootstrap + watch) 后, 若 status 显示某些 "本地无/
        # 远端有产物" 的目录冲突, 把它们按下面格式加进来, 再 remote-dev restart。
        #
        # 常见需要排除的:
        #   - 远端运行时/测试数据混进源码树:  /onebox/local_test/  /deploy/tmp/  /ut_test/  /log/
        #   - 无权限(403)的 submodule 空目录:  /third/<name>/
        #   - submodule 内部嵌套的 thirdparty 编译目录:  /third/*/thirdparty/
        #   - 远端预编译依赖库目录(本地无, 全是 .a/.so):  /src/third_party/<dep>/
        # ============================================================
        # - "/example/runtime_data/"

    # ---- 符号链接与权限 ----
    symlink:
      mode: "posix-raw"          # 原样同步符号链接目标(不解引用)
    permissions:
      defaultFileMode: 0644
      defaultDirectoryMode: 0755

  # ==========================================================================
  # 每个 project 一个条目。会话名不能含下划线(用连字符)。
  #   alpha: 本地绝对路径
  #   beta:  远端 "ssh_host:绝对路径"  (ssh_host 用 ~/.ssh/config 里的别名)
  # ==========================================================================
  example-project:
    alpha: "/Users/leo/Projects/example/proj-a"
    beta: "devhost:/home/youruser/Projects/proj-a"

  # another-project:
  #   alpha: "/Users/leo/Projects/example/proj-b"
  #   beta: "devhost:/home/youruser/Projects/proj-b"
