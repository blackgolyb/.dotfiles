{ pkgs, ... }:

{
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    ".direnv/**"
    ".git/**"
    ".pre-commit-config.yaml"
    "flake.lock"
    "monodark.nvim/**"
    "public/**"
    "resources/**"
    "result"
    "result/**"
    "secrets/**"
    "modules/hardware/kanata/poetry.lock"
    "**/*.qsb"
  ];

  programs.nixfmt = {
    enable = true;
    package = pkgs.nixfmt;
  };
  programs.ruff-format = {
    enable = true;
    lineLength = 100;
  };
  programs.shfmt.enable = true;
  programs.stylua.enable = true;
  programs.taplo.enable = true;
}
