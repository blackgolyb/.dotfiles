{ config, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
  };

  home.packages = with pkgs; [
    xclip
    unzip
    nodejs
    git
    gcc
    gnumake
    python3
    wget
    curl

    # lsp
    nixd
    lua-language-server     # lua_ls
    nodePackages.typescript-language-server # ts_ls
    nodePackages.vscode-langservers-extracted # html, cssls, jsonls, eslint
    tailwindcss-language-server
    emmet-ls
    pyright
    ruff
    clang-tools             # clangd
    rust-analyzer
    elixir-ls
    nodePackages.bash-language-server
    dockerfile-language-server
    hadolint
    taplo                   # toml
    yaml-language-server
    typos-lsp
    marksman
  ];

  xdg.configFile."nvim" = {
    source = ./.;
    recursive = true;
  };
}
