#!/usr/bin/env sh

function main() {
    sudo pacman-mirrors -f
    sudo pacman -Syu
    sudo pacman -S\
        wezterm\
        zsh\
        exa\
        bat\
        zoxide\
        qtile\
        picom\
        dunst\
        rofi\
        betterlockscreen\
        nmcli\
        bluez
}


echo "Install Apps..."
