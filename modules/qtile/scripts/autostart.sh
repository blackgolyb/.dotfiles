#!/bin/sh
# gamma correction for ThinkPad e14 yellow screen
xgamma -rgamma 0.95 -ggamma 0.95 -bgamma 1.1 &
dbus-update-activation-environment --all &

# glava &
# eww open --config ~/.config/eww/test bar
dunst &
unclutter --timeout 10 --jitter 0 &
greenclip daemon &
tmux start &

zen-twilight &
Telegram &
