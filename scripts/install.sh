#!/usr/bin/env sh

# !!! Use only with main installation script !!!


chmod -R +x $DOTFILES_PATH/scripts/dotfiles.sh
ln --force -s $DOTFILES_PATH/scripts/dotfiles.sh ${HOME}/.local/bin/dotfiles
chmod -R +x $DOTFILES_PATH/scripts/get_dotfiles_dir.sh
ln --force -s $DOTFILES_PATH/scripts/get_dotfiles_dir.sh ${HOME}/.local/bin/get_dotfiles_dir

sh $DOTFILES_PATH/scripts/install_apps.sh
sh $DOTFILES_PATH/scripts/install_config.sh
