function ctree -d "calltree.pl wrapper (verbose)"
    # usage: calltree.pl 'start_pattern' 'end_pattern' mode verbose depth path
    if test (count $argv) -eq 3
        set -l cmd "calltree.pl '$argv[1]' '' $argv[2] 1 $argv[3]"
        echo "cmd:$cmd"
        eval $cmd
        return
    end
    if test (count $argv) -eq 4
        set -l cmd "calltree.pl '$argv[1]' '' $argv[2] 1 $argv[3] $argv[4]"
        echo "cmd:$cmd"
        eval $cmd
        return
    end
    # print usage
    calltree.pl
end
