#!/bin/bash
# ============================================================
#  Oh My Zsh 主题 & 插件 一键迁移安装脚本
#  支持 macOS / Linux
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Oh My Zsh 主体目录（可能是系统级的 /etc/oh-my-zsh），由 install_omz 探测后填入。
OMZ_ROOT=""
# 主题与插件一律装到用户家目录：系统级安装的 $ZSH/custom 归 root 所有，
# 普通用户写不进去，而 Oh My Zsh 支持 ZSH_CUSTOM 独立于 ZSH。
OMZ_CUSTOM="$HOME/.oh-my-zsh/custom"

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ------ 前置检查 ------
check_prerequisites() {
    info "检查运行环境..."

    if ! command -v git &>/dev/null; then
        error "未检测到 git，请先安装 git"
    fi

    if ! command -v zsh &>/dev/null; then
        error "未检测到 zsh，请先安装 zsh"
    fi

    if ! command -v curl &>/dev/null; then
        error "未检测到 curl，请先安装 curl"
    fi

    success "环境检查通过 (git + zsh + curl)"
}

# ------ 探测 Oh My Zsh 安装位置 ------

# 读出 .zshrc 里已声明的 ZSH= 路径并展开 ~ 与 $HOME；没有则输出空串。
declared_zsh_root() {
    local ZSHRC="$HOME/.zshrc"
    local value=""

    [ -f "$ZSHRC" ] || return 0
    if grep -Eq '^[[:space:]]*(export[[:space:]]+)?ZSH=' "$ZSHRC"; then
        value="$(grep -E '^[[:space:]]*(export[[:space:]]+)?ZSH=' "$ZSHRC" \
            | tail -n 1 \
            | sed -E 's/^[[:space:]]*(export[[:space:]]+)?ZSH=//; s/[[:space:]]*#.*$//; s/[[:space:]]*$//' \
            | tr -d "\"'")"
        value="${value/#\~/$HOME}"
        value="${value//\$\{HOME\}/$HOME}"
        value="${value//\$HOME/$HOME}"
    fi

    printf '%s' "$value"
}

