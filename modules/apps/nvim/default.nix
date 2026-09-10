{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.apps.nvim;

  magickPath = "${pkgs.luajitPackages.magick}/share/lua/5.1";

  neovimWrapped = pkgs.symlinkJoin {
    name = "neovim-wrapped";
    paths = [ pkgs.neovim ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim \
        --set LUA_PATH '${magickPath}/?.lua;${magickPath}/?/init.lua;;'
    '';
  };

  pythonEnv = pkgs.python3.withPackages (
    ps: with ps; [
      pynvim
      jupyter-client
      ipykernel
      cairosvg
      pyperclip
      nbformat
      pillow
      pnglatex
    ]
  );

  texliveEnv = pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-small pdfcrop;
  };
in
{
  options.my.apps.nvim.enable = lib.mkEnableOption "Neovim";

  config = lib.mkIf cfg.enable {
    stylix.targets.neovim.enable = false;

    home.packages = with pkgs; [
      neovimWrapped
      neovim-remote
      xclip
      unzip
      lsof
      nodejs
      git
      gcc
      gnumake
      tree-sitter
      pythonEnv
      rustc
      cargo
      jdk
      maven
      gradle
      kotlin
      wget
      curl

      # lsp
      gopls
      nixd
      lua-language-server # lua_ls
      vtsls
      vue-language-server # vue_ls
      vscode-langservers-extracted # html, cssls, jsonls, eslint
      tailwindcss-language-server
      emmet-ls
      basedpyright
      ruff
      clang-tools # clangd
      rust-analyzer
      jdt-language-server # jdtls
      kotlin-lsp
      elixir-ls
      bash-language-server
      docker-language-server
      hadolint
      sqls
      texlab
      taplo # toml
      yaml-language-server
      typos-lsp
      marksman
      wgsl-analyzer

      # jvm formatting/linting
      google-java-format
      ktlint

      # molten-nvim / notebook
      imagemagick
      ghostscript # pdfcrop
      netpbm # pdftopnm / pnmtopng for pnglatex
      quarto # quarto rendering
      python3Packages.jupytext
      texliveEnv # pdflatex, pdfcrop for pnglatex formula rendering
    ];

    dotfiles.config."nvim" = {
      source = ./.;
      recursive = true;
      force = true;
    };
  };
}
