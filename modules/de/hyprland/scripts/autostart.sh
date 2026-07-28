#!/bin/sh

dbus-update-activation-environment --systemd --all &
systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE DBUS_SESSION_BUS_ADDRESS &

qsm &
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

"$HOME/.config/hypr/scripts/volume_control" init &
"$HOME/.config/hypr/scripts/multi_monitor" autoconfigure &
wallpaper_manager random --type image &

zen-twilight &
Telegram &
