# fish interactive configuration.
#
# Base config (PATH, env vars, arm64 guard) lives in conf.d/ so it applies to
# every session. This file only holds interactive-only bits: key bindings,
# jump tool, and aliases.
#
# The POSIX shell equivalents live in shell/*.sh (used by bash/zsh); fish can't
# source those directly, so this is the native mirror. Keep them in sync.

if status is-interactive
    # vi mode (mirror of the zsh vi-mode plugin)
    fish_vi_key_bindings

    # fzf key bindings: Ctrl-T (files), Ctrl-R (history), Alt-C (cd).
    # fish integration ships with the fzf brew formula.
    for __fzf_dir in (brew --prefix fzf 2>/dev/null)/shell /usr/local/opt/fzf/shell /opt/homebrew/opt/fzf/shell
        if test -f "$__fzf_dir/key-bindings.fish"
            source "$__fzf_dir/key-bindings.fish"
            fzf_key_bindings
            break
        end
    end
    set -e __fzf_dir

    # zoxide: `z`/`zi` smart directory jumping (replaces the zsh z plugin).
    # History was imported from ~/.z via `zoxide import --from=z ~/.z`.
    if type -q zoxide
        zoxide init fish | source
    end

    # ---- aliases (mirror of shell/aliases.sh) ----

    # colored ls
    if test (uname) = Darwin
        alias ls='ls -FG'
    else
        alias ls='ls --color=auto -F'
    end
    alias grep='grep --color'

    # ls aliases
    alias ll='ls -lah'
    alias la='ls -A'
    alias l='ls'

    # protect against overwriting
    alias cp='cp -i'
    alias mv='mv -i'

    # git
    alias gag='git exec ag'

    # g++
    alias 'g++'='g++ -std=c++11'

    # misc
    alias mirrorsite='wget -m -k -K -E -e robots=off'
    alias clc='clear'
    alias dockerx86='DOCKER_DEFAULT_PLATFORM=linux/amd64 docker'
    alias lazygit='lazygit -ucd ~/.config/lazygit/'
    alias rgn='rg --no-ignore --no-config'
    alias cpptree='cpptree.pl'
    alias nv='/Users/leo/.local/share/bob/v0.12.3/nvim-macos-arm64/bin/nvim'

    # switch architecture (fish counterparts of armzsh/x86zsh)
    alias armfish='arch -arm64 fish'
    alias x86fish='arch -x86_64 fish'
end
