#!/bin/bash
# ============================================================
#  Oh My Zsh 主题 & 插件 一键迁移安装脚本
#  源机器: kristin@linux  →  目标机器: macOS
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

info()    { echo -e "${CYAN}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ------ 前置检查 ------
check_prerequisites() {
    info "检查运行环境..."

    if ! command -v git &>/dev/null; then
        error "未检测到 git，请先安装: xcode-select --install"
    fi

    if ! command -v zsh &>/dev/null; then
        error "未检测到 zsh，macOS 应自带 zsh，请检查系统"
    fi

    success "环境检查通过 (git + zsh)"
}

# ------ 安装 Oh My Zsh ------
install_omz() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        success "Oh My Zsh 已安装，跳过"
    else
        info "正在安装 Oh My Zsh..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        success "Oh My Zsh 安装完成"
    fi
}

# ------ 安装主题 ------
install_themes() {
    local ZSH_HOME="$HOME/.oh-my-zsh"
    local CUSTOM_THEMES="$ZSH_HOME/custom/themes"
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
    local CUSTOM_PLUGINS="$HOME/.oh-my-zsh/custom/plugins"
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

    if [ -f "$ZSHRC" ]; then
        cp "$ZSHRC" "$BACKUP"
        success "已备份原 .zshrc → $BACKUP"
    fi

    info "正在配置 .zshrc..."

    # 替换主题
    if grep -q '^ZSH_THEME=' "$ZSHRC" 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="half-lifeclean"/' "$ZSHRC"
        else
            sed -i 's/^ZSH_THEME=.*/ZSH_THEME="half-lifeclean"/' "$ZSHRC"
        fi
        success "主题已设置为 half-lifeclean"
    else
        echo 'ZSH_THEME="half-lifeclean"' >> "$ZSHRC"
        success "主题已追加到 .zshrc"
    fi

    # 替换插件列表
    if grep -q '^plugins=' "$ZSHRC" 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/^plugins=/,/)$/c\
plugins=(git\
\tzsh-autosuggestions\
\tzsh-syntax-highlighting\
)' "$ZSHRC"
        else
            sed -i '/^plugins=/,/)$/c\plugins=(git\n\tzsh-autosuggestions\n\tzsh-syntax-highlighting\n)' "$ZSHRC"
        fi
        success "插件列表已更新"
    else
        cat >> "$ZSHRC" <<'PLUGINS'

plugins=(git
	zsh-autosuggestions
	zsh-syntax-highlighting
)
PLUGINS
        success "插件列表已追加到 .zshrc"
    fi
}

# ------ 主流程 ------
main() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Oh My Zsh 主题 & 插件 迁移安装工具       ║${NC}"
    echo -e "${CYAN}║  从 kristin@linux → macOS                  ║${NC}"
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
    echo -e "  ${GREEN}source ~/.zshrc${NC}"
    echo -e "  或重新打开终端"
    echo ""

    # 切换主题的小提示
    echo -e "${CYAN}[提示]${NC} 如果想换成 lambda-gitster 主题:"
    echo -e "  编辑 ~/.zshrc，将 ZSH_THEME=\"half-lifeclean\" 改为 ZSH_THEME=\"lambda-gitster\""
    echo ""
}

main "$@"
