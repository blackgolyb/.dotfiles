#!/bin/sh
# gamma correction
xgamma -rgamma 0.95 -ggamma 0.95 -bgamma 1.1 &

# glava &
# eww open --config ~/.config/eww/test bar
dunst &
# /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
/usr/lib/polkit-kde-authentication-agent-1 &
