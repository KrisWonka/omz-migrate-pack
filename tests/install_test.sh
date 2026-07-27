#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"

trap 'rm -rf "$TEST_ROOT"' EXIT

# shellcheck source=../install.sh
source "$PROJECT_ROOT/install.sh"

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

assert_count() {
    local expected="$1"
    local pattern="$2"
    local file="$3"
    local actual

    actual="$(grep -Ec "$pattern" "$file" || true)"
    [[ "$actual" == "$expected" ]] || fail "expected $expected match(es) for $pattern, got $actual"
}

assert_config_order() {
    local file="$1"
    local theme_line
    local plugins_line
    local source_line

    theme_line="$(grep -n '^ZSH_THEME=' "$file" | cut -d: -f1)"
    plugins_line="$(grep -n '^plugins=(' "$file" | cut -d: -f1)"
    source_line="$(grep -nE '^[[:space:]]*(source|\.)[[:space:]]+.*oh-my-zsh\.sh' "$file" | cut -d: -f1)"

    (( theme_line < source_line )) || fail "theme must be set before Oh My Zsh is loaded"
    (( plugins_line < source_line )) || fail "plugins must be set before Oh My Zsh is loaded"
}

assert_custom_before_source() {
    local file="$1"
    local custom_line
    local source_line

    custom_line="$(grep -n '^ZSH_CUSTOM=' "$file" | cut -d: -f1)"
    source_line="$(grep -nE '^[[:space:]]*(source|\.)[[:space:]]+.*oh-my-zsh\.sh' "$file" | cut -d: -f1)"

    [[ -n "$custom_line" ]] || fail "ZSH_CUSTOM was never written"
    (( custom_line < source_line )) || fail "ZSH_CUSTOM must be set before Oh My Zsh is loaded"
}

test_existing_source_and_idempotence() {
    export HOME="$TEST_ROOT/existing"
    mkdir -p "$HOME"

    cat > "$HOME/.zshrc" <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
source "$ZSH/oh-my-zsh.sh"
alias keep-me='printf kept'
ZSH_THEME="old-theme"
plugins=(docker)
EOF

    configure_zshrc >/dev/null

    assert_count 1 '^ZSH_THEME="half-lifeclean"$' "$HOME/.zshrc"
    assert_count 1 '^ZSH_CUSTOM="\$HOME/.oh-my-zsh/custom"$' "$HOME/.zshrc"
    assert_count 1 '^plugins=\($' "$HOME/.zshrc"
    assert_count 1 '^[[:space:]]*(source|\.)[[:space:]]+.*oh-my-zsh\.sh' "$HOME/.zshrc"
    assert_config_order "$HOME/.zshrc"
    assert_custom_before_source "$HOME/.zshrc"
    grep -q "alias keep-me='printf kept'" "$HOME/.zshrc" || fail "unrelated zshrc content was removed"

    cp "$HOME/.zshrc" "$HOME/first-run.zshrc"
    configure_zshrc >/dev/null
    cmp -s "$HOME/first-run.zshrc" "$HOME/.zshrc" || fail "second run changed zshrc"
}

test_missing_omz_loader() {
    export HOME="$TEST_ROOT/missing-loader"
    mkdir -p "$HOME"

    cat > "$HOME/.zshrc" <<'EOF'
alias keep-this='printf kept'
EOF

    configure_zshrc >/dev/null

    assert_count 1 '^export ZSH="\$HOME/.oh-my-zsh"$' "$HOME/.zshrc"
    assert_count 1 '^ZSH_CUSTOM="\$HOME/.oh-my-zsh/custom"$' "$HOME/.zshrc"
    assert_count 1 '^ZSH_THEME="half-lifeclean"$' "$HOME/.zshrc"
    assert_count 1 '^plugins=\($' "$HOME/.zshrc"
    assert_count 1 '^source "\$ZSH/oh-my-zsh.sh"$' "$HOME/.zshrc"
    assert_config_order "$HOME/.zshrc"
    assert_custom_before_source "$HOME/.zshrc"
    grep -q "alias keep-this='printf kept'" "$HOME/.zshrc" || fail "unrelated zshrc content was removed"
}

# Armbian / Orange Pi 等发行版把 Oh My Zsh 装在系统级 /etc/oh-my-zsh，
# 其 custom 目录归 root 所有，装不进去。此时必须显式把 ZSH_CUSTOM 指向
# 用户家目录，否则 Oh My Zsh 会去 $ZSH/custom 找主题和插件从而报 not found。
test_system_wide_omz_uses_user_custom() {
    export HOME="$TEST_ROOT/system-wide"
    mkdir -p "$HOME"

    cat > "$HOME/.zshrc" <<'EOF'
export ZSH=/etc/oh-my-zsh
export ZSH_CACHE_DIR=~/.oh-my-zsh/cache
ZSH_THEME="half-lifeclean"
plugins=(git)
source $ZSH/oh-my-zsh.sh
EOF

    configure_zshrc >/dev/null

    assert_count 1 '^export ZSH=/etc/oh-my-zsh$' "$HOME/.zshrc"
    assert_count 0 '^export ZSH="\$HOME/.oh-my-zsh"$' "$HOME/.zshrc"
    assert_count 1 '^ZSH_CUSTOM="\$HOME/.oh-my-zsh/custom"$' "$HOME/.zshrc"
    assert_count 1 '^export ZSH_CACHE_DIR=~/.oh-my-zsh/cache$' "$HOME/.zshrc"
    assert_custom_before_source "$HOME/.zshrc"

    cp "$HOME/.zshrc" "$HOME/first-run.zshrc"
    configure_zshrc >/dev/null
    cmp -s "$HOME/first-run.zshrc" "$HOME/.zshrc" || fail "second run changed zshrc"
}

# 主体目录的探测必须看 oh-my-zsh.sh 是否存在，而不是目录是否存在。
# Armbian 的 .zshrc 设了 ZSH_CACHE_DIR=~/.oh-my-zsh/cache，运行时会
# 凭空造出一个只含 cache/ 的 ~/.oh-my-zsh，骗过单纯的 [ -d ] 判断。
test_resolve_omz_root() {
    export HOME="$TEST_ROOT/resolve"
    mkdir -p "$HOME/.oh-my-zsh/cache"

    cat > "$HOME/.zshrc" <<'EOF'
export ZSH=/etc/oh-my-zsh
EOF

    local fake_system="$TEST_ROOT/resolve-etc"
    mkdir -p "$fake_system"
    touch "$fake_system/oh-my-zsh.sh"

    resolve_omz_root >/dev/null 2>&1 && fail "空壳 ~/.oh-my-zsh 不应被当成已安装"

    printf 'export ZSH=%s\n' "$fake_system" > "$HOME/.zshrc"
    [[ "$(resolve_omz_root)" == "$fake_system" ]] \
        || fail "应识别 .zshrc 中声明的系统级 Oh My Zsh"

    touch "$HOME/.oh-my-zsh/oh-my-zsh.sh"
    [[ "$(resolve_omz_root)" == "$HOME/.oh-my-zsh" ]] \
        || fail "用户级安装应优先于系统级"
}

test_existing_source_and_idempotence
test_missing_omz_loader
test_system_wide_omz_uses_user_custom
test_resolve_omz_root

echo "PASS: install configuration tests"
