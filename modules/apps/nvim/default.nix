{ config, lib, pkgs, ... }:

let
  cfg = config.my.apps.nvim;
in
{
  options.my.apps.nvim.enable = lib.mkEnableOption "Neovim";

  config = lib.mkIf cfg.enable {
    stylix.targets.neovim.enable = false;

    home.packages = with pkgs; [
      neovim
      neovim-remote
      xclip
      unzip
      lsof
      nodejs
      git
      gcc
      gnumake
      tree-sitter
      python3
      rustc
      cargo
      wget
      curl

      # lsp
      nixd
      lua-language-server     # lua_ls
      typescript-language-server # ts_ls
      vscode-langservers-extracted # html, cssls, jsonls, eslint
      tailwindcss-language-server
      emmet-ls
      pyright
      ruff
      clang-tools             # clangd
      rust-analyzer
      elixir-ls
      bash-language-server
      dockerfile-language-server
      hadolint
      taplo                   # toml
      yaml-language-server
      typos-lsp
      marksman
      wgsl-analyzer
    ];

    dotfiles.config."nvim" = {
      source = ./.;
      recursive = true;
      force = true;
    };
  };
}
