{ config, lib, pkgs, ... }:

let
  # Workaround for Zed's managed Node.js not working on NixOS.
  # Zed downloads a generic Linux node binary that fails due to missing dynamic linker.
  # We create a directory that symlinks to Nix's nodejs, with a writable cache dir.
  # See: https://github.com/zed-industries/zed/issues/50828#issuecomment-4031736186
  # See: https://github.com/tonybutt/nix-config/blob/main/modules/hm/editors/zed.nix
  zedNodeVersion = "node-v24.11.0-linux-x64";
  zedNodeShim = pkgs.runCommand "zed-node-shim" { } ''
    mkdir -p $out
    for item in ${pkgs.nodejs}/bin ${pkgs.nodejs}/include ${pkgs.nodejs}/lib ${pkgs.nodejs}/share; do
      ln -s "$item" "$out/$(basename $item)"
    done
    ln -s ${config.home.homeDirectory}/.cache/zed-node $out/cache
  '';
in
{
    # Symlink Nix nodejs into the location Zed expects
    home.file.".local/share/zed/node/${zedNodeVersion}".source = zedNodeShim;

    home.packages = with pkgs; [
    	zed-editor
    ];

    xdg.configFile.zed = {
      source = ./.;
      force = true;
    };
}
