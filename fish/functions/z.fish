function z -d "Jump to a directory with zoxide"
    set -l argc (count $argv)

    if test $argc -eq 0
        cd "$HOME"
    else if test $argc -eq 1; and test "$argv[1]" = "-"
        cd -
    else if test $argc -eq 1; and test -d "$argv[1]"
        cd "$argv[1]"
    else if test $argc -eq 2; and test "$argv[1]" = "--"
        cd -- "$argv[2]"
    else
        if not type -q zoxide
            echo "z: zoxide not found"
            return 127
        end

        set -l result (command zoxide query --exclude (pwd) -- $argv)
        and cd "$result"
    end

    set -l cd_status $status
    if test $cd_status -eq 0; and type -q zoxide
        command zoxide add -- (pwd) >/dev/null 2>&1
    end
    return $cd_status
end
