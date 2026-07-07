# remote-dev — 基于 Mutagen 的远程开发同步

在本地用**原生编辑器**(Neovim / VSCode 等)丝滑编辑代码，后台把工作树**增量同步**到远端开发机，远端负责编译/测试。彻底解决 "SSH 到服务器再打开编辑器" 的按键延迟卡顿。

思路等价于 VSCode Remote 的 "本地 UI + 远程算力"，但用 Mutagen 做文件层同步，编辑器完全在本地，零网络延迟。

---

## 目录结构

```
~/.config/dotfiles/remote_dev/         (= ~/.dotfiles/remote_dev, 已在 PATH)
├── remote-dev                 # 主 CLI (可执行)
├── templates/
│   └── mutagen.yml.tpl        # 新 workspace 配置模板(含全部 ignore 最佳实践)
└── README.md                  # 本文档
```

> `~/.dotfiles/remote_dev/` 已在 `$PATH` 中，所以 `remote-dev` 命令可在任意目录直接调用。

---

## 一、依赖

| 依赖 | 说明 | 安装 |
|------|------|------|
| **mutagen** | 核心同步引擎(客户端 + daemon)。首次连接远端时会自动上传对应架构的 agent 到远端 `~/.mutagen/agents/`，远端**无需预装**。 | `HOMEBREW_NO_REQUIRE_TAP_TRUST=1 brew install mutagen-io/mutagen/mutagen` |
| **ssh** | 用于连接远端。远端 host 建议在 `~/.ssh/config` 里配好别名(含 `HostName`/`User`/`ProxyJump`)。 | 系统自带 |
| **bash/zsh** | 运行 `remote-dev` 脚本。 | 系统自带 |
| git (可选) | 单边 VCS 模型下，git 操作只在本地执行。 | — |

安装校验：
```bash
mutagen version          # 应打印版本, 如 0.18.1
mutagen daemon start     # 启动后台 daemon (remote-dev 会自动确保)
```

> **Homebrew tap 信任问题**：若 `brew install` 报 `Refusing to load formula ... from untrusted tap`，前面加 `HOMEBREW_NO_REQUIRE_TAP_TRUST=1` 即可。

---

## 二、核心概念

### 工作流模型：单边 VCS (本地 = master，远端 = slave)

这是整套方案能稳定工作的关键前提：

- **`.git` 只在本地**。所有 git 操作(`checkout`、`rebase`、`git submodule update`)**只在本地执行**。
- Mutagen 只同步**工作树文件**，**不同步 `.git`**。
- **远端不跑 git**，只作为编译/测试算力。

为什么？如果两端各有 `.git` 各自跑 git，切分支/commit 后两端状态会分叉，陷入 "一边 clean 一边全是 modified" 的死循环。让 `.git` 只在一侧、只同步工作树，就彻底避免了这个问题。

### 三种同步模式

| 模式 | 行为 | 用途 |
|------|------|------|
| `one-way-safe` | 本地→远端，只新增/更新，**不删除**远端多余文件 | **首灌推荐**：最安全，用来排查 ignore |
| `one-way-replica` | 本地→远端，远端严格等于本地(**会删**远端多余文件) | 想让远端完全镜像本地(注意远端 root 文件删不动会报错) |
| `two-way-resolved` | 双向，两端改动互传，**冲突以本地(alpha)为准** | **日常使用** |

### workspace

一个 workspace = 一个含 `mutagen.yml` 的目录，里面可定义**多个 project**（多个同步会话），作为一组统一 start/stop/flush。这就是 "一个项目里打开多个 project 一起同步" 的能力。

---

## 三、Step-by-Step：配置一个新 workspace

假设本地代码在 `~/Projects/myapp/{svc-a,svc-b}`，远端开发机 ssh 别名 `devhost`，远端目标 `~/Projects/{svc-a,svc-b}`。

### 步骤 0：准备远端 SSH 别名（建议）

在 `~/.ssh/config` 里配好，让 `ssh devhost` 能直接连上：
```
Host devhost
  HostName 10.x.x.x
  User youruser
  # ProxyJump jumphost      # 如需跳板
```
验证：`ssh devhost 'echo OK; whoami; pwd'`

### 步骤 1：生成配置模板

```bash
cd ~/Projects/myapp
remote-dev init            # 在当前目录生成 mutagen.yml
```

### 步骤 2：编辑 mutagen.yml

