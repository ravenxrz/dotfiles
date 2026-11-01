# Herdr dotfiles

Herdr itself and the plugins used by this setup are bootstrapped by
`install-plugins.sh`, which Dotbot runs from the repository-level `./install`.

Managed plugins:

- `persiyanov/herdr-reviewr`
- `paulbkim-dev/vim-herdr-navigation`
- `kryptamine/herdr-auto-title`

`herdr-auto-title` is built from source and needs Go 1.24 or newer. On macOS,
the bootstrap installs a current native Homebrew Go toolchain when necessary.

Normal bootstrap is idempotent and skips plugins that are already registered:

```sh
./install
```

To refresh the GitHub installations to their current default branches:

```sh
HERDR_REFRESH_PLUGINS=1 ./install
```

The generated registry and plugin checkouts under `~/.config/herdr` contain
machine-specific absolute paths and are deliberately not stored in this repo.
Only the reproducible config, plugin list, and Neovim integration belong here.
