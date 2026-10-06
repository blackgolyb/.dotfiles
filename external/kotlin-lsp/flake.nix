{
  description = "Official Kotlin Language Server by JetBrains";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      version = "263.6379.0";
    in
    {
      packages.${system} = {
        default = pkgs.stdenv.mkDerivation {
          pname = "kotlin-lsp";
          inherit version;

          src = pkgs.fetchzip {
            url = "https://download.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}.tar.gz";
            hash = "sha256-MQZ2Q70IYbVpKVg8D7yjK/jpboMuNjKGslxFOw+6b9I=";
          };

          nativeBuildInputs = [
            pkgs.autoPatchelfHook
            pkgs.makeWrapper
          ];

          buildInputs = [
            pkgs.stdenv.cc.cc.lib
            pkgs.zlib
            pkgs.libx11
            pkgs.libxext
            pkgs.libxrender
            pkgs.libxtst
            pkgs.libxi
            pkgs.freetype
            pkgs.wayland
            pkgs.libxkbcommon
            pkgs.alsa-lib
          ];

          installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/libexec
            cp -r ./* $out/libexec
            chmod -R u+w $out/libexec
            chmod +x $out/libexec/bin/intellij-server
            chmod +x $out/libexec/jbr/bin/*
            makeWrapper $out/libexec/bin/intellij-server $out/bin/kotlin-lsp

            runHook postInstall
          '';

          meta = {
            description = "Kotlin Language Server by JetBrains";
            homepage = "https://github.com/Kotlin/kotlin-lsp";
            license = pkgs.lib.licenses.asl20;
            platforms = [ "x86_64-linux" ];
          };
        };
      };

      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
