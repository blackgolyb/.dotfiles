{
  pkgs,
  system,
  treefmt-nix,
  git-hooks,
  ...
}:

let
  lib = pkgs.lib;
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
  preCommitCheck = git-hooks.lib.${system}.run {
    src = cleanSrc;
    hooks = {
      treefmt = {
        enable = true;
        name = "treefmt";
        entry = "${treefmtEval.config.build.wrapper}/bin/treefmt";
      };
      deadnix = {
        enable = true;
        name = "deadnix";
        entry = "${pkgs.deadnix}/bin/deadnix --fail --no-lambda-pattern-names";
        files = "\\.nix$";
      };
      ruff.enable = true;
      shellcheck = {
        enable = true;
        name = "shellcheck";
        entry = "${pkgs.shellcheck}/bin/shellcheck --severity=error";
        files = "\\.sh$";
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
    shellHook = preCommitCheck.shellHook;
    packages = [
      treefmtEval.config.build.wrapper
      pkgs.python3Packages.pytest
      pkgs.typos
    ]
    ++ preCommitCheck.enabledPackages;
  };
}
