# Oh My Zsh 迁移安装包

用于 macOS 和 Linux 的 Oh My Zsh 主题与插件配置。

## 包含内容

| 类型 | 名称 | 说明 |
|------|------|------|
| 主题 | `half-lifeclean` | 主力主题 — 彩色路径 + VCS 信息 + λ 提示符 |
| 主题 | `lambda-gitster` | 备用主题 — 精简 λ + git 状态 |
| 插件 | `zsh-autosuggestions` | 命令自动补全建议（灰色提示历史命令） |
| 插件 | `zsh-syntax-highlighting` | 命令语法高亮（正确命令绿色，错误红色） |
| 插件 | `git` | Oh My Zsh 内置 git 快捷别名 |

## 一键安装

在终端中执行：

```bash
cd /path/to/omz-migrate-pack
bash install.sh
```

脚本会自动完成以下操作：

1. 检查 git、zsh 和 curl 是否可用
2. 探测 Oh My Zsh 的安装位置，没有则自动安装
3. 将两个主题文件复制到 `~/.oh-my-zsh/custom/themes/`
4. 从 GitHub 克隆 `zsh-autosuggestions` 和 `zsh-syntax-highlighting` 到 `~/.oh-my-zsh/custom/plugins/`
5. 备份当前 `~/.zshrc`，设置主题和插件，并确保 Oh My Zsh 按正确顺序加载

### 关于系统级 Oh My Zsh

部分发行版（Armbian、Orange Pi 官方镜像等）把 Oh My Zsh 装在系统级的
`/etc/oh-my-zsh`，其 `custom/` 目录归 root 所有，普通用户写不进去。

这种情况下脚本**保留**你 `.zshrc` 里原有的 `ZSH=/etc/oh-my-zsh`，同时显式写入：

```bash
ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
```

主题和插件因此始终落在用户家目录，全程不需要 sudo，也不会污染系统目录。
少了这一行，Oh My Zsh 会去 `$ZSH/custom` 找，报 `plugin '...' not found`。

## 安装后

```bash
exec zsh -l
# 或者在已经运行 zsh 时执行 source ~/.zshrc
```

## 切换主题

编辑 `~/.zshrc`，修改 `ZSH_THEME` 的值：

```bash
# 主力主题
ZSH_THEME="half-lifeclean"

# 备用主题
ZSH_THEME="lambda-gitster"
```

## 目录结构

```
omz-migrate-pack/
├── install.sh                              # 一键安装脚本
├── README.md                               # 本文件
├── tests/
│   └── install_test.sh                 # .zshrc 配置回归测试
└── themes/
    ├── half-lifeclean.zsh-theme            # 主力主题
    └── lambda-gitster.zsh-theme            # 备用主题
```
