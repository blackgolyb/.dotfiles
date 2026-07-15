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

  programs = {
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt;
    };
    ruff-format = {
      enable = true;
      lineLength = 100;
    };
    qmlformat = {
      enable = true;
      package = pkgs.qt6Packages.qtdeclarative;
    };
    shfmt.enable = true;
    stylua.enable = true;
    taplo.enable = true;
  };

  settings.formatter.qmlformat.options = [
    "--indent-width"
    "4"
  ];
}
