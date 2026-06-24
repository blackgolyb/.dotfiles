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

  outputs = { self, nixpkgs, home-manager, stylix, ... }@inputs: 
    let
      system = "x86_64-linux";
      enabled = {
        apps = {
          flameshot.enable = true;
          nvim.enable = true;
          rofi.enable = true;
          rofiNetworkManager.enable = true;
          starship.enable = true;
          thunar.enable = true;
          wezterm.enable = true;
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
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit enabled inputs system; };
        modules = [
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          ./configuration.nix
        ];
      };

      devShells.${system} = {
        node = import ./dev-shells/node.nix { inherit pkgs; };
        python = import ./dev-shells/python.nix { inherit pkgs; };
      };
    };
}
