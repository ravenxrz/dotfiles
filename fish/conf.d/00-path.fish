# PATH setup — fish mirror of shell/bootstrap.sh (and PATH bits of zshrc).
# conf.d files load for login, interactive and non-interactive sessions, which
# makes this the right place to build $PATH.
#
# fish_add_path prepends (default) and de-duplicates, so re-sourcing is safe.

# Homebrew (arm64) first, so brew-installed tools win over system ones.
if test -x /opt/homebrew/bin/brew
    fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
end

# dotfiles bin dirs (bootstrap.sh)
fish_add_path "$HOME/.dotfiles/bin/common"
if test (uname) = Darwin
    fish_add_path "$HOME/.dotfiles/bin/macos"
else
    fish_add_path "$HOME/.dotfiles/bin/linux"
    fish_add_path "$HOME/.dotfiles/bin/linux/bin"
end

fish_add_path "$HOME/.dotfiles/remote_dev"
fish_add_path "$HOME/.dotfiles/dockerfile"

# User-local tool dirs (zshrc tail)
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.npm-global/bin"
fish_add_path "$HOME/.cargo/bin"

# set term color (bootstrap.sh)
set -gx TERM xterm-256color
