{ pkgs, ... }:
{
    services.udev.extraRules = ''
        SUBSYSTEM=="leds", KERNEL=="platform::micmute", RUN+="${pkgs.coreutils}/bin/chmod 0666 /sys/class/leds/platform::micmute/brightness"
    '';
}
