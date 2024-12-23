# Use colors in coreutils utilities output
if ls --help 2>&1 | grep -q -- --color; then
  alias ls='ls --color=auto -F'
else
  alias ls='ls -FG'
fi
alias grep='grep --color'

# ls aliases
alias ll='ls -lah'
alias la='ls -A'
alias l='ls'

# Aliases to protect against overwriting
alias cp='cp -i'
alias mv='mv -i'

# git related aliases
alias gag='git exec ag'

# g++ aliases
alias g++='g++ -std=c++11'

# Update dotfiles
dfu() {
  (
    cd ~/.dotfiles && git pull --ff-only && ./install -q
  )
}

# Use pip without requiring virtualenv
syspip() {
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}

syspip2() {
  PIP_REQUIRE_VIRTUALENV="" pip2 "$@"
}

syspip3() {
  PIP_REQUIRE_VIRTUALENV="" pip3 "$@"
}

# cd to git root directory
alias cdgr='cd "$(git root)"'

# Create a directory and cd into it
mcd() {
  mkdir "${1}" && cd "${1}"
}

# Go up [n] directories
up() {
  local cdir="$(pwd)"
  if [[ "${1}" == "" ]]; then
    cdir="$(dirname "${cdir}")"
  elif ! [[ "${1}" =~ ^[0-9]+$ ]]; then
    echo "Error: argument must be a number"
  elif ! [[ "${1}" -gt "0" ]]; then
    echo "Error: argument must be positive"
  else
    for ((i = 0; i < ${1}; i++)); do
      local ncdir="$(dirname "${cdir}")"
      if [[ "${cdir}" == "${ncdir}" ]]; then
        break
      else
        cdir="${ncdir}"
      fi
    done
  fi
  cd "${cdir}"
}

# Execute a command in a specific directory
xin() {
  (
    cd "${1}" && shift && "${@}"
  )
}

# Check if a file contains non-ascii characters
nonascii() {
  LC_ALL=C grep -n '[^[:print:][:space:]]' "${1}"
}

# Fetch pull request

fpr() {
  if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: fpr must be executed from within a git repository"
    return 1
  fi
  (
    cdgr
    if [ "$#" -eq 1 ]; then
      local repo="${PWD##*/}"
      local user="${1%%:*}"
      local branch="${1#*:}"
    elif [ "$#" -eq 2 ]; then
      local repo="${PWD##*/}"
      local user="${1}"
      local branch="${2}"
    elif [ "$#" -eq 3 ]; then
      local repo="${1}"
      local user="${2}"
      local branch="${3}"
    else
      echo "Usage: fpr [repo] username branch"
      return 1
    fi

    git fetch "git@github.com:${user}/${repo}" "${branch}:${user}/${branch}"
  )
}

# Serve current directory

serve() {
  python3 -m http.server 8000
}

# Mirror a website
alias mirrorsite='wget -m -k -K -E -e robots=off'

# Mirror stdout to stderr, useful for seeing data going through a pipe
alias peek='tee >(cat 1>&2)'

# clean window output
alias clc="clear"

# docker x86 on mac
alias dockerx86="DOCKER_DEFAULT_PLATFORM=linux/amd64 docker"

# lazygit
alias lazygit="lazygit -ucd ~/.config/lazygit/"

# ripgrep without ignore
alias rgn="rg --no-ignore"

# alias ctree="calltree.pl"

alias cpptree="cpptree.pl"

ctree() {
  # usage: calltree.pl 'start_pattern' 'end_pattern' mode verbose depeth
  echo $#
  if [ $# -eq 3 ]; then
    cmd="calltree.pl $1 '' $2 1 $3"
    echo "cmd:$cmd"
    eval $cmd
    return
  fi
  if [ $# -eq 4 ]; then
    cmd="calltree.pl $1 '' $2 1 $3 $4"
    echo "cmd:$cmd"
    eval $cmd
    return
  fi
  # print usage
  calltree.pl
  return
}

# run file with fzf
rfzf() {
  file=$(fzf)
  if [ -z "${file}" ]; then
    return
  fi
  if [ -x "${file}" ]; then
    ./${file}
    echo $(realpath ${file})
  else
    echo "${file} is not executable file"
  fi
}

# cd to the file parent dir or dir itself
cdfzf() {
  file=$(fzf)
  if [ -z "${file}" ]; then
    return
  fi
  if [ -d "${file}" ]; then
    cd ${file}
  else
    cd $(dirname ${file})
  fi
}

myssh() {
  /usr/bin/kinit -kt ~/.ssh/keytab zhangxingrui.leo@BYTEDANCE.COM
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $@
}

nkinit() {
  bash /data00/home/zhangxingrui/Projects/my_tools/pipeline-build/common/kinit.sh
  # /usr/bin/kinit -kt ~/.ssh/keytab zhangxingrui.leo@BYTEDANCE.COM
}

zkinit() {
  /usr/bin/kinit -kt ~/.ssh/keytab zhangxingrui.leo@BYTEDANCE.COM
}

#  windows exec aliases
# https://stackoverflow.com/questions/7131670/make-a-bash-alias-that-takes-a-parameter
# NOTE: bash function can be called from shell command
# chrome() {
#   chrome.exe file://wsl.localhost/Ubuntu-20.04`pwd`/$1
# }

# alias opencwd="explorer.exe ."
# alias img="Honeyview.exe"
# alias typora="Typora.exe"
# alias vim="lvim"
