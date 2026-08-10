function there -d "cd to the directory remembered by `here`"
    cd (readlink "$HOME/.shell.here")
end
