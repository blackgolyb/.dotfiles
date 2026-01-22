{pkgs, ...}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    nodejs
    fnm
    yarn
  ];
}
