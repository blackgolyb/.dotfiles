#!/usr/bin/env sh

DOTFILES_DIR=".dotfiles"
DOTFILES_PATH="$HOME/$DOTFILES_DIR"

case $1 in
    "update")
        ;;
    "")
        echo "You should provide option"
        ;;
    *)
        echo "No option $1"
esac
