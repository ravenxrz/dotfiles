function fish_prompt --description 'ys-like prompt, ported from the oh-my-zsh ys theme'
    # Capture exit status of the last command before anything clobbers it.
    set -l last_status $status

    # user segment: highlight root like ys does, otherwise cyan.
    set -l user_seg
    if test (id -u) -eq 0
        set user_seg (set_color -b yellow black)$USER(set_color normal)
    else
        set user_seg (set_color cyan)$USER(set_color normal)
    end

    # absolute cwd (no home abbreviation)
    set -l cwd $PWD

    # git branch only — no dirty check, to match `oh-my-zsh.hide-dirty = 1`
    # and keep the prompt fast in large repos.
    set -l git_seg
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
    if test -n "$branch"
        set git_seg ' '(set_color normal)'on'(set_color blue)' git:'(set_color cyan)$branch(set_color normal)
    end

    # exit code, shown only when the last command failed (ys style)
    set -l exit_seg
    if test $last_status -ne 0
        set exit_seg ' C:'(set_color red)$last_status(set_color normal)
    end

    # Blank line above the prompt, like ys.
    echo ''
    echo -n -s \
        (set_color -o blue) '#' (set_color normal) ' ' \
        $user_seg ' ' \
        (set_color normal) '@ ' \
        (set_color green) (prompt_hostname) ' ' \
        (set_color normal) 'in ' \
        (set_color -o yellow) $cwd (set_color normal) \
        $git_seg \
        ' ' (set_color magenta) (uname -s) (set_color normal) \
        ' [' (date +%H:%M:%S) ']' \
        $exit_seg
    echo ''
    echo -n -s (set_color -o red) '$ ' (set_color normal)
end
