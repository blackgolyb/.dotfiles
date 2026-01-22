{pkgs, ...}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    python
    uv
  ];
}
