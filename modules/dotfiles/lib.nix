{ config, lib }:

rec {
  dotfileTarget = optionPath: target: path: pureSource: attrs:
    let
      activationName = "dotfile-${lib.replaceStrings [ "/" "." " " ] [ "-" "-" "-" ] target}";
      source = "${config.dotfiles.root}/${path}";
      force = if attrs.force or false then "1" else "0";
    in
    lib.mkMerge [
      (lib.mkIf config.dotfiles.pure (
        lib.setAttrByPath optionPath (attrs // { source = pureSource; })
      ))
      (lib.mkIf (!config.dotfiles.pure) {
        home.activation.${activationName} = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          target="$HOME/${target}"
          source=${lib.escapeShellArg source}
          force=${force}

          if [ ! -e "$source" ] && [ ! -L "$source" ]; then
            echo "Missing dotfile source: $source" >&2
            exit 1
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
      })
    ];

  dotfileFile = target: dotfileTarget [ "home" "file" target ] target;
  dotfileConfig = target: dotfileTarget [ "xdg" "configFile" target ] ".config/${target}";
  dotfileData = target: dotfileTarget [ "xdg" "dataFile" target ] ".local/share/${target}";
}
