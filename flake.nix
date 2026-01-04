{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = {self, nixpkgs, home-manager, stylix, ... }@inputs:{
    # use "nixos", or your hostname as the name of the configuration
    # it's a better practice than "default" shown in the video
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; system = "x86_64-linux"; };
      modules = [
        stylix.nixosModules.stylix
        home-manager.nixosModules.home-manager
        ./configuration.nix
      ];
    };

    # homeConfigurations.blackgolyb = home-manager.lib.homeManagerConfiguration {
    #   pkgs = nixpkgs.legacyPackages.x86_64-linux // {
    #     config = { allowUnfree = true; };
    #   };
    #   modules = [
    #     ./home.nix
    #   ];
    # };
  };
}
