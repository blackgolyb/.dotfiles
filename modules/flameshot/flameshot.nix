{ pkgs, ... }:

{
  home.packages = with pkgs; [
    flameshot
    (writeShellScriptBin "flameshot-session" ''
      set -euo pipefail

      config_home="$HOME/.config/flameshot-wayland"
      if [ "''${XDG_SESSION_TYPE:-}" = "x11" ] || { [ -n "''${DISPLAY:-}" ] && [ -z "''${WAYLAND_DISPLAY:-}" ]; }; then
        config_home="$HOME/.config/flameshot-x11"
      fi

      export XDG_CONFIG_HOME="$config_home"
      exec flameshot "$@"
    '')
  ];

  xdg.configFile."flameshot-x11/flameshot/flameshot.ini".text = ''
    [General]
    useX11LegacyScreenshot=true
  '';

  xdg.configFile."flameshot-wayland/flameshot/flameshot.ini".text = ''
    [General]
    useGrimAdapter=true
  '';
}
