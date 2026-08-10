function cdd -d "cd into a dir, or the parent dir if given a file"
    set -l dir $argv[1]
    if test -z "$dir"
        return
    end
    if test -d "$dir"
        cd "$dir"
        return
    end
    cd (dirname "$dir")
end
