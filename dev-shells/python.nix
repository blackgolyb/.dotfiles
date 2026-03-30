{pkgs, ...}:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    python
    ruff
    uv
  ];
}
