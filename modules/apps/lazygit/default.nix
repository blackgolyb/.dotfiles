{ config, lib, ... }:

let
  cfg = config.my.apps.lazygit;
in
{
  options.my.apps.lazygit.enable = lib.mkEnableOption "Lazygit";

  config = lib.mkIf cfg.enable {
    programs.lazygit = {
      enable = true;
      settings = {
        os = {
          editPreset = "nvim";
          editInTerminal = true;
        };
      };
    };
  };
}
