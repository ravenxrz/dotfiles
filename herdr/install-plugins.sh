#!/usr/bin/env bash
# Install the Herdr runtime, build prerequisites, and plugins declared by these
# dotfiles.
# Safe to run on every `./install`: existing plugins are left alone unless
# HERDR_REFRESH_PLUGINS=1 is set.

set -euo pipefail

install_herdr() {
    if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
        echo "==> herdr not found, installing with Homebrew..."
        brew install herdr
        return
    fi

    echo "!! herdr is not installed and no supported installer was found." >&2
    echo "!! Install it from https://herdr.dev, then rerun ./install." >&2
    return 1
}

go_version_supported() {
    command -v go >/dev/null 2>&1 || return 1

    local version major minor
    version="$(go env GOVERSION 2>/dev/null)" || return 1
    version="${version#go}"
    major="${version%%.*}"
    version="${version#*.}"
    minor="${version%%.*}"

    case "${major}" in
        ''|*[!0-9]*) return 1 ;;
    esac
    case "${minor}" in
        ''|*[!0-9]*) return 1 ;;
    esac

    [ "${major}" -gt 1 ] || {
        [ "${major}" -eq 1 ] && [ "${minor}" -ge 24 ]
    }
}

install_go() {
    if [ "$(uname -s)" = "Darwin" ] && command -v brew >/dev/null 2>&1; then
        echo "==> Go 1.24+ not found, installing with Homebrew..."
        brew install go

        # Prefer the native Homebrew toolchain over a legacy Intel Homebrew or
        # official-package installation under /usr/local.
        local brew_bin
        brew_bin="$(brew --prefix)/bin"
        PATH="${brew_bin}:${PATH}"
        export PATH
        hash -r
        return
    fi

    echo "!! herdr-auto-title requires Go 1.24 or newer." >&2
    echo "!! Install Go from https://go.dev, then rerun ./install." >&2
    return 1
}

plugin_installed() {
    local plugin_id="$1"
    herdr plugin list --json | grep -Fq "\"plugin_id\":\"${plugin_id}\""
}

install_plugin() {
    local source="$1"
    local plugin_id="$2"
    local go_proxy="${3:-}"

    if [ "${HERDR_REFRESH_PLUGINS:-0}" != "1" ] && plugin_installed "${plugin_id}"; then
        echo "==> Herdr plugin already installed: ${plugin_id}"
        return
    fi

    echo "==> Installing Herdr plugin: ${source}"
    if [ -n "${go_proxy}" ]; then
        env GOPROXY="${go_proxy}" herdr plugin install --yes "${source}"
    else
        herdr plugin install --yes "${source}"
    fi
}

python_version_supported() {
    local python_bin="$1"
    "${python_bin}" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 9) else 1)' \
        >/dev/null 2>&1
}

find_python_39() {
    local candidate resolved
    for candidate in \
        "${OPENSPEC_PYTHON:-}" \
        python3 python3.13 python3.12 python3.11 python3.10 python3.9 \
        "${HOME}"/.pyenv/versions/*/bin/python3; do
        [ -n "${candidate}" ] || continue

        if [[ "${candidate}" == */* ]]; then
            [ -x "${candidate}" ] || continue
            resolved="${candidate}"
        else
            resolved="$(command -v "${candidate}" 2>/dev/null)" || continue
        fi

        if python_version_supported "${resolved}"; then
            "${resolved}" -c 'import sys; print(sys.executable)'
            return
        fi
    done
    return 1
}

configure_openspec_plugin() {
    local python_bin plugin_root launcher

    if ! python_bin="$(find_python_39)"; then
        echo "!! herdr-openspec requires Python 3.9 or newer." >&2
        echo "!! Install a supported Python or set OPENSPEC_PYTHON=/absolute/path/to/python." >&2
        return 1
    fi

    plugin_root="$(
        herdr plugin list --plugin openspec --json |
            "${python_bin}" -c 'import json, sys; print(json.load(sys.stdin)["result"]["plugins"][0]["plugin_root"])'
    )"
    launcher="${plugin_root}/bin/ospec"

    if [ ! -f "${launcher}" ]; then
        echo "!! herdr-openspec launcher not found: ${launcher}" >&2
        return 1
    fi

    # The upstream launcher uses `#!/usr/bin/env python3`. Herdr may run with a
    # smaller service PATH than the interactive shell, so pin the interpreter
    # selected above. Reapply this after every managed plugin refresh.
    OPENSPEC_LAUNCHER="${launcher}" OPENSPEC_PYTHON="${python_bin}" \
        "${python_bin}" -c '
import os
from pathlib import Path

path = Path(os.environ["OPENSPEC_LAUNCHER"])
lines = path.read_text().splitlines(keepends=True)
lines[0] = "#!" + os.environ["OPENSPEC_PYTHON"] + "\n"
path.write_text("".join(lines))
'
    chmod +x "${launcher}"
    echo "==> Configured herdr-openspec with ${python_bin}"
}

if ! command -v herdr >/dev/null 2>&1; then
    install_herdr
fi

if ! go_version_supported; then
    install_go
fi
if ! go_version_supported; then
    echo "!! Active Go toolchain is still older than 1.24." >&2
    exit 1
fi

# Declarative plugin list. GitHub installs intentionally follow the source's
# default branch; Herdr records the resolved commit in its generated registry.
install_plugin "persiyanov/herdr-reviewr" "persiyanov.reviewr"
install_plugin "paulbkim-dev/vim-herdr-navigation" "vim-herdr-navigation"
install_plugin "kryptamine/herdr-auto-title" "herdr.auto-title" "${GOPROXY:-direct}"
install_plugin "FlorisKr/herdr-openspec" "openspec"

configure_openspec_plugin

herdr config check

# A fresh machine may not have started Herdr yet. Reload only an existing
# server; the next server start reads the linked config automatically.
if herdr status server --json 2>/dev/null | grep -Fq '"running":true'; then
    herdr server reload-config >/dev/null
    herdr plugin action invoke herdr.auto-title.restart >/dev/null
    echo "==> Reloaded the running Herdr server config."
fi