# 定位 Oh My Zsh 主体目录：用户级优先，其次采纳 .zshrc 里声明的系统级安装
# （Armbian / Orange Pi 装在 /etc/oh-my-zsh）。都没有则返回 1 表示尚未安装。
# 判据是 oh-my-zsh.sh 是否存在 —— 光看目录会被只含 cache/ 的空壳骗过。
resolve_omz_root() {
    local declared

    if [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
        printf '%s' "$HOME/.oh-my-zsh"
        return 0
    fi

    declared="$(declared_zsh_root)"
    if [ -n "$declared" ] && [ -f "$declared/oh-my-zsh.sh" ]; then
        printf '%s' "$declared"
        return 0
    fi

    return 1
}

# ------ 安装 Oh My Zsh ------
install_omz() {
    if OMZ_ROOT="$(resolve_omz_root)"; then
        success "检测到 Oh My Zsh: $OMZ_ROOT"
        if [ "$OMZ_ROOT" != "$HOME/.oh-my-zsh" ]; then
            info "这是系统级安装，主题和插件将装到 $OMZ_CUSTOM（无需 sudo）"
        fi
    else
        info "正在安装 Oh My Zsh..."
        # ~/.oh-my-zsh 可能是个残缺空壳（如 .zshrc 里的 ZSH_CACHE_DIR 造出来的
        # cache/ 目录），官方安装器遇到已存在的目录会直接退出，先挪开。
        if [ -d "$HOME/.oh-my-zsh" ]; then
            local STALE="$HOME/.oh-my-zsh.incomplete.$(date +%Y%m%d%H%M%S)"
            warn "~/.oh-my-zsh 已存在但缺少 oh-my-zsh.sh，移至 $STALE"
            mv "$HOME/.oh-my-zsh" "$STALE"
        fi
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        OMZ_ROOT="$HOME/.oh-my-zsh"
        success "Oh My Zsh 安装完成 → $OMZ_ROOT"
    fi
}

# ------ 安装主题 ------
install_themes() {
    local CUSTOM_THEMES="$OMZ_CUSTOM/themes"
    mkdir -p "$CUSTOM_THEMES"

    info "安装主题: half-lifeclean..."
    cp "$SCRIPT_DIR/themes/half-lifeclean.zsh-theme" "$CUSTOM_THEMES/"
    success "half-lifeclean → $CUSTOM_THEMES/"

    info "安装主题: lambda-gitster..."
    cp "$SCRIPT_DIR/themes/lambda-gitster.zsh-theme" "$CUSTOM_THEMES/"
    success "lambda-gitster → $CUSTOM_THEMES/"
}

# ------ 安装插件 ------
install_plugins() {
    local CUSTOM_PLUGINS="$OMZ_CUSTOM/plugins"
    mkdir -p "$CUSTOM_PLUGINS"

    # zsh-autosuggestions
    if [ -d "$CUSTOM_PLUGINS/zsh-autosuggestions" ]; then
        warn "zsh-autosuggestions 已存在，正在更新..."
        git -C "$CUSTOM_PLUGINS/zsh-autosuggestions" pull --quiet
    else
        info "克隆 zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions.git \
            "$CUSTOM_PLUGINS/zsh-autosuggestions"
    fi
    success "zsh-autosuggestions 就绪"

    # zsh-syntax-highlighting
    if [ -d "$CUSTOM_PLUGINS/zsh-syntax-highlighting" ]; then
        warn "zsh-syntax-highlighting 已存在，正在更新..."
        git -C "$CUSTOM_PLUGINS/zsh-syntax-highlighting" pull --quiet
    else
        info "克隆 zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "$CUSTOM_PLUGINS/zsh-syntax-highlighting"
    fi
    success "zsh-syntax-highlighting 就绪"
}

# ------ 配置 .zshrc ------
configure_zshrc() {
    local ZSHRC="$HOME/.zshrc"
    local BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    local TEMP_ZSHRC
    local HAS_ZSH_HOME=0

    if [ -f "$ZSHRC" ]; then
        cp "$ZSHRC" "$BACKUP"
        success "已备份原 .zshrc → $BACKUP"
    else
        touch "$ZSHRC"
    fi

    info "正在配置 .zshrc..."

    if grep -Eq '^[[:space:]]*(export[[:space:]]+)?ZSH=' "$ZSHRC"; then
        HAS_ZSH_HOME=1
    fi

    TEMP_ZSHRC="$(mktemp "${ZSHRC}.tmp.XXXXXX")"

    # 移除旧的主题和插件配置，然后在 Oh My Zsh 加载前重新插入。
    # 这样可以同时修复缺少 source、配置顺序错误和重复运行。
    awk -v has_zsh_home="$HAS_ZSH_HOME" '
        function print_omz_config() {
            if (!has_zsh_home) {
                print "export ZSH=\"$HOME/.oh-my-zsh\""
            }
            # 必须显式指定：系统级安装下 $ZSH/custom 归 root，主题插件不在那儿
            print "ZSH_CUSTOM=\"$HOME/.oh-my-zsh/custom\""
            print "ZSH_THEME=\"half-lifeclean\""
            print ""
            print "plugins=("
            print "  git"
            print "  zsh-autosuggestions"
            print "  zsh-syntax-highlighting"
            print ")"
            print ""
        }

        in_plugins {
            if ($0 ~ /^[[:space:]]*\)[[:space:]]*(#.*)?$/) {
                in_plugins = 0
                skip_config_blank = 1
            }
            next
        }

        /^[[:space:]]*ZSH_THEME=/ {
            skip_config_blank = 1
            next
        }

        /^[[:space:]]*(export[[:space:]]+)?ZSH_CUSTOM=/ {
            skip_config_blank = 1
            next
        }

        /^[[:space:]]*plugins=\(/ {
            if ($0 !~ /\)[[:space:]]*(#.*)?$/) {
                in_plugins = 1
            }
            skip_config_blank = 1
            next
        }

        skip_config_blank && /^[[:space:]]*$/ {
            next
        }

        /^[[:space:]]*(source|\.)[[:space:]]+.*oh-my-zsh\.sh/ {
            if (!omz_loaded) {
                print_omz_config()
                print
                omz_loaded = 1
            }
            next
        }

        {
            skip_config_blank = 0
            print
        }

        END {
            if (!omz_loaded) {
                if (NR > 0) {
                    print ""
                }
                print_omz_config()
                print "source \"$ZSH/oh-my-zsh.sh\""
            }
        }
    ' "$ZSHRC" > "$TEMP_ZSHRC"

    cat "$TEMP_ZSHRC" > "$ZSHRC"
    rm -f "$TEMP_ZSHRC"

    success "主题、插件与 Oh My Zsh 加载顺序已更新"
}

# ------ 主流程 ------
main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Oh My Zsh 主题 & 插件 迁移安装工具       ║${NC}"
    echo -e "${CYAN}║  支持 macOS 与 Linux                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""

    check_prerequisites
    echo ""
    install_omz
    echo ""
    install_themes
    echo ""
    install_plugins
    echo ""
    configure_zshrc

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  全部安装完成!                             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "主题: ${CYAN}half-lifeclean${NC} (备用: lambda-gitster)"
    echo -e "插件: ${CYAN}git${NC}, ${CYAN}zsh-autosuggestions${NC}, ${CYAN}zsh-syntax-highlighting${NC}"
    echo ""
    echo -e "${YELLOW}请执行以下命令使配置生效:${NC}"
    echo -e "  ${GREEN}exec zsh -l${NC}"
    echo -e "  或重新打开终端"
    echo ""

    # 切换主题的小提示
    echo -e "${CYAN}[提示]${NC} 如果想换成 lambda-gitster 主题:"
    echo -e "  编辑 ~/.zshrc，将 ZSH_THEME=\"half-lifeclean\" 改为 ZSH_THEME=\"lambda-gitster\""
    echo ""
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
