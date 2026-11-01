path_prepend "$HOME/.dotfiles/bin/common"
if [[ $OSTYPE == 'darwin'* ]]; then
  # Prefer native Apple Silicon Homebrew tools over legacy Intel installs in
  # /usr/local. Keep this in the shared bootstrap so both zsh and bash agree.
  if [[ -d /opt/homebrew/bin ]]; then
    path_prepend "/opt/homebrew/sbin"
    path_prepend "/opt/homebrew/bin"
  fi
  path_prepend "$HOME/.dotfiles/bin/macos"
else
  path_prepend "$HOME/.dotfiles/bin/linux/"
  path_prepend "$HOME/.dotfiles/bin/linux/bin"
fi

path_prepend "$HOME/.dotfiles/remote_dev/"
path_prepend "$HOME/.dotfiles/dockerfile/"

# set zsh term color
export TERM=xterm-256color
