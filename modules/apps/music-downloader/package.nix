{
  ffmpeg,
  lib,
  makeWrapper,
  python3,
  stdenv,
  yt-dlp,
}:

stdenv.mkDerivation {
  pname = "music-downloader";
  version = "0.1.0";

  src = ./src;

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/lib/music-downloader
    install -m644 \
      $src/main.py $src/config.py $src/core.py $src/save.py $src/youtube.py \
      $out/lib/music-downloader/
    makeWrapper \
      ${python3.withPackages (ps: [ ps.yt-dlp ])}/bin/python3 \
      $out/bin/mdl \
      --add-flags "$out/lib/music-downloader/main.py" \
      --prefix PATH : ${
        lib.makeBinPath [
          ffmpeg
          yt-dlp
        ]
      }
    runHook postInstall
  '';
}
