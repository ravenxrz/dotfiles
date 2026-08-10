function fpr -d "Fetch a GitHub pull request branch"
    if not git rev-parse --git-dir >/dev/null 2>&1
        echo "error: fpr must be executed from within a git repository"
        return 1
    end

    pushd (git root)

    set -l repo (basename $PWD)
    set -l user
    set -l branch

    switch (count $argv)
        case 1
            set user (string split -m1 : -- $argv[1])[1]
            set branch (string replace -r '^[^:]*:' '' -- $argv[1])
        case 2
            set user $argv[1]
            set branch $argv[2]
        case 3
            set repo $argv[1]
            set user $argv[2]
            set branch $argv[3]
        case '*'
            echo "Usage: fpr [repo] username branch"
            popd
            return 1
    end

    git fetch "git@github.com:$user/$repo" "$branch:$user/$branch"
    popd
end
