path_prepend "$HOME/.dotfiles/bin/common"
if [[ $OSTYPE == 'darwin'* ]]; then
  path_prepend "$HOME/.dotfiles/bin/macos"
else
  path_prepend "$HOME/.dotfiles/bin/linux/"
  path_prepend "$HOME/.dotfiles/bin/linux/bin"
fi

path_prepend "$HOME/.dotfiles/remote_dev/"
path_prepend "$HOME/.dotfiles/dockerfile/"

# set zsh term color
export TERM=xterm-256color
