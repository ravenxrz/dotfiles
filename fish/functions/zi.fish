function zi -d "Interactively jump to a directory with zoxide"
    if not type -q zoxide
        echo "zi: zoxide not found"
        return 127
    end

    set -l result (command zoxide query --interactive -- $argv)
    and cd "$result"

    set -l cd_status $status
    if test $cd_status -eq 0
        command zoxide add -- (pwd) >/dev/null 2>&1
    end
    return $cd_status
end
