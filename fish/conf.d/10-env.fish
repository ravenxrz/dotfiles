# Environment variables — fish mirror of shell/external.sh.

# pip should only run if there is a virtualenv currently activated
set -gx PIP_REQUIRE_VIRTUALENV false

# Cache pip-installed packages to avoid re-downloading
set -gx PIP_DOWNLOAD_CACHE "$HOME/.pip/cache"

# Python startup file
set -gx PYTHONSTARTUP "$HOME/.pythonrc"

# Vagrant
set -gx VAGRANT_DISABLE_VBOXSYMLINKCREATE 1

# Ripgrep
set -gx RIPGREP_CONFIG_PATH "$HOME/.ripgreprc"
