# Force the current shell session onto arm64 — fish mirror of the Darwin guard
# in zshrc. If we're an x86_64 process running under Rosetta translation,
# re-exec fish natively so everything defaults to arm64.
if test (uname) = Darwin
    if test (uname -m) = x86_64; and test (sysctl -n sysctl.proc_translated 2>/dev/null) = 1
        exec arch -arm64 fish
    end
end
