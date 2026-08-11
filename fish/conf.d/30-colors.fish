# Brighter fish syntax-highlight colors for typed commands.
#
# Keep this repo-managed instead of relying on fish universal variables in
# fish_variables. These globals shadow stale/dim universal colors for the
# current session without mutating host-local state.
if status is-interactive
    set -g fish_color_normal normal
    set -g fish_color_command brcyan --bold
    set -g fish_color_param brwhite
    set -g fish_color_quote brgreen
    set -g fish_color_redirection bryellow
    set -g fish_color_operator bryellow
    set -g fish_color_end brcyan
    set -g fish_color_escape brmagenta
    set -g fish_color_error brred --bold
    set -g fish_color_autosuggestion 8a8a8a
    set -g fish_color_comment brblack
    set -g fish_color_valid_path --underline

    set -g fish_color_selection black --bold --background=brcyan
    set -g fish_color_search_match black --background=bryellow
    set -g fish_color_match --background=brblue

    set -g fish_pager_color_prefix brcyan --bold --underline
    set -g fish_pager_color_completion brwhite
    set -g fish_pager_color_description bryellow
    set -g fish_pager_color_selected_background --background=brblack
end
