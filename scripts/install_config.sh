#!/usr/bin/env sh

echo "Install Config..."

PROJECT_DIR=$(get_dotfiles_dir)

DOTFILES_DIR=${PROJECT_DIR}/dotfiles
ROOT_DOTFILES_DIR=${PROJECT_DIR}/dotfiles/root
SCRIPTS_DOTFILES_DIR=${PROJECT_DIR}/dotfiles/scripts

read -s -p "Password: " PASSWORD
echo ""

cd ${DOTFILES_DIR}
stow --target=${HOME} .

cd ${SCRIPTS_DOTFILES_DIR}
chmod -R +x .
echo $PASSWORD | sudo -S stow --target=${HOME}/.local/bin .

cd ${ROOT_DOTFILES_DIR}
echo $PASSWORD | sudo -S stow --target=/ .
