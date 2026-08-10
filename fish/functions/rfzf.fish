function rfzf -d "Pick a file with fzf and run it if executable"
    set -l file (fzf)
    if test -z "$file"
        return
    end
    if test -x "$file"
        ./$file
        realpath $file
    else
        echo "$file is not executable file"
    end
end
