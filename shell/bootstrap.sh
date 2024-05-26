path_prepend "$HOME/.local/bin"

if [[ $OSTYPE == 'darwin'* ]]; then
  path_prepend "$HOME/.dotfiles/bin/macos"
else
  path_prepend "$HOME/.dotfiles/bin/linux/"
fi

path_prepend "$HOME/.dotfiles/remote_dev/"

# set zsh term color
export TERM=xterm-256color

