# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=false

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc

# Vagrant
VAGRANT_DISABLE_VBOXSYMLINKCREATE=1

# Ripgep
export RIPGREP_CONFIG_PATH=$HOME/.ripgreprc
