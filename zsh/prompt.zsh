# display full path except ~
export AGKOZAK_PROMPT_DIRTRIM=0
# display command execution time if cost is larger than 1s
export AGKOZAK_CMD_EXEC_TIME=1

# prompt
# The left prompt
# Exit status
AGKOZAK_CUSTOM_PROMPT='%(?..%B%F{red}(%?%)%f%b )'
AGKOZAK_CUSTOM_PROMPT+='%B%F{yellow}[%*] '
# Command execution time
AGKOZAK_CUSTOM_PROMPT+='%(9V.%9v .)'
# Username and hostname
AGKOZAK_CUSTOM_PROMPT+='%(!.%S%B.%B%F{green})%n%1v%(!.%b%s.%f%b) '
# Path
AGKOZAK_CUSTOM_PROMPT+=$'%B%F{blue}%2v%f%b'
# Virtual environment
AGKOZAK_CUSTOM_PROMPT+='%(10V. %F{green}[%10v]%f.)'
# Background jobs indicator and newline
AGKOZAK_CUSTOM_PROMPT+=$'%(1j. %F{magenta}%jj%f.)\n'
# Prompt character
AGKOZAK_CUSTOM_PROMPT+='%(4V.:.%#) '

# The right prompt
# Git status
AGKOZAK_CUSTOM_RPROMPT='%(3V.%F{yellow}%3v%f.)'

source ~/.zsh/plugins/agkozak-zsh-prompt/agkozak-zsh-prompt.plugin.zsh
