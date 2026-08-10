function up -d "Go up [n] directories"
    set -l cdir (pwd)
    if test -z "$argv[1]"
        set cdir (dirname "$cdir")
    else if not string match -qr '^[0-9]+$' -- $argv[1]
        echo "Error: argument must be a number"
        return 1
    else if test $argv[1] -le 0
        echo "Error: argument must be positive"
        return 1
    else
        for i in (seq 1 $argv[1])
            set -l ncdir (dirname "$cdir")
            if test "$cdir" = "$ncdir"
                break
            else
                set cdir "$ncdir"
            end
        end
    end
    cd "$cdir"
end
