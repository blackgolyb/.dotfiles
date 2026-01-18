{ config, lib, pkgs, ... }:
{
    home.packages = with pkgs; [
    	zed-editor
    ];

    xdg.configFile.zed = {
      source = ./.;
      force = true;
    };
}
