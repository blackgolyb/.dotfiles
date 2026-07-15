{
  pkgs,
  system,
  treefmt-nix,
  git-hooks,
  ...
}:

let
  inherit (pkgs) lib;
  root = ../.;
  cleanSrc = lib.cleanSourceWith {
    src = root;
    filter =
      path: _type:
      let
        rel = lib.removePrefix "${toString root}/" (toString path);
        excluded = [
          ".git"
          ".git/"
          ".direnv"
          ".direnv/"
          ".pre-commit-config.yaml"
          "public"
          "public/"
          "secrets"
          "secrets/"
        ];
      in
      !(lib.any (prefix: rel == prefix || lib.hasPrefix prefix rel) excluded);
  };
  treefmtEval = treefmt-nix.lib.evalModule pkgs ../treefmt.nix;
  qmlPackages = [
    pkgs.qt6Packages.qtdeclarative
    pkgs.quickshell
  ];
  qmlImportPath = lib.makeSearchPath "lib/qt-6/qml" qmlPackages;
  qtPluginPath = lib.makeSearchPath "lib/qt-6/plugins" qmlPackages;
  qmlLint = pkgs.writeShellScriptBin "qmllint-dotfiles" ''
    set -eu

    export QML_IMPORT_PATH="${qmlImportPath}:''${QML_IMPORT_PATH:-}"
    export QML2_IMPORT_PATH="${qmlImportPath}:''${QML2_IMPORT_PATH:-}"
    export QT_PLUGIN_PATH="${qtPluginPath}:''${QT_PLUGIN_PATH:-}"

    exec ${pkgs.qt6Packages.qtdeclarative}/bin/qmllint \
      -E \
      -I modules/de/hyprland/quickshell \
      --import disable \
      --missing-property disable \
      --signal-handler-parameters disable \
      --uncreatable-type disable \
      --unqualified disable \
      --unresolved-type disable \
      --unused-imports disable \
      "$@"
  '';
  preCommitCheck = git-hooks.lib.${system}.run {
    src = cleanSrc;
    hooks = {
      treefmt = {
        enable = true;
        name = "treefmt";
        entry = "${treefmtEval.config.build.wrapper}/bin/treefmt --no-cache";
      };
      deadnix = {
        enable = true;
        name = "deadnix";
        entry = "${pkgs.deadnix}/bin/deadnix --fail --no-lambda-pattern-names";
        files = "\\.nix$";
      };
      statix = {
        enable = true;
        name = "statix";
        entry = "${pkgs.statix}/bin/statix check";
        pass_filenames = false;
      };
      ruff.enable = true;
      shellcheck = {
        enable = true;
        name = "shellcheck";
        entry = "${pkgs.shellcheck}/bin/shellcheck --severity=error";
        files = "\\.sh$";
      };
      qmllint = {
        enable = true;
        name = "qmllint";
        entry = "${qmlLint}/bin/qmllint-dotfiles";
        files = "^modules/de/hyprland/quickshell/.*\\.qml$";
      };
      typos = {
        enable = true;
        name = "typos";
        entry = "${pkgs.typos}/bin/typos --force-exclude";
      };
      check-merge-conflicts.enable = true;
      check-symlinks.enable = true;
    };
  };
in
{
  formatter = treefmtEval.config.build.wrapper;

  checks = {
    formatting = treefmtEval.config.build.check cleanSrc;
    pre-commit = preCommitCheck;
  };

  shell = pkgs.mkShell {
    shellHook = ''
      ${preCommitCheck.shellHook}
      export QML_IMPORT_PATH="${qmlImportPath}:''${QML_IMPORT_PATH:-}"
      export QML2_IMPORT_PATH="${qmlImportPath}:''${QML2_IMPORT_PATH:-}"
      export QT_PLUGIN_PATH="${qtPluginPath}:''${QT_PLUGIN_PATH:-}"
    '';
    packages = [
      treefmtEval.config.build.wrapper
      qmlLint
      pkgs.python3Packages.pytest
      pkgs.typos
    ]
    ++ qmlPackages
    ++ preCommitCheck.enabledPackages;
  };
}
