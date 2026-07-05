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

## 4. Verify Secrets And Pass

After login, check SOPS decrypted the GitHub SSH key:

```sh
systemctl --user status sops-nix.service
ls -l ~/.config/sops-nix/secrets/ssh/github
ls -l ~/.ssh/github
```

Expected secret path:

```text
~/.config/sops-nix/secrets/ssh/github
```

Expected convenience symlink for the normal SSH workflow:

```text
~/.ssh/github -> ~/.config/sops-nix/secrets/ssh/github
```

The password store is bootstrapped by `password-store.service` after `sops-nix.service`.
It uses the decrypted GitHub SSH key from the SOPS secrets directory to clone:

```text
git@github.com:blackgolyb/pass.git
```

Verify it:

```sh
systemctl --user status password-store.service
git -C ~/.password-store remote get-url origin
pass ls
```

Expected origin:

```text
git@github.com:blackgolyb/pass.git
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
