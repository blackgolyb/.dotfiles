#!/bin/sh
# gamma correction for ThinkPad t480 yellow screen
xgamma -rgamma 0.95 -ggamma 0.95 -bgamma 1.1 &

# glava &
# eww open --config ~/.config/eww/test bar
dunst &
greenclip daemon &
tmux start &

zen &
super-productivity &

gnome-keyring-daemon --start --components=pkcs11,secrets,ssh &
