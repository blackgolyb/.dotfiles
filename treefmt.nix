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
  programs.qmlformat = {
    enable = true;
    package = pkgs.qt6Packages.qtdeclarative;
  };
  programs.shfmt.enable = true;
  programs.stylua.enable = true;
  programs.taplo.enable = true;

  settings.formatter.qmlformat.options = [
    "--indent-width"
    "4"
  ];
}
