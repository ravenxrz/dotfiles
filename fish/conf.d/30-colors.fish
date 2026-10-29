# Fish syntax-highlight colors tuned for the iTerm2 One Light profile.
#
# Keep this repo-managed instead of relying on fish universal variables in
# fish_variables. Explicit true-color values avoid low-contrast ANSI bright
# colors on a light background and shadow stale universal variables without
# mutating host-local state.
if status is-interactive
    set -g fish_color_normal normal
    set -g fish_color_command 305fbd --bold
    set -g fish_color_param normal
    set -g fish_color_quote 3a7638
    set -g fish_color_redirection 8a6100
    set -g fish_color_operator 8a6100
    set -g fish_color_end 305fbd
    set -g fish_color_escape 962694
    set -g fish_color_error c4313d --bold
    set -g fish_color_autosuggestion 6b6f78
    set -g fish_color_comment 6b6f78
    set -g fish_color_valid_path --underline

    set -g fish_color_selection 2a2c33 --bold --background=cfe8ff
    set -g fish_color_search_match 2a2c33 --background=f2df9b
    set -g fish_color_match --background=d9e5ff

    set -g fish_pager_color_prefix 08799e --bold --underline
    set -g fish_pager_color_completion normal
    set -g fish_pager_color_description 6b6f78
    set -g fish_pager_color_selected_background --background=e5e7eb
end
