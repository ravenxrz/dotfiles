function xin -d "Execute a command in a specific directory"
    pushd $argv[1]
    and command $argv[2..-1]
    popd
end
