# NixOS Bootstrap

Short checklist for a fresh NixOS machine.

## 1. Get The Repo

Install temporary tools if needed:

```sh
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git nixpkgs#openssh
```

Clone or copy this repo:

```sh
git clone git@github.com:blackgolyb/nixos.git ~/nixos
cd ~/nixos
```

If SSH is not available yet, clone with HTTPS or copy the repo from another machine.

## 2. Restore SOPS Age Key

Copy this file from an existing trusted machine:

```text
~/.config/sops/age/keys.txt
```

Place it on the new machine:

```sh
mkdir -p ~/.config/sops/age
chmod 700 ~/.config/sops ~/.config/sops/age
cp keys.txt ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Without this key, `sops-nix` cannot decrypt secrets like `ssh/github`.

## 3. Switch System

Run the flake:

```sh
sudo nixos-rebuild switch --flake ~/nixos#nixos --option experimental-features 'nix-command flakes'
```

This applies NixOS and Home Manager config for user `blackgolyb`.

## 4. Verify Secrets

After login, check SOPS decrypted the GitHub SSH key:

```sh
systemctl --user status sops-nix.service
ls -l ~/.config/sops-nix/secrets/ssh/github
```

Expected secret path:

```text
~/.config/sops-nix/secrets/ssh/github
```

## 5. If Age Key Is Lost

On a machine that can still decrypt secrets:

```sh
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Put the new public recipient into `.sops.yaml`, then re-encrypt secrets:

```sh
sops updatekeys secrets/ssh.yaml
```
