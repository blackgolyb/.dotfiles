{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.starship;
in
{
  options.my.apps.starship.enable = lib.mkEnableOption "Starship";

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = with pkgs; [
          starship
        ];
      }
      {
        dotfiles.config."starship/starship.toml" = {
          source = ./starship.toml;
        };
      }
    ]
  );
}
