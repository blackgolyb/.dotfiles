{ config, lib, ... }:

let
  cfg = config.dotfiles;

  entryType = lib.types.submodule {
    options = {
      path = lib.mkOption {
        type = lib.types.str;
        description = "Path relative to dotfiles.root used for impure symlinks.";
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

  pureAttrs = entry:
    entry.attrs
    // { source = entry.source; }
    // lib.optionalAttrs entry.recursive { recursive = true; }
    // lib.optionalAttrs entry.executable { executable = true; }
    // lib.optionalAttrs entry.force { force = true; };

  renderActivationEntry = homeTarget: entry:
    let
      source = "${cfg.root}/${entry.path}";
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
      run ln -s "$source" "$target"
    '';

  renderConfigEntry = name: entry:
    renderActivationEntry ".config/${name}" entry;

  renderDataEntry = name: entry:
    renderActivationEntry ".local/share/${name}" entry;

  renderFileEntry = name: entry:
    renderActivationEntry name entry;

  activationScript = lib.concatStringsSep "\n" (
    lib.mapAttrsToList renderConfigEntry cfg.config
    ++ lib.mapAttrsToList renderDataEntry cfg.data
    ++ lib.mapAttrsToList renderFileEntry cfg.file
  );
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
    xdg.configFile = lib.mkIf cfg.pure (lib.mapAttrs (_: pureAttrs) cfg.config);
    xdg.dataFile = lib.mkIf cfg.pure (lib.mapAttrs (_: pureAttrs) cfg.data);
    home.file = lib.mkIf cfg.pure (lib.mapAttrs (_: pureAttrs) cfg.file);

    home.activation.dotfiles = lib.mkIf (!cfg.pure) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] activationScript
    );
  };
}
