function here -d "Remember the current (or given) directory for `there`"
    set -l loc
    if test (count $argv) -eq 1
        set loc (realpath "$argv[1]")
    else
        set loc (realpath .)
    end
    ln -sfn "$loc" "$HOME/.shell.here"
    echo "here -> "(readlink "$HOME/.shell.here")
end
