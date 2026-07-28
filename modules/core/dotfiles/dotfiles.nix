{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.dotfiles;

  entryType = lib.types.submodule {
    options = {
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Path relative to dotfiles.root used for impure symlinks. If null, it is inferred from source.";
      };

      source = lib.mkOption {
        type = lib.types.path;
        description = "Nix path used for pure store-backed Home Manager files.";
      };

      recursive = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether Home Manager should recursively install this source in pure mode.";
      };

      executable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether Home Manager should make this file executable in pure mode.";
      };

      force = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether existing real files may be replaced in impure mode and pure mode.";
      };

      attrs = lib.mkOption {
        type = lib.types.attrs;
        default = { };
        description = "Additional attributes passed to the pure Home Manager file declaration.";
      };
    };
  };

  pureAttrs =
    entry:
    entry.attrs
    // {
      inherit (entry) source;
    }
    // lib.optionalAttrs entry.recursive { recursive = true; }
    // lib.optionalAttrs entry.executable { executable = true; }
    // lib.optionalAttrs entry.force { force = true; };

  renderActivationEntry =
    homeTarget: entry:
    let
      inferredPath =
        let
          sourceRoot = "${cfg.sourceRoot}/";
          sourcePath = toString entry.source;
          relativePath = lib.removePrefix sourceRoot sourcePath;
        in
        if relativePath == sourcePath then
          throw "Cannot infer dotfile path for ${sourcePath}; set dotfiles.*.<name>.path explicitly or adjust dotfiles.sourceRoot."
        else
          relativePath;
      repoPath = if entry.path == null then inferredPath else entry.path;
      source = "${cfg.root}/${repoPath}";
      force = if entry.force then "1" else "0";
      executable = if entry.executable then "1" else "0";
    in
    ''
      target="$HOME/${homeTarget}"
      source=${lib.escapeShellArg source}
      force=${force}
      executable=${executable}

      if [ ! -e "$source" ] && [ ! -L "$source" ]; then
        echo "Missing dotfile source: $source" >&2
        exit 1
      fi

      if [ "$executable" = 1 ]; then
        run chmod +x "$source"
      fi

      run mkdir -p "$(dirname "$target")"
      if [ -L "$target" ]; then
        run rm "$target"
      elif [ -e "$target" ]; then
        if [ "$force" != 1 ]; then
          echo "Refusing to replace existing dotfile target without force = true: $target" >&2
          exit 1
        fi
        run rm -rf "$target"
      fi
      if [ "$force" = 1 ]; then
        # A running application may recreate its config between rm and ln.
        # Build the link beside the target, then atomically rename it into place.
        replacement="$target.home-manager-new"
        run rm -rf "$replacement"
        run ln -s "$source" "$replacement"
        run mv -Tf "$replacement" "$target"
      else
        run ln -s "$source" "$target"
      fi
    '';

  renderPreCleanEntry =
    homeTarget: entry:
    let
      force = if entry.force then "1" else "0";
    in
    ''
      target="$HOME/${homeTarget}"
      force=${force}

      if [ -L "$target" ]; then
        run rm "$target"
      elif [ -e "$target" ] && [ "$force" = 1 ]; then
        run rm -rf "$target"
      fi
    '';

  renderConfigEntry = name: entry: renderActivationEntry ".config/${name}" entry;

  renderPreCleanConfigEntry = name: entry: renderPreCleanEntry ".config/${name}" entry;

  renderDataEntry = name: entry: renderActivationEntry ".local/share/${name}" entry;

  renderPreCleanDataEntry = name: entry: renderPreCleanEntry ".local/share/${name}" entry;

  renderFileEntry = name: entry: renderActivationEntry name entry;

  renderPreCleanFileEntry = name: entry: renderPreCleanEntry name entry;

  preCleanScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList renderPreCleanConfigEntry cfg.config
    ++ lib.mapAttrsToList renderPreCleanDataEntry cfg.data
    ++ lib.mapAttrsToList renderPreCleanFileEntry cfg.file
  );

  activationScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList renderConfigEntry cfg.config
    ++ lib.mapAttrsToList renderDataEntry cfg.data
    ++ lib.mapAttrsToList renderFileEntry cfg.file
  );

  dotfilesPython = pkgs.python3.withPackages (pythonPkgs: [
    pythonPkgs.click
  ]);

  dotfilesCli = pkgs.writeShellApplication {
    name = "dotfiles";
    runtimeInputs = with pkgs; [
      openssh
      sops
    ];
    text = ''
      export DOTFILES_ROOT=${lib.escapeShellArg cfg.root}
      exec ${dotfilesPython}/bin/python ${./cli.py} "$@"
    '';
  };
in
{
  options.dotfiles = {
    pure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use Nix store-backed dotfiles instead of live repo symlinks.";
    };

    root = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/nixos";
      description = "Absolute path to the dotfiles repository used for impure symlinks.";
    };

    sourceRoot = lib.mkOption {
      type = lib.types.str;
      default = toString inputs.self;
      description = "Nix source root used to infer repository-relative paths from source.";
    };

    config = lib.mkOption {
      type = lib.types.attrsOf entryType;
      default = { };
      description = "Dotfiles installed below XDG_CONFIG_HOME.";
    };

    data = lib.mkOption {
      type = lib.types.attrsOf entryType;
      default = { };
      description = "Dotfiles installed below XDG_DATA_HOME.";
    };

    file = lib.mkOption {
      type = lib.types.attrsOf entryType;
      default = { };
      description = "Dotfiles installed below HOME.";
    };
  };

  config = {
    home = {
      packages = [ dotfilesCli ];
      file = lib.mkIf cfg.pure (lib.mapAttrs (_: pureAttrs) cfg.file);
      activation = {
        dotfilesPreClean = lib.mkIf (!cfg.pure) (
          lib.hm.dag.entryBefore [ "linkGeneration" ] preCleanScript
        );
        dotfiles = lib.mkIf (!cfg.pure) (lib.hm.dag.entryAfter [ "linkGeneration" ] activationScript);
      };
    };

    xdg.configFile = lib.mkIf cfg.pure (lib.mapAttrs (_: pureAttrs) cfg.config);
    xdg.dataFile = lib.mkIf cfg.pure (lib.mapAttrs (_: pureAttrs) cfg.data);
  };
}
