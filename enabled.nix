{ lib }:

let
  requested = {
    apps = {
      nvim.enable = true;
      pass.enable = true;
      ssh.enable = true;
      tmux.enable = true;
      zed.enable = true;
      zsh.enable = true;
    };

    de = {
      hyprland.enable = true;
      qtile.enable = true;
    };

    hardware.kanata.enable = true;

    system = {
      plymouth.enable = true;
      qemu.enable = true;
    };
  };

  moduleRoots = {
    apps = ./modules/apps;
    de = ./modules/de;
    hardware = ./modules/hardware;
    system = ./modules/system;
  };

  kebabToCamel = name:
    let
      parts = lib.splitString "-" name;
      capitalize = part:
        let
          chars = lib.stringToCharacters part;
        in
        if chars == [ ] then "" else lib.concatStrings ([ (lib.toUpper (lib.head chars)) ] ++ lib.tail chars);
    in
    lib.concatStrings ([ (lib.head parts) ] ++ map capitalize (lib.tail parts));

  depsForRoot = kind: root:
    lib.flatten (
      lib.mapAttrsToList
        (name: type:
          let
            dir = root + "/${name}";
            depsFile = dir + "/deps.nix";
          in
          if type == "directory" && builtins.pathExists depsFile then [
            {
              path = [ kind (kebabToCamel name) ];
              deps = import depsFile;
            }
          ] else [ ])
        (builtins.readDir root)
    );

  dependencyModules = lib.flatten (
    lib.mapAttrsToList depsForRoot moduleRoots
  );

  isEnabled = enabledSet: path:
    lib.attrByPath (path ++ [ "enable" ]) false enabledSet;

  depsFor = enabledSet:
    lib.foldl'
      (acc: module:
        if isEnabled enabledSet module.path then
          lib.recursiveUpdate acc module.deps
        else
          acc)
      { }
      dependencyModules;

  resolveEnabled = enabledSet:
    let
      next = lib.recursiveUpdate (depsFor enabledSet) enabledSet;
    in
    if next == enabledSet then next else resolveEnabled next;
in
resolveEnabled requested
