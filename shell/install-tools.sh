#!/usr/bin/env bash
# Ensure the CLI tools our shells depend on are installed.
# Idempotent: safe to run on every `./install`. When a tool already exists this
# is just a `command -v` check, so it stays cheap.
#
# Currently manages:
#   - zoxide (the `z` smart-jump command used by fish/zsh)

set -e

# ---- zoxide -----------------------------------------------------------------
install_zoxide() {
    echo "==> zoxide not found, installing..."
    if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
        brew install zoxide
    elif command -v cargo >/dev/null 2>&1; then
        cargo install zoxide --locked
    elif command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update && sudo apt-get install -y zoxide
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zoxide
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm zoxide
    else
        echo "!! Could not find a package manager to install zoxide."
        echo "!! Install it manually: https://github.com/ajeetdsouza/zoxide#installation"
        return 1
    fi
}

# One-time migration of the legacy oh-my-zsh `z` database (~/.z) into zoxide,
# only when zoxide's own database is still empty.
import_legacy_z() {
    [ -f "$HOME/.z" ] || return 0
    local count
    count=$(zoxide query -l 2>/dev/null | wc -l | tr -d ' ')
    [ "$count" = "0" ] || return 0

    echo "==> importing legacy ~/.z history into zoxide..."
    # `import` syntax differs across zoxide versions: newer uses --from, older
    # (<=0.10) reads the z datafile from stdin. Try both.
    zoxide import --from z "$HOME/.z" 2>/dev/null \
        || zoxide import z <"$HOME/.z" 2>/dev/null \
        || echo "!! zoxide import skipped (unrecognized version syntax)"
}

if command -v zoxide >/dev/null 2>&1; then
    :
else
    install_zoxide || exit 0
fi

if command -v zoxide >/dev/null 2>&1; then
    import_legacy_z
fi
