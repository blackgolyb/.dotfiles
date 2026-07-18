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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openwhispr = {
      url = "github:OpenWhispr/openwhispr";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    glide-browser = {
      url = "github:glide-browser/glide.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      stylix,
      treefmt-nix,
      git-hooks,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
      enabled = import ./enabled.nix { inherit lib; };
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      dotfilesDevShell = import ./dev-shells/dotfiles.nix {
        inherit
          pkgs
          system
          treefmt-nix
          git-hooks
          ;
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit enabled inputs system; };
        modules = [
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          ./configuration.nix
        ];
      };

      formatter.${system} = dotfilesDevShell.formatter;

      checks.${system} = dotfilesDevShell.checks;

      devShells.${system} = {
        default = dotfilesDevShell.shell;
        dotfiles = dotfilesDevShell.shell;
        node = import ./dev-shells/node.nix { inherit pkgs; };
        python = import ./dev-shells/python.nix { inherit pkgs; };
      };
    };
}
