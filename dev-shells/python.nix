{ pkgs, ... }:
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    python3
    ruff
    uv
  ];
}
