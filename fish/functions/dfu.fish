function dfu -d "Update dotfiles"
    pushd ~/.dotfiles
    and git pull --ff-only
    and ./install -q
    popd
end
