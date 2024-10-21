#!/usr/bin/env sh

cd ~

if [ -d "$HOME/.dotfiles" ]; then
    cd .dotfiles
    git pull
else
    echo "Select type of connection:"
    select connection in ssh http; do
        case $connection in
            ssh)
                git clone git@github.com:blackgolyb/.dotfiles.git
                break
            ;;
            http)
                git clone https://github.com/blackgolyb/.dotfiles.git
                break
            ;;
        esac
    done
    cd .dotfiles
fi

sh scripts/install.sh
