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
    cp -r $src/* $out/lib/music-downloader/
    makeWrapper \
      ${
        python3.withPackages (ps: [
          ps.tqdm
          ps.yt-dlp
        ])
      }/bin/python3 \
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
