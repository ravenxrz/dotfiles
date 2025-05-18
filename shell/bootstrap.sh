# intall pyenv by 'curl -L https://pyenv.run | bash'
path_prepend "$HOME/.local/bin:$HOME/.pyenv/bin"
# init pyenv
if which pyenv > /dev/null 2>&1; then
  eval "$(pyenv init -)" > /dev/null 2>&1
fi

path_prepend "$HOME/.dotfiles/bin/common"
if [[ $OSTYPE == 'darwin'* ]]; then
  path_prepend "$HOME/.dotfiles/bin/macos"
else
  path_prepend "$HOME/.dotfiles/bin/linux/"
fi

path_prepend "$HOME/.dotfiles/remote_dev/"
path_prepend "$HOME/.dotfiles/dockerfile/"

# set zsh term color
export TERM=xterm-256color

