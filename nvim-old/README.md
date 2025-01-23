## Neovim 配置


**此配置已过期**

个人neovim配置仓库，视频演示可查看[此处](https://www.bilibili.com/video/BV1WY411P736?spm_id_from=333.999.0.0)


## 要求

本配置依赖如下环境:

- neovim 版本=0.7

>建议：在[此处](https://github.com/neovim/neovim/releases)手动下载可执行文件。 通过类似 `apt` 的方式安装往往都是旧版本，arch系下载的又会过新。

- gcc, cmake, make, fd, rg, glow, lazygit, global

> ubuntu20.04的 fd, rg, glow, lazygit 已放在本仓库的bin目录下, 其余发行版请自行安装。

## 安装

**安装过程中如遇任何问题，首先查看FAQ，如仍未能解决，可加入 QQ群:728502470 反馈**

使用方法：

1. clone本仓库，并在 `~/.config` 目录下建立nvim的软链接
  ```shell
  git clone https://github.com/ravenxrz/dotfiles.git ~/.config/dotfiles
  ln -s ~/.config/dotfiles/nvim ~/.config
  ```

2.执行 `nvim +PackerSync` 命令， 根据网络条件的不同，可能需要多次执行本命令，直到所有插件下载完成

3.通过`LspInstallInfo`命令安装对应lsp svr, 接着选中对应语言的server，如cpp为clangd， 按i执行安装

4.通过`DIInstall xxx`命令安装对应语言的 `debugger`, 除此外，需要在 `~/.dotfiles/nvim/lua/user/dap/`目录下新建对应语言的配置文件（已配置好c/cpp,go,python), 同时更新 `dap-config.lua` 文件下的 `config_debuggers()` 函数。

## 常用快捷键说明

> 注意：随着个人使用习惯的改变，快捷键可能会有所更改。
> 快捷键定义位置说明：
>
> 1. 常用快捷键在 keymaps.lua 文件下定义
> 2. 和插件特定的快捷键一部分放在keymaps.lua文件，大部分放在该插件配置文件处。
>
> 可通过 `<space>`+h+k 快捷键调出快捷键查询窗口

个人 `leader `键位设置为分号`;`

### 1. 文件目录 

| 快捷键         | 功能                         |
| -------------- | ---------------------------- |
| `<space>` + e | 开关目录树                   |
| o              | 打开文件/打开文件目录        |
| h              | 折叠一个层级目录             |
| d              | 删除文件                     |
| a              | 新建文件/新建文件夹          |
| r              | 重命名文件                   |
| x              | 剪切文件                     |
| p              | 粘贴                         |
| gy             | 拷贝文件绝对路径             |
| Y              | 拷贝文件相对路径             |
| y              | 拷贝文件名                   |

更多快捷键见 nvim-tree.lua 顶部注释

### 2. 常规动作

| 快捷键             | 功能                                                         |
| ------------------ | ------------------------------------------------------------ |
| `<space>` + o      | 打开大纲                                                     |
| `<space>` + f      | 搜索文件                                                     |
| `<space>` + F      | 搜索字符(依赖rg，可传入rg的各类参数，实现忽略大小写、正则表达式搜索等) |
| `<space>` + p      | 切换项目                                                     |
| `<space>` + P      | 切换会话                                                     |
| `<space>` + r      | 最近文件                                                     |
| `<space>` + R      | 打开替换窗口                                                 |
| E                  | 打开左边标签页                                               |
| R                  | 打开右边标签页                                               |
| `<ctrl>` + h/j/k/l | 进入左边/下边/上边/右边窗口                                  |
| `<ctrl> + \`       | 打开终端                                                     |
| `<leader>` + q     | 关闭窗口                                                     |
| `<leader>` + D     | 关闭buffer                                                   |

### 3. 代码导航

| 快捷键          | 功能                                                         |
| --------------- | ------------------------------------------------------------ |
| `<leader>` + t  | 在声明/定义间来回跳转 (c和cpp项目，需要导出compile_commands.json文件) |
| `<leader>` + u  | 查看代码引用                                                 |
| `<leader>`+ in  | 函数调用链                                                   |
| `]]`            | 跳转到下一个函数头                                           |
| `][`            | 跳转到下一个函数尾                                           |
| `[[`            | 跳转到上一个函数头                                           |
| `[]`            | 跳转到上一个函数尾                                           |
| gh              | 查看函数签名+注释文档                                        |
| gl              | 查看代码诊断                                                 |
| `<leader>` + rn | 重命名符号                                                   |
| `<space>` + s   | 搜索当前窗口下的符号 (类似vscode的 `@`)                      |
| `<space>` + S   | 搜索项目下的符号 (类似vscode `#`)                            |

### 4. 代码诊断

| 快捷键          | 功能                                |
| --------------- | ----------------------------------- |
| `<leader>` + dj | 下一个错误                          |
| `<leader>`+ dk  | 上一个错误                          |
| `<space>` + Td  | 错误窗口 （类似vscode problem pane) |

### 5. Git操作

| 快捷键          | 功能         |
| --------------- | ------------ |
| `<leader>` + j | 下一个hunk   |
| `<leader>` + k | 上一个hunk   |
| `<leader>` + hs | stage hunk   |
| `<leader>` + hu | unstage hunk |
| `<leader>` + hr | reset hunk   |
| `<leader>` + hp | preview hunk |
| `<space>` + gd  | diff file    |
| `<space>` + gf  | file history |
| `<space>` + gg  | 打开lazygit  |

### 6. Debug

| 快捷键          | 功能                                                         |
| --------------- | ------------------------------------------------------------ |
| `<leader>` + db | 开关断点                                                     |
| `<leader>` + dc | 条件断点                                                     |
| `<F5>/<F10>`    | 开始调试/continue                                            |
| `<F4>`          | 结束调试会话                                                 |
| `<F6>`          | stepover                                                     |
| `<F7>`          | stepinto                                                     |
| `<F8>`          | stepout                                                      |
| `<shift>` + k   | 变量悬浮窗（查看cursor下变量的值, 按两次`<shift>`+k使cursor聚焦到悬浮窗) |

### 7. 其他

- cmake： `<space>` + c后，查看which key的提示
- ultest: 单元测试插件， `<space>` + t
- TodoList:  无快捷键，执行 `:TodoTrouble`查看
- LocalHistory： 无快捷键， 执行 `:LocalHistoryToggle`查看
- Lsp svr： `<space>`+li（小l和小i), 查看当前lsp状态， `<space>` + lI(小L和大I)安装lsp svr

