{
  description = "Nixos config flake";

  nixConfig = {
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
  };

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
    pineconemc = {
      url = "github:ElyPrismLauncher/Launcher";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kotlin-lsp = {
      url = "git+https://tangled.org/bpavuk.neocities.org/kotlin-lsp-flake";
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
    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      stylix,
      sops-nix,
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
          sops-nix.nixosModules.sops
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          ./configuration.nix
        ];
      };

      formatter.${system} = dotfilesDevShell.formatter;

      packages.${system}.kotlin-lsp = inputs.kotlin-lsp.packages.${system}.default;

      checks.${system} = dotfilesDevShell.checks;

      devShells.${system} = {
        default = dotfilesDevShell.shell;
        dotfiles = dotfilesDevShell.shell;
        node = import ./dev-shells/node.nix { inherit pkgs; };
        python = import ./dev-shells/python.nix { inherit pkgs; };
      };
    };
}
