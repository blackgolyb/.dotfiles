{
  self,
  pkgs,
  system,
  treefmt-nix,
  git-hooks,
  ...
}:

let
  treefmtEval = treefmt-nix.lib.evalModule pkgs ../treefmt.nix;
  preCommitCheck = git-hooks.lib.${system}.run {
    src = ../.;
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
      check-merge-conflicts.enable = true;
      check-symlinks.enable = true;
    };
  };
in
{
  formatter = treefmtEval.config.build.wrapper;

  checks = {
    formatting = treefmtEval.config.build.check self;
    pre-commit = preCommitCheck;
  };

  shell = pkgs.mkShell {
    shellHook = preCommitCheck.shellHook;
    packages = [ treefmtEval.config.build.wrapper ] ++ preCommitCheck.enabledPackages;
  };
}
