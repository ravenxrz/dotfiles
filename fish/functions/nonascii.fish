function nonascii -d "Check if a file contains non-ascii characters"
    LC_ALL=C grep -n '[^[:print:][:space:]]' $argv[1]
end
