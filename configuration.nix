# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/kanata/kanata.nix
      ./modules/plymouth/plymouth.nix
    ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  # Set your time zone.
  time.timeZone = "Europe/Kyiv";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "uk_UA.UTF-8";
    LC_IDENTIFICATION = "uk_UA.UTF-8";
    LC_MEASUREMENT = "uk_UA.UTF-8";
    LC_MONETARY = "uk_UA.UTF-8";
    LC_NAME = "uk_UA.UTF-8";
    LC_NUMERIC = "uk_UA.UTF-8";
    LC_PAPER = "uk_UA.UTF-8";
    LC_TELEPHONE = "uk_UA.UTF-8";
    LC_TIME = "uk_UA.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  services.xserver.enable = true;
  services.xserver.windowManager.qtile = {
    enable = true;
    # package = pkgs.python312.pkgs.qtile;
    extraPackages = python3Packages: with python3Packages; [
      qtile-extras
      requests
    ];
  };

  services.xserver.displayManager.lightdm = {
    enable = true;
    greeters.mini = {
      enable = true;
      user = "blackgolyb";
      extraConfig = ''
        [greeter]
        show-password-label = false
        password-alignment = left

        [greeter-theme]
        # The font to use for all text
        font = "Sans"
        # The font size to use for all text
        font-size = 1em
        # The font weight to use for all text
        font-weight = bold
        # The font style to use for all text
        font-style = normal
        # The default text color
        text-color = "#ffffff"
        # The color of the error text
        error-color = "#dc4358"
        # An absolute path to an optional background image.
        background-image = ""
        # Background image size:
        background-image-size = cover
        # The screen's background color.
        background-color = "#2e3440"
        # The password window's background color
        window-color = "#2e3440"
        # The color of the password window's border
        border-color = "#dc4358"
        # The width of the password window's border.
        border-width = 2px
        # The pixels of empty space around the password input.
        layout-space = 15
        # The character used to mask your password.
        password-character = -1
        # The color of the text in the password input.
        password-color = "#ffffff"
        # The background color of the password input.
        password-background-color = "#2e3440"
        # The color of the password input's border.
        password-border-color = "#dc4358"
        # The width of the password input's border.
        password-border-width = 1px
        # The border radius of the password input.
        password-border-radius = 0.5em
        # Override font for system info
        sys-info-font = "Mono"
        # Set font size of system info
        sys-info-font-size = 0.8em
        # Override color for system info text
        sys-info-color = "#ffffff"
        # Margins around the system info section
        sys-info-margin = -5px -5px 0px
      '';
    };
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.lightdm.enableGnomeKeyring = true;

  services.dbus.enable = true;

  stylix = {
    enable = true;

    base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark-dark.yaml";

    icons = {
      enable = true;
      package = pkgs.dracula-icon-theme;
      dark = "Dracula";
      light = "Dracula";
    };

    cursor = {
        name = "Nordzy-cursors";
        package = pkgs.nordzy-cursor-theme;
        size = 24;
      };

    polarity = "dark";

    targets = {
	    plymouth.enable = false;
    };
  };

  programs.zsh.enable = true;
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.blackgolyb = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "blackgolyb";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
     gnome-keyring # сам демон
     libsecret     # бібліотека для програм (Zed, VS Code, Discord)
     # 
     vim
     git
     zsh
     wget
     dracula-icon-theme
     nordzy-cursor-theme
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    localNetworkGameTransfers.openFirewall = true; # Open ports in the firewall for Steam Local Network Game Transfers
  };


  home-manager = {
    # also pass inputs to home-manager modules
    extraSpecialArgs = {inherit inputs;};
    backupFileExtension = "backup";
    users = {
      "blackgolyb" = import ./home.nix;
    };
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  boot.loader.systemd-boot.configurationLimit = 5;


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  # Enable the uinput module
  boot.kernelModules = [ "uinput" ];

  # Enable uinput
  hardware.uinput.enable = true;

  # Set up udev rules for uinput
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  # Ensure the uinput group exists
  users.groups.uinput = { };

  # Add the Kanata service user to necessary groups
   systemd.services.kanata-internalKeyboard.serviceConfig = {
     SupplementaryGroups = [
       "input"
       "uinput"
     ];
   };

}
