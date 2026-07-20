{
  config,
  pkgs,
  system,
  enabled,
  inputs,
  ...
}:
{
  imports = [
    ./modules/core/dotfiles/dotfiles.nix
    ./modules/apps/copy-to-clipboard
    ./modules/apps/flameshot
    ./modules/apps/glide
    ./modules/apps/lazygit
    ./modules/apps/nvim
    ./modules/apps/opencode
    ./modules/apps/openwhispr
    ./modules/apps/pass
    ./modules/apps/rofi
    ./modules/apps/rofi-network-manager
    ./modules/apps/secrets
    ./modules/apps/starship
    ./modules/apps/ssh
    ./modules/apps/thunar
    ./modules/apps/tmux
    ./modules/apps/wezterm
    ./modules/apps/zed
    ./modules/apps/zen
    ./modules/apps/zsh
    ./modules/de/hyprland
    ./modules/de/qtile
    inputs.sops-nix.homeManagerModules.sops
  ];

  # TODO: remove this after fix on mongodb-compass side
  nixpkgs.overlays = [
    (_: prev: {
      mongodb-compass = prev.mongodb-compass.overrideAttrs (old: {
        buildCommand =
          builtins.replaceStrings
            [ "wrapGAppsHook $out/bin/mongodb-compass" ]
            [ "wrapGApp $out/bin/mongodb-compass" ]
            old.buildCommand;
      });
    })
  ];

  home = {
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    username = "blackgolyb";
    homeDirectory = "/home/blackgolyb";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.11"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
      # # Adds the 'hello' command to your environment. It prints a friendly
      # # "Hello, world!" when run.
      # pkgs.hello

      # # It is sometimes useful to fine-tune packages, for example, by applying
      # # overrides. You can do that directly here, just don't forget the
      # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
      # # fonts?
      # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

      # # You can also create simple shell scripts directly inside your
      # # configuration. For example, this adds a command 'my-hello' to your
      # # environment:
      # (pkgs.writeShellScriptBin "my-hello" ''
      #   echo "Hello, ${config.home.username}!"
      # '')

      # CLI
      pinentry-curses # gnupg
      gnupg
      bat
      zoxide
      eza
      file
      jq
      just
      fzf
      ripgrep
      brightnessctl # qtile
      pamixer # qtile
      cloc
      duf
      devbox
      gh

      # TUI
      yazi
      zellij
      lazydocker
      btop
      wezterm
      codex

      # Programs
      xcolor
      telegram-desktop
      blueman # qtile
      pavucontrol # qtile
      feh
      sioyek
      anki
      chromium
      logseq
      super-productivity
      firefox-devedition
      mongodb-compass
      pear-desktop
      onlyoffice-desktopeditors
      vokoscreen-ng
      vlc
      baobab
      krita

      # Games
      heroic
      prismlauncher
    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    file = {
      # # Building this configuration will create a copy of 'dotfiles/screenrc' in
      # # the Nix store. Activating the configuration will then make '~/.screenrc' a
      # # symlink to the Nix store copy.
      # ".screenrc".source = dotfiles/screenrc;

      # # You can also set the file content immediately.
      # ".gradle/gradle.properties".text = ''
      #   org.gradle.console=verbose
      #   org.gradle.daemon.idletimeout=3600000
      # '';
    };

    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. These will be explicitly sourced when using a
    # shell provided by Home Manager. If you don't want to manage your shell
    # through Home Manager then you have to manually source 'hm-session-vars.sh'
    # located at either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/blackgolyb/etc/profile.d/hm-session-vars.sh
    #
    sessionVariables = {
      SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
      GPG_TTY = "$(tty)";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
  };

  dotfiles.pure = false;

  my = {
    inherit (enabled) apps de;
  };

  services = {
    gnome-keyring.enable = true;

    gpg-agent = {
      enable = true;
      pinentry.package = pkgs.pinentry-curses;
      enableSshSupport = false; # optional, if you use GPG for SSH
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "electron-39.8.10"
    ];
  };
  programs = {
    git = {
      enable = true;
      settings = {
        push.autoSetupRemote = true;
        core.editor = "nvim";
      };
    };

    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    gpg.enable = true;
  };

  # XDG MIME types configuration
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # PDF
      "application/pdf" = "sioyek.desktop";

      # Text & Programming
      "text/plain" = "dev.zed.Zed.desktop";
      "text/markdown" = "dev.zed.Zed.desktop";
      "text/x-python" = "dev.zed.Zed.desktop";
      "text/x-rust" = "dev.zed.Zed.desktop";
      "text/x-go" = "dev.zed.Zed.desktop";
      "text/x-java" = "dev.zed.Zed.desktop";
      "text/x-csrc" = "dev.zed.Zed.desktop";
      "text/x-c++src" = "dev.zed.Zed.desktop";
      "text/x-shellscript" = "dev.zed.Zed.desktop";
      "application/json" = "dev.zed.Zed.desktop";
      "application/javascript" = "dev.zed.Zed.desktop";
      "application/xml" = "dev.zed.Zed.desktop";
      "application/toml" = "dev.zed.Zed.desktop";
      "text/x-yaml" = "dev.zed.Zed.desktop";
      "text/x-toml" = "dev.zed.Zed.desktop";

      # Images
      "image/png" = "feh.desktop";
      "image/jpeg" = "feh.desktop";
      "image/webp" = "feh.desktop";
      "image/gif" = "feh.desktop";
      "image/bmp" = "feh.desktop";
      "image/tiff" = "feh.desktop";
      "image/svg+xml" = "feh.desktop";

      # Video
      "video/mp4" = "vlc.desktop";
      "video/x-matroska" = "vlc.desktop";
      "video/webm" = "vlc.desktop";
      "video/x-msvideo" = "vlc.desktop";
      "video/mpeg" = "vlc.desktop";
      "video/quicktime" = "vlc.desktop";

      # Audio
      "audio/mpeg" = "vlc.desktop";
      "audio/ogg" = "vlc.desktop";
      "audio/wav" = "vlc.desktop";
      "audio/flac" = "vlc.desktop";
      "audio/mp4" = "vlc.desktop";
      "audio/webm" = "vlc.desktop";

      # Archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-rar" = "org.gnome.FileRoller.desktop";
      "application/x-tar" = "org.gnome.FileRoller.desktop";
      "application/x-bzip" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2" = "org.gnome.FileRoller.desktop";
      "application/x-gzip" = "org.gnome.FileRoller.desktop";
      "application/x-xz" = "org.gnome.FileRoller.desktop";
      "application/x-compress" = "org.gnome.FileRoller.desktop";
      "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-bzip-compressed-tar" = "org.gnome.FileRoller.desktop";
      "application/x-lzip" = "org.gnome.FileRoller.desktop";
      "application/x-lzma" = "org.gnome.FileRoller.desktop";
      "application/x-lzop" = "org.gnome.FileRoller.desktop";

      # File manager
      "inode/directory" = "thunar.desktop";

      # App handlers
      "x-scheme-handler/logseq" = "Logseq.desktop";
      "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
    };
  };
}