## FAQ

**1.插件下载不下来？**

网络问题，插件都在github上，考虑加代理。

**2.bin目录下的可执行文件如何使用？**

bin目录下的文件是一些依赖可执行文件，如果通过 `install` 命令安装了所有配置，该目录默认会加载至系统PATH变量中，否则需要个人手动将该目录添加至PATH中，另外，这些文件仅在ubuntu20.04中测试使用通过，其余系统不保证。 所以可考虑手动下载依赖, 如 `apt install xxx`, `yum install xx` `pacman -S xxx`等等。

**3.终端颜色有问题?**

> mac建议使用iterm2, 或者kitty， 不建议使用默认终端。

确认终端支持真彩色, 另外将 $TERM 环境变量设为 `xterm-256color`. 

**4.出现xxx not found**

大概率是因为没有下载完插件。 可以使用 `PackerStatus` 查看下当前有哪些插件。

**5.图标乱码问题**

没有安装nerd font, 请自行安装nerd font，并设置终端字体为对应的nerd font。

如果安装后，代码显示出现“残缺”，查看问题11。

**6.PackerSync命令找不到？**

packer插件自动下载失败，网络问题。遇到此问题，可手动清除 `~/.local/share/nvim/site/pack/packer/start/packer.nvim/` 目录，然后重新开启nvim。不过首先要解决的是你的网络问题。

**7. 如何在右上角显示实时cpu和mem？**

这是tmux的配置，和nvim无关，有兴趣可自行查看我的tmux配置。

> 提示：要安装 `ravenxrz/tmux-plugin-sysstat` tmux插件，另外需要手动配置主题。如：
>
> `set -g status-right "#[fg=#1f2428,bg=#1f2428,nobold,nounderscore,noitalics]#[fg=#1f2428,bg=#1f2428] #{prefix_highlight} #[fg=#e1e4e8,bg=#1f2428,nobold,nounderscore,noitalics]#[fg=#586069,bg=#e1e4e8] %Y-%m-%d  %I:%M %p #[fg=#2188ff,bg=#e1e4e8,nobold,nounderscore,noitalics]#[fg=#1f2428,bg=#2188ff,bold] #{sysstat_cpu}#[fg=#1f2428,bg=#2188ff,bold] #{sysstat_mem}#[fg=#2188ff,bg=#2188ff,bold] "`

**8. c/cpp项目如何导出 compile_commands.json 文件？**

- makefile管理的项目： 使用 bear 工具（开源工具，自行下载），然后在项目工程下执行 `bear -- make` 
- cmake管理的项目： 使用快捷键 `<space> + cg`

**9. failed loading telescope.lua**

确保所有插件均安装完成，如仍有该错误，打开telescope.lua, 注释掉最后几行的 `load_extesion(xxx)`

**10. wsl nvim启动速度极慢，超过2s**

确保wsl版本为wsl2。

**11. Windows Terminal 字体显示 "残缺" 问题**

似乎是windows termianl的bug。[issuse](https://github.com/microsoft/terminal/issues/9381)

我个人的解决方案：

打开nerd font github 官网，想要的字体->Ligatures->字体样式（Bold, Italic, Medium, Regular都下载一份并安装)

以JetBriansMono字体为例, 安装如下目录字体:
<img src="https://cdn.JsDelivr.net/gh/ravenxrz/PicBed/img/image-20220524184305412.png" alt="image-20220524184305412" style="zoom: 33%;" />

打开windows设置，得到结果：
<img src="https://cdn.JsDelivr.net/gh/ravenxrz/PicBed/img/image-20220524184402745.png" alt="image-20220524184402745" style="zoom:33%;" />

重新设置windows terminal字体并重启即可。

**12. 提示GUN Global not found**

两种解决方案：
1. 安装global包即可
2. 该依赖主要在c/c++开发中使用，不需要的去掉 `jsfaint/gen_tags.vim` 插件即可。
