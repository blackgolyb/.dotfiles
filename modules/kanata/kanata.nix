{ config, lib, ... }:

let
  kanataConfigDir = builtins.path {
    path = ./config;
    name = "kanata-config";
  };
in
{
  config.services.kanata = {
    enable = true;
    keyboards.default.configFile =
      "${kanataConfigDir}/config.kbd";
  };
}
