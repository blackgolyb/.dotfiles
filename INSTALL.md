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

## 4. Verify SSH Keys And Pass

After login, check sops-nix decrypted the system GitHub key and the SSH key installer linked the user GitHub key:

```sh
systemctl --user status sops-nix.service
systemctl --user status ssh-keys.service
ls -l ~/.config/sops-nix/secrets/ssh/system/github
ls -l "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/dotfiles-ssh/user/github"
ls -l ~/.ssh/github
ls -l ~/.ssh/github.pub
```

Expected runtime secret paths:

```text
~/.config/sops-nix/secrets/ssh/system/github
${XDG_RUNTIME_DIR}/dotfiles-ssh/user/github
```

Expected convenience symlink for the normal SSH workflow:

```text
~/.ssh/github -> ${XDG_RUNTIME_DIR}/dotfiles-ssh/user/github
~/.ssh/github.pub -> ${XDG_RUNTIME_DIR}/dotfiles-ssh/user/github.pub
```

The password store is bootstrapped by `password-store.service` after `sops-nix.service`.
It uses the explicit sops-nix system GitHub SSH key to clone:

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

## 5. Add SSH Keys

Generate a service-only key under `secrets/ssh/system/`:

```sh
dotfiles ssh-keygen system <name>
```

Generate a user workflow key under `secrets/ssh/user/`:

```sh
dotfiles ssh-keygen user <name>
```

You can also pass an explicit encrypted private key file path:

```sh
dotfiles ssh-keygen user <name> secrets/ssh/user/custom-name.key
```

The command writes an encrypted private key file and a plain public key file next to it.
Files under `secrets/ssh/user/*.key` are linked automatically to `~/.ssh/<name>` with matching `~/.ssh/<name>.pub`.
System keys under `secrets/ssh/system/*.key` must be declared explicitly in `my.apps.secrets.secrets` and are consumed through `config.sops.secrets.<name>.path`.

## 6. If Age Key Is Lost

On a machine that can still decrypt secrets:

```sh
age-keygen -o ~/.config/sops/age/keys.txt
age-keygen -y ~/.config/sops/age/keys.txt
```

Put the new public recipient into `.sops.yaml`, then re-encrypt secrets:

```sh
sops updatekeys secrets/ssh/system/*.key
sops updatekeys secrets/ssh/user/*.key
```
