#!/usr/bin/env bash
# Install the terminal toolchain into a devcontainer without touching the
# project's devcontainer.json — the team's config stays untouched, everything
# here lands in $HOME inside the container.
#
# DevPod clones this repo to ~/dotfiles and runs this script from the repo
# root. Wire it up once per machine, it then applies to every workspace:
#
#   devpod context set-options \
#     -o DOTFILES_URL=https://github.com/<user>/dotfiles \
#     -o DOTFILES_SCRIPT=install-devcontainer.sh
#
# No root required: every tool ships a static binary that goes to ~/.local/bin.
set -euo pipefail

# Pinned against the real upstream releases — bump deliberately, not by guess.
NVIM_VERSION=v0.12.6
LAZYGIT_VERSION=0.66.1
ZELLIJ_VERSION=v0.45.1
RIPGREP_VERSION=15.2.0
FD_VERSION=v10.5.0

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BIN_DIR="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> warning:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31m==> error:\033[0m %s\n' "$*" >&2; exit 1; }

# Guard against a stray run on a real machine: this script symlinks configs and
# writes to shell rc files, which is fine in a throwaway container and not fine
# on the host (where stow owns those paths). Override with --force.
in_container() {
  [ -f /.dockerenv ] ||
    [ -f /run/.containerenv ] ||
    [ -n "${REMOTE_CONTAINERS:-}" ] ||
    [ -n "${DEVPOD_WORKSPACE_ID:-}" ]
}

if [ "${1:-}" != "--force" ] && ! in_container; then
  die "no container detected — this script is meant to run inside a devcontainer (use --force to override)"
fi

case "$(uname -m)" in
  # Upstreams disagree on the arm64 spelling, so keep both around.
  x86_64 | amd64) ARCH_GNU=x86_64 ARCH_ALT=x86_64 ;;
  aarch64 | arm64) ARCH_GNU=aarch64 ARCH_ALT=arm64 ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

for cmd in curl tar git; do
  command -v "$cmd" >/dev/null || die "$cmd is required but missing from the image"
done

mkdir -p "$BIN_DIR" "$OPT_DIR"

# True when the wanted version is not already installed. Upstream --version
# output carries the number without a leading v, so normalise before matching.
needs_install() {
  local bin=$1 want=${2#v}
  [ -x "$BIN_DIR/$bin" ] || return 0
  "$BIN_DIR/$bin" --version 2>/dev/null | head -n1 | grep -qF "$want" && return 1
  return 0
}

# Unpack a release tarball and pick the binary out of it, regardless of whether
# the archive is flat (lazygit, zellij) or nested in a version directory (rg, fd).
install_binary() {
  local name=$1 url=$2 tmp found
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  curl -fsSL "$url" | tar -xz -C "$tmp"
  found=$(find "$tmp" -type f -name "$name" | head -n1)
  [ -n "$found" ] || die "$name not found in $url"
  install -m 755 "$found" "$BIN_DIR/$name"
}

install_nvim() {
  local tmp dir="$OPT_DIR/nvim"
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' RETURN
  # The tarball, not the AppImage: AppImages need FUSE, which containers rarely have.
  curl -fsSL "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${ARCH_ALT}.tar.gz" |
    tar -xz -C "$tmp"
  rm -rf "$dir"
  mv "$tmp/nvim-linux-${ARCH_ALT}" "$dir"
  ln -sfn "$dir/bin/nvim" "$BIN_DIR/nvim"
}

# Point ~/.config/<pkg> at this repo, the same layout stow produces on the host.
link_config() {
  # Separate declarations: within one local statement $pkg is not assigned yet.
  local pkg=$1
  local src="$REPO_DIR/$pkg/.config/$pkg"
  local target="$HOME/.config/$pkg"
  [ -d "$src" ] || { warn "no config for $pkg in this repo, skipping"; return; }
  mkdir -p "$HOME/.config"
  # Never clobber a real directory the image shipped — only replace our own symlink.
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    warn "$target exists and is not a symlink, leaving it alone"
    return
  fi
  ln -sfn "$src" "$target"
}

ensure_path() {
  local rc
  touch "$HOME/.profile"
  for rc in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    grep -qF '.local/bin' "$rc" && continue
    # shellcheck disable=SC2016  # the rc file must expand these, not this script
    printf '\n# added by dotfiles install-devcontainer.sh\nexport PATH="$HOME/.local/bin:$PATH"\n' >>"$rc"
  done
}

if needs_install nvim "$NVIM_VERSION"; then
  log "installing neovim ${NVIM_VERSION}"
  install_nvim
else
  log "neovim ${NVIM_VERSION} already installed"
fi

if needs_install lazygit "$LAZYGIT_VERSION"; then
  log "installing lazygit ${LAZYGIT_VERSION}"
  install_binary lazygit \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_linux_${ARCH_ALT}.tar.gz"
else
  log "lazygit ${LAZYGIT_VERSION} already installed"
fi

if needs_install zellij "$ZELLIJ_VERSION"; then
  log "installing zellij ${ZELLIJ_VERSION}"
  install_binary zellij \
    "https://github.com/zellij-org/zellij/releases/download/${ZELLIJ_VERSION}/zellij-${ARCH_GNU}-unknown-linux-musl.tar.gz"
else
  log "zellij ${ZELLIJ_VERSION} already installed"
fi

# telescope and the snacks picker are close to useless without these two.
if needs_install rg "$RIPGREP_VERSION"; then
  log "installing ripgrep ${RIPGREP_VERSION}"
  install_binary rg \
    "https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-${ARCH_GNU}-unknown-linux-musl.tar.gz"
else
  log "ripgrep ${RIPGREP_VERSION} already installed"
fi

if needs_install fd "$FD_VERSION"; then
  log "installing fd ${FD_VERSION}"
  install_binary fd \
    "https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-${ARCH_GNU}-unknown-linux-musl.tar.gz"
else
  log "fd ${FD_VERSION} already installed"
fi

log "linking configs"
# Deliberately not zsh/p10k: the zshrc in this repo carries hard macOS paths.
link_config nvim
link_config zellij
link_config lazygit

ensure_path

# Pre-install the plugins so the first nvim start is not a two-minute wait.
# Non-fatal: a plugin that fails to build should not fail the whole workspace.
log "syncing neovim plugins"
"$BIN_DIR/nvim" --headless "+Lazy! sync" +qa 2>&1 | tail -n 5 ||
  warn "plugin sync failed — run :Lazy sync inside nvim to see why"

log "done — open a new shell, then run zellij"
