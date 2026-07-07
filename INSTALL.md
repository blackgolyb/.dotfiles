# NixOS Install

Minimal fresh-machine bootstrap.

## 1. Prepare Bootstrap Files

Create a temporary directory containing machine secrets copied from a trusted machine:

```text
keys.txt
gpg*.asc or gpg*.gpg, optional
```

`keys.txt` is the SOPS age identity that will be installed to:

```text
~/.config/sops/age/keys.txt
```

## 2. Run Installer

Run the installer from the directory containing the bootstrap files:

```sh
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#curl -c \
  sh -c 'curl -fsSL https://raw.githubusercontent.com/blackgolyb/.dotfiles/refs/heads/nixos/install.sh | sh'
```

The script clones or updates the repo at `~/nixos`, restores local keys, imports optional GPG exports, and runs:

```sh
sudo nixos-rebuild switch --flake ~/nixos#nixos
```

Override defaults if needed:

```sh
REPO_URL=https://github.com/blackgolyb/.dotfiles.git DOTFILES_DIR=~/nixos FLAKE_NAME=nixos sh install.sh
```
