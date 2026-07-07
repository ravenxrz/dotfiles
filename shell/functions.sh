path_remove() {
    local remove="$1"
    local new_path="" path_entry old_ifs="$IFS"

    if [ -n "${ZSH_VERSION:-}" ]; then
        local -a new_path_entries
        new_path_entries=()
        for path_entry in "${path[@]}"; do
            [[ "$path_entry" == "$remove" ]] && continue
            new_path_entries+=("$path_entry")
        done
        path=("${new_path_entries[@]}")
        return
    fi

    IFS=:
    for path_entry in $PATH; do
        [[ "$path_entry" == "$remove" ]] && continue
        new_path="${new_path:+$new_path:}$path_entry"
    done
    IFS="$old_ifs"
    PATH="$new_path"
}

path_append() {
    path_remove "$1"
    PATH="${PATH:+"$PATH:"}$1"
}

path_prepend() {
    path_remove "$1"
    PATH="$1${PATH:+":$PATH"}"
}

here() {
    local loc
    if [ "$#" -eq 1 ]; then
        loc=$(realpath "$1")
    else
        loc=$(realpath ".")
    fi
    ln -sfn "${loc}" "$HOME/.shell.here"
    echo "here -> $(readlink $HOME/.shell.here)"
}

there="$HOME/.shell.here"

there() {
    cd "$(readlink "${there}")"
}
