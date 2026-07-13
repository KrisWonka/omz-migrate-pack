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
    assert_count 1 '^plugins=\($' "$HOME/.zshrc"
    assert_count 1 '^[[:space:]]*(source|\.)[[:space:]]+.*oh-my-zsh\.sh' "$HOME/.zshrc"
    assert_config_order "$HOME/.zshrc"
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
    assert_count 1 '^ZSH_THEME="half-lifeclean"$' "$HOME/.zshrc"
    assert_count 1 '^plugins=\($' "$HOME/.zshrc"
    assert_count 1 '^source "\$ZSH/oh-my-zsh.sh"$' "$HOME/.zshrc"
    assert_config_order "$HOME/.zshrc"
    grep -q "alias keep-this='printf kept'" "$HOME/.zshrc" || fail "unrelated zshrc content was removed"
}

test_existing_source_and_idempotence
test_missing_omz_loader

echo "PASS: install configuration tests"
