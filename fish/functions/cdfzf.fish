function cdfzf -d "Pick a path with fzf and cd to it (or its parent dir)"
    set -l file (fzf)
    if test -z "$file"
        return
    end
    if test -d "$file"
        cd "$file"
    else
        cd (dirname "$file")
    end
end
