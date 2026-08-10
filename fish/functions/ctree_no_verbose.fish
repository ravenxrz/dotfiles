function ctree_no_verbose -d "calltree.pl wrapper (non-verbose)"
    # usage: calltree.pl 'start_pattern' 'end_pattern' mode verbose depth path
    if test (count $argv) -eq 3
        eval "calltree.pl '$argv[1]' '' $argv[2] 0 $argv[3]"
        return
    end
    if test (count $argv) -eq 4
        eval "calltree.pl '$argv[1]' '' $argv[2] 0 $argv[3] $argv[4]"
        return
    end
    # print usage
    calltree.pl
end
