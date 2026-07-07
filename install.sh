#!/bin/sh
set -eu

run_dir=$(pwd -P)
repo_url=${REPO_URL:-https://github.com/blackgolyb/.dotfiles.git}
repo_dir=${DOTFILES_DIR:-$HOME/nixos}
flake_name=${FLAKE_NAME:-nixos}

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

run_git() {
  if command -v git >/dev/null 2>&1; then
    git "$@"
  else
    nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git -c git "$@"
  fi
}

install_age_key() {
  source=$run_dir/keys.txt

  [ -f "$source" ] || die "missing $source"

  mkdir -p "$HOME/.config/sops/age"
  chmod 700 "$HOME/.config/sops" "$HOME/.config/sops/age"
  install -m 600 "$source" "$HOME/.config/sops/age/keys.txt"
  log "installed SOPS age key"
}

clone_repo() {
  if [ -d "$repo_dir/.git" ]; then
    log "updating existing repo at $repo_dir"
    run_git -C "$repo_dir" pull --ff-only
    return
  fi

  if [ -e "$repo_dir" ]; then
    die "$repo_dir exists but is not a git repository"
  fi

  mkdir -p "$(dirname "$repo_dir")"
  log "cloning $repo_url to $repo_dir"
  run_git clone "$repo_url" "$repo_dir"
}

import_gpg_keys() {
  imported=0

  if ! command -v gpg >/dev/null 2>&1; then
    log "gpg is not available, skipping GPG imports"
    return
  fi

  for key in "$run_dir"/*.asc "$run_dir"/*.gpg; do
    [ -f "$key" ] || continue
    gpg --import "$key"
    imported=1
  done

  if [ "$imported" -eq 1 ]; then
    log "imported GPG key exports"
  else
    log "no GPG key exports found"
  fi
}

switch_system() {
  [ -f "$repo_dir/flake.nix" ] || die "missing flake.nix in $repo_dir"

  sudo nixos-rebuild switch \
    --flake "$repo_dir#$flake_name" \
    --option experimental-features 'nix-command flakes'
}

start_user_services() {
  systemctl --user daemon-reload || true
  systemctl --user start sops-nix.service ssh-keys.service password-store.service || true
}

install_age_key
clone_repo
switch_system
import_gpg_keys
start_user_services

log "install complete"
