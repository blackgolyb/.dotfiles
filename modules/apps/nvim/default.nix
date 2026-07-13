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
      gopls
      nixd
      lua-language-server     # lua_ls
      vtsls
      vue-language-server      # vue_ls
      vscode-langservers-extracted # html, cssls, jsonls, eslint
      tailwindcss-language-server
      emmet-ls
      basedpyright
      ruff
      clang-tools             # clangd
      rust-analyzer
      elixir-ls
      bash-language-server
      docker-language-server
      hadolint
      sqls
      texlab
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
