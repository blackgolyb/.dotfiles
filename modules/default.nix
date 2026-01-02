{
  nixosModules.default = {
    lib,
    username,
    ...
  }: {
    imports = [
      ./kanata/kanata.nix
    ];
  };
}
