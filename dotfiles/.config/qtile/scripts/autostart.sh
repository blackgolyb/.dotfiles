#!/bin/sh
# gamma correction for ThinkPad t480 yellow screen
xgamma -rgamma 0.95 -ggamma 0.95 -bgamma 1.1 &
xset b off &

# glava &
# eww open --config ~/.config/eww/test bar
dunst &
greenclip daemon &
tmux start &

zen-browser &
superproductivity &

# setxkbmap -option ctrl:swapcaps
# /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
/usr/lib/polkit-kde-authentication-agent-1 &
