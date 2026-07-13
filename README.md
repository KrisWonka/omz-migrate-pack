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
2. 如果没有 Oh My Zsh，自动安装
3. 将两个主题文件复制到 `~/.oh-my-zsh/custom/themes/`
4. 从 GitHub 克隆 `zsh-autosuggestions` 和 `zsh-syntax-highlighting` 到 `~/.oh-my-zsh/custom/plugins/`
5. 备份当前 `~/.zshrc`，设置主题和插件，并确保 Oh My Zsh 按正确顺序加载

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
