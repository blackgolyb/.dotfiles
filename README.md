# Dotfiles

![Preview](./public/preview.png)

See [INSTALL.md](./INSTALL.md) for fresh-machine bootstrap details.

Install from a directory containing `keys.txt`:

```sh
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#curl -c sh -c 'curl -fsSL https://raw.githubusercontent.com/blackgolyb/.dotfiles/refs/heads/nixos/install.sh | sh'
```