打开 `~/Projects/myapp/mutagen.yml`，改 `sync:` 段末尾的 project 列表：

```yaml
  svc-a:
    alpha: "/Users/leo/Projects/myapp/svc-a"
    beta: "devhost:/home/youruser/Projects/svc-a"
  svc-b:
    alpha: "/Users/leo/Projects/myapp/svc-b"
    beta: "devhost:/home/youruser/Projects/svc-b"
```

> ⚠️ **会话名(project 名)不能含下划线**，用连字符。如 `dbstore-coordinator`。
> 路径可以照常用下划线，只有 YAML key 有此限制。

### 步骤 3（可选）：本地补全 submodule

单边 VCS 模型下 submodule 也在本地管理：
```bash
cd ~/Projects/myapp/svc-a
# 若走公司内网 git, 加代理:
export https_proxy=http://sys-proxy-rd-relay.byted.org:8118 \
       http_proxy=http://sys-proxy-rd-relay.byted.org:8118 \
       no_proxy="byted.org,.byted.org,bytedance.net,.bytedance.net,10.0.0.0/8,127.0.0.1"
git submodule update --init          # 无权限(403)的会失败, 跳过即可
```
无权限拉取的 submodule 会是空目录，稍后在 ignore 里整体排除它。

### 步骤 4：首灌（one-way-safe，排查 ignore）

模板默认 `mode: one-way-safe`（只推不删，最安全）。启动并盯扫描：
```bash
cd ~/Projects/myapp
remote-dev bootstrap       # = start, 但提示你当前应处于首灌模式
remote-dev watch           # 持续显示扫描进度, 直到全部进入 Watching
```

> **首次扫描可能很慢**（几分钟到半小时），取决于文件数量。大型 submodule
> (如几十万文件的库) 首次建立快照哈希是纯粹的规模成本。**只发生在首次/重建会话时**，之后增量同步是秒级的。

### 步骤 5：看冲突，补 ignore

```bash
remote-dev status
```
若看到某 project 有 `Conflicts` 或 `Transition problems`，多半是**远端有、本地没有的产物/依赖**（远端是编译过的重环境）。查看详情：
```bash
mutagen sync list --long <project-name> | grep -A20 Conflicts
```
把这些 "本地无、远端产物" 的路径加进 `mutagen.yml` 的 `ignore.paths`（模板底部有示例和规则说明），然后：
```bash
remote-dev restart         # ignore 变更需重建会话才生效 (会重扫)
remote-dev watch
```
重复步骤 5 直到 `remote-dev status` 显示全部 **Watching for changes、0 冲突、0 problems**。

> 常见需排除项(见模板注释)：`/onebox/local_test/`(远端运行数据)、`/third/<name>/`(403 空 submodule)、`/third/*/thirdparty/`(嵌套编译目录)、`/src/third_party/<dep>/`(预编译库)。

### 步骤 6：切到日常双向同步

两端一致后，编辑 `mutagen.yml`：
```yaml
    # mode: "one-way-safe"
    mode: "two-way-resolved"        # 启用双向
```
```bash
remote-dev restart
remote-dev watch                    # 等最后一次重扫完成
remote-dev status                   # 确认全部 Watching, 0 冲突
```

搭建完成 ✅

---

## 四、日常使用

```bash
cd <workspace>                      # 或设 export REMOTE_DEV_WORKSPACE=<workspace>

remote-dev start                    # 开工: 启动同步
remote-dev status                   # 查看状态/冲突

# --- 编辑 ---
# 用本地 Neovim/VSCode 直接编辑, 改动自动同步到远端

# --- 切分支 (关键: 让远端拿到完整最新代码) ---
remote-dev checkout <branch>        # 一键: flush→git checkout+submodule→flush→status
                                    # (对 workspace 内所有 project 仓库切同名分支)
remote-dev checkout <proj> <branch> # 只切指定 project

# --- 远端构建 ---
remote-dev build svc-a ./build.sh   # 自动 flush 后在远端 svc-a 目录执行

remote-dev stop                     # 暂时不用(保留会话)
remote-dev down                     # 彻底关闭清理
```

### 为什么切分支要 `flush`

Mutagen 默认基于文件监听自动同步，但切分支瞬间大量文件变化，`flush` 会**强制同步一轮并阻塞到落盘**，保证远端构建时代码是完整、最新的，不会编译到 "新旧混合" 的中间态。这是做到 "无感" 的关键一步。

