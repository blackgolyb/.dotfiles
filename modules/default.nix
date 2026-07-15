{
  nixosModules.default =
    {
      lib,
      username,
      ...
    }:
    {
      imports = [
        ./hardware/kanata/kanata.nix
      ];
    };
}
