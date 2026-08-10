# PATH setup — fish mirror of shell/bootstrap.sh (and PATH bits of zshrc).
# conf.d files load for login, interactive and non-interactive sessions, which
# makes this the right place to build $PATH.
#
# fish_add_path prepends (default) and de-duplicates, so re-sourcing is safe.
# It is only available in newer fish releases; keep a small fallback for older
# host installs such as fish 3.0.x.
function __dotfiles_fish_add_path --description 'fish_add_path fallback for old fish'
    if type -q fish_add_path
        fish_add_path $argv
        return
    end

    set -l __new_paths
    for __path in $argv
        if test -d "$__path"; and not contains -- "$__path" $__new_paths; and not contains -- "$__path" $fish_user_paths
            set __new_paths $__new_paths "$__path"
        end
    end

    if test (count $__new_paths) -gt 0
        set -gx fish_user_paths $__new_paths $fish_user_paths
    end
end

# Homebrew (arm64) first, so brew-installed tools win over system ones.
if test -x /opt/homebrew/bin/brew
    __dotfiles_fish_add_path /opt/homebrew/bin /opt/homebrew/sbin
end

# dotfiles bin dirs (bootstrap.sh)
__dotfiles_fish_add_path "$HOME/.dotfiles/bin/common"
if test (uname) = Darwin
    __dotfiles_fish_add_path "$HOME/.dotfiles/bin/macos"
else
    __dotfiles_fish_add_path "$HOME/.dotfiles/bin/linux"
    __dotfiles_fish_add_path "$HOME/.dotfiles/bin/linux/bin"
end

__dotfiles_fish_add_path "$HOME/.dotfiles/remote_dev"
__dotfiles_fish_add_path "$HOME/.dotfiles/dockerfile"

# User-local tool dirs (zshrc tail)
__dotfiles_fish_add_path "$HOME/.local/bin"
__dotfiles_fish_add_path "$HOME/.npm-global/bin"
__dotfiles_fish_add_path "$HOME/.cargo/bin"

functions -e __dotfiles_fish_add_path

# set term color (bootstrap.sh)
set -gx TERM xterm-256color