`remote-dev checkout <branch>` 把这套动作封装成一条命令，内部依次执行：
1. **前置 flush** — 结算两端 pending 改动，避免 checkout 被本地意外改动挡住
2. **本地 `git checkout` + `git submodule update`** — 对 workspace 内每个 project 仓库执行（分支不存在的自动跳过；submodule 无权限的忽略）
3. **后置 flush** — 把切分支的大 diff 推到远端并阻塞到落盘
4. **status** — 确认全部 Watching

> 单独 project 分支不同时用 `remote-dev checkout <proj> <branch>`。
> **不要**用 `stop`/`down` 再切分支——`resume`/`restart` 会触发全量重扫（大仓库很慢）。让同步保持运行，靠增量 + flush 即可。

---

## 五、命令参考

| 命令 | 说明 |
|------|------|
| `remote-dev init [dir]` | 在 dir(默认当前目录)生成 mutagen.yml 模板 |
| `remote-dev bootstrap` | 首灌(需 mode=one-way-safe/replica)：只推不删 |
| `remote-dev start` | 启动 workspace 所有同步会话 |
| `remote-dev stop` | 暂停(保留会话，可 resume) |
| `remote-dev resume` | 恢复 |
| `remote-dev down` | 终止并清理 |
| `remote-dev restart` | down + start（改 ignore/mode 后用） |
| `remote-dev status [name]` | 查看状态/冲突/问题 |
| `remote-dev flush` | 强制同步一轮并阻塞到落盘(切分支后用) |
| `remote-dev sync` | flush + status |
| `remote-dev watch` | 持续监控首次扫描直到完成 |
| `remote-dev checkout <branch>` | 切分支(全部 project)：flush→checkout+submodule→flush→status |
| `remote-dev checkout <proj> <branch>` | 只切指定 project |
| `remote-dev build <proj> <cmd>` | flush 后在远端 `<proj>` 目录执行 `<cmd>` |

**workspace 定位顺序**：① 环境变量 `REMOTE_DEV_WORKSPACE` ② 当前目录向上查找 `mutagen.yml`。

---

## 六、排障

| 现象 | 原因 | 解决 |
|------|------|------|
| `invalid synchronization session name ... '_'` | project 名(YAML key)含下划线 | 改用连字符，如 `my-proj` |
| 一直 `Scanning files` 不结束 | 文件数巨大(大型 submodule)首次建快照 | 正常，耐心等；`remote-dev watch` 盯着。确认远端 `mutagen-agent` 有 CPU 占用即在干活 |
| `Transition problems: permission denied` | one-way-replica 想删远端 root 拥有的文件 | 改用 `one-way-safe`(不删)，或把该路径 ignore |
| `Conflicts` 全是 "本地无、远端 Untracked" | 远端有编译产物/依赖，本地没有 | 把这些路径加进 `ignore.paths`，`remote-dev restart` |
| submodule 的 `.git` 反复冲突 | `vcs:true` 只忽略 `.git` 目录，submodule 的 `.git` 是文件 | 模板已含显式 `- ".git"`，确保没删掉它 |
| 改了 ignore 但没生效 | Mutagen 会话创建时锁定 ignore | 必须 `remote-dev restart` 重建会话 |
| 双向模式下本地冒出预期外文件 | 远端产生的新产物未被 ignore 回灌了 | 加 ignore + restart |
| 远端 host 连不上 | ssh 别名/跳板问题 | 先 `ssh <host> 'echo ok'` 单独验证 |

**查看某会话详情**：
```bash
mutagen sync list --long <project-name>
```
**查看 daemon**：
```bash
mutagen daemon stop && mutagen daemon start   # 升级 mutagen 后需重启 daemon
```

---

## 七、设计要点回顾

1. **本地编辑零延迟**：编辑器完全在本地，网络上只走文件同步，不走按键。
2. **单边 VCS**：`.git` 只在本地，`.git` + submodule 的 `.git` 文件都 ignore，远端不跑 git。
3. **首灌用 one-way-safe**：只推不删，安全地把本地铺到远端，同时暴露需要 ignore 的远端产物。
4. **ignore 要覆盖**：构建产物、运行数据、代码索引、预编译依赖库、无权限 submodule。远端往往是 "重环境"(几百 G 产物)，ignore 到位后同步量降到源码级别。
5. **切分支 flush**：把切分支变成 "改文件 → flush → 远端可编译" 的原子动作。
