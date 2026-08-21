{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.tailscale;
in
{
  options.my.system.tailscale.enable = lib.mkEnableOption "Tailscale VPN";

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";

      extraSetFlags = [
        "--accept-dns=true"
        "--operator=blackgolyb"
      ];
    };

    environment.systemPackages = with pkgs; [
      tailscale
    ];

    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
