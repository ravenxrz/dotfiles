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

    # Absolute cwd (no home abbreviation). Fish 3.0.x falls back to a bare `>`
    # prompt when a rendered prompt line is too wide. Keep the line unwrapped
    # whenever it fits in the real terminal; only wrap before fish would fall
    # back to `>`.
    set -l cwd $PWD
    set -l columns 120
    if set -q COLUMNS; and test "$COLUMNS" -gt 0 2>/dev/null
        set columns $COLUMNS
    else if type -q stty
        set -l stty_size (stty size 2>/dev/null)
        set -l stty_columns $stty_size[2]
        if test -n "$stty_columns"; and test "$stty_columns" -gt 0 2>/dev/null
            set columns $stty_columns
        end
    end

    # Leave a small margin for fish's renderer and prompt editing area. This is
    # deliberately based on terminal width, not a fixed 100-char cap, so wide
    # terminals keep the full absolute path on one line.
    set -l physical_limit (math "$columns - 4")
    if test $physical_limit -lt 40
        set physical_limit 40
    end

    # git branch only — no dirty check, to match `oh-my-zsh.hide-dirty = 1`
    # and keep the prompt fast in large repos.
    set -l git_seg
    set -l git_seg_unpadded
    set -l git_plain
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
    if test -n "$branch"
        set git_seg ' '(set_color normal)'on'(set_color blue)' git:'(set_color cyan)$branch(set_color normal)
        set git_seg_unpadded (set_color normal)'on'(set_color blue)' git:'(set_color cyan)$branch(set_color normal)
        set git_plain " on git:$branch"
    end

    # exit code, shown only when the last command failed (ys style)
    set -l exit_seg
    set -l exit_plain
    if test $last_status -ne 0
        set exit_seg ' C:'(set_color red)$last_status(set_color normal)
        set exit_plain " C:$last_status"
    end

    set -l os_name (uname -s)
    set -l now (date +%H:%M:%S)
    set -l prompt_host (prompt_hostname)
    set -l prefix_plain "# $USER @ $prompt_host in "
    set -l suffix_plain "$git_plain $os_name [$now]$exit_plain"
    set -l full_line_plain "$prefix_plain$cwd$suffix_plain"

    # Blank line above the prompt, like ys.
    echo ''

    if test (string length -- $full_line_plain) -le $physical_limit
        echo -n -s \
            (set_color -o blue) '#' (set_color normal) ' ' \
            $user_seg ' ' \
            (set_color normal) '@ ' \
            (set_color green) $prompt_host ' ' \
            (set_color normal) 'in ' \
            (set_color -o yellow) $cwd (set_color normal) \
            $git_seg \
            ' ' (set_color magenta) $os_name (set_color normal) \
            ' [' $now ']' \
            $exit_seg
    else
        set -l first_chunk_width (math "$physical_limit - "(string length -- $prefix_plain))
        if test $first_chunk_width -lt 20
            set first_chunk_width 20
        end

        echo -n -s \
            (set_color -o blue) '#' (set_color normal) ' ' \
            $user_seg ' ' \
            (set_color normal) '@ ' \
            (set_color green) $prompt_host ' ' \
            (set_color normal) 'in ' \
            (set_color -o yellow) (string sub -s 1 -l $first_chunk_width -- $cwd) (set_color normal)

        set -l last_path_line_len $first_chunk_width
        set -l cwd_len (string length -- $cwd)
        set -l cwd_offset (math "$first_chunk_width + 1")
        while test $cwd_offset -le $cwd_len
            echo ''
            set -l path_chunk (string sub -s $cwd_offset -l $physical_limit -- $cwd)
            echo -n -s (set_color -o yellow) $path_chunk (set_color normal)
            set last_path_line_len (string length -- $path_chunk)
            set cwd_offset (math "$cwd_offset + $physical_limit")
        end

        set -l suffix_len (string length -- $suffix_plain)
        if test (math "$last_path_line_len + $suffix_len") -le $physical_limit
            echo -n -s \
                $git_seg \
                ' ' (set_color magenta) $os_name (set_color normal) \
                ' [' $now ']' \
                $exit_seg
        else
            echo ''
            if test -n "$branch"
                echo -n -s $git_seg_unpadded ' '
            end
            echo -n -s \
                (set_color magenta) $os_name (set_color normal) \
                ' [' $now ']' \
                $exit_seg
        end
    end

    echo ''
    echo -n -s (set_color -o red) '$ ' (set_color normal)
end
