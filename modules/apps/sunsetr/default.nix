{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.sunsetr;
  sunsetr = lib.getExe pkgs.sunsetr;
  startTime = lib.replaceStrings [ ":" ] [ "" ] cfg.lateNight.start;
  endTime = lib.replaceStrings [ ":" ] [ "" ] cfg.lateNight.end;

  selectScheduledProfile = pkgs.writeShellApplication {
    name = "sunsetr-select-scheduled-profile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.sunsetr
    ];
    text = ''
      for _ in $(seq 1 20); do
        if sunsetr status >/dev/null 2>&1; then
          break
        fi
        sleep 0.1
      done

      now=$((10#$(date +%H%M)))
      start=$((10#${startTime}))
      end=$((10#${endTime}))

      if
        if [ "$start" -lt "$end" ]; then
          [ "$now" -ge "$start" ] && [ "$now" -lt "$end" ]
        else
          [ "$now" -ge "$start" ] || [ "$now" -lt "$end" ]
        fi
      then
        sunsetr preset late-night
      else
        sunsetr preset default
      fi
    '';
  };
in
{
  options.my.apps.sunsetr = {
    enable = lib.mkEnableOption "Sunsetr";

    lateNight = {
      start = lib.mkOption {
        type = lib.types.strMatching "^([01][0-9]|2[0-3]):[0-5][0-9]$";
        default = "01:00";
        description = "Local time at which the late-night profile starts.";
      };

      end = lib.mkOption {
        type = lib.types.strMatching "^([01][0-9]|2[0-3]):[0-5][0-9]$";
        default = "06:00";
        description = "Local time at which the default profile is restored.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.sunsetr ];

    dotfiles.config = {
      "sunsetr/sunsetr.toml" = {
        source = ./sunsetr.toml;
        force = true;
      };

      "sunsetr/presets/late-night/sunsetr.toml" = {
        source = ./late-night.toml;
        force = true;
      };
    };

    systemd.user.services = {
      sunsetr = {
        Unit = {
          Description = "Sunsetr blue-light filter";
          Documentation = [ "https://psi4j.github.io/projects/sunsetr/" ];
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = sunsetr;
          ExecStartPost = lib.getExe selectScheduledProfile;
          Restart = "on-failure";
          RestartSec = 1;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      sunsetr-refresh = {
        Unit = {
          Description = "Refresh Sunsetr's scheduled profile";
          After = [ "sunsetr.service" ];
          Requisite = [ "sunsetr.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = lib.getExe selectScheduledProfile;
        };
      };
    };

    systemd.user.timers = {
      sunsetr-refresh-start = {
        Unit.Description = "Refresh Sunsetr at ${cfg.lateNight.start}";
        Timer = {
          OnCalendar = "*-*-* ${cfg.lateNight.start}:00";
          Unit = "sunsetr-refresh.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };

      sunsetr-refresh-end = {
        Unit.Description = "Refresh Sunsetr at ${cfg.lateNight.end}";
        Timer = {
          OnCalendar = "*-*-* ${cfg.lateNight.end}:00";
          Unit = "sunsetr-refresh.service";
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
  };
}
