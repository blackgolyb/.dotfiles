{ config, pkgs, system, inputs, ... }:
{
  imports = [
    ./modules/qtile/qtile.nix
      ./modules/zsh/zsh.nix
      ./modules/wezterm/wezterm.nix
      ./modules/nvim/nvim.nix
      ./modules/zed/zed.nix
      ./modules/rofi/rofi.nix
      ./modules/rofi-network-manager/rofi-network-manager.nix
      ./modules/thunar/thunar.nix
      inputs.zen-browser.homeModules.twilight
  ];
# Home Manager needs a bit of information about you and the paths it should
# manage.
  home.username = "blackgolyb";
  home.homeDirectory = "/home/blackgolyb";

# This value determines the Home Manager release that your configuration is
# compatible with. This helps avoid breakage when a new Home Manager release
# introduces backwards incompatible changes.
#
# You should not change this value, even if you update Home Manager. If you do
# want to update the value, then make sure to first check the Home Manager
# release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  services.gnome-keyring.enable = true;
# The home.packages option allows you to install Nix packages into your
# environment.
    nixpkgs.config.allowUnfree = true;
  home.packages = with pkgs; [
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
      pass
      pinentry-curses # gnupg
      gnupg
      bat
      zoxide
      eza
      jq
      fzf
      ripgrep
      brightnessctl # qtile
      pamixer # qtile
      uv
      cloc
      docker
      duf

# TUI
      yazi
      zellij
      lazydocker
      btop
      aider-chat
      wezterm

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
      ytmdesktop
      onlyoffice-desktopeditors
      vokoscreen-ng
      vlc
      flameshot
      baobab
      krita

# Games
      heroic
      prismlauncher
      ];

# Home Manager is pretty good at managing dotfiles. The primary way to manage
# plain files is through 'home.file'.
  home.file = {
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
  home.sessionVariables = {
    SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
    DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    GPG_TTY = "$(tty)";
    EDITOR = "zeditor";
    VISUAL = "zeditor";
    BROWSER = "zen-twilight";
  };
  home.shellAliases = {
    zen = "zen-twilight";
  };

  programs.lazygit = {
      enable = true;
      settings = {
          os = {
              edit = "zeditor -- {{filename}}";
              editAtLine = "zeditor -- {{filename}}:{{line}}";
              editAtLineAndWait = "zeditor --wait -- {{filename}}:{{line}}";
              openDirInEditor = "zeditor -- {{dir}}";
              editInTerminal = false;
          };
      };
  };

  programs.git = {
      enable = true;
      settings = {
          core.editor = "zeditor";
      };
  };

  stylix.targets = {
    zen-browser.enable = false;
  };

# Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    enableSshSupport = false; # optional, if you use GPG for SSH
  };

  programs.zen-browser = {
    enable = true;
  };

  # XDG MIME types configuration
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Browsers / links
      "x-scheme-handler/http" = "zen-twilight.desktop";
      "x-scheme-handler/https" = "zen-twilight.desktop";
      "x-scheme-handler/chrome" = "zen-twilight.desktop";
      "text/html" = "zen-twilight.desktop";
      "application/xhtml+xml" = "zen-twilight.desktop";

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
      "x-scheme-handler/ytmd" = "ytmdesktop.desktop";
      "x-scheme-handler/tonsite" = "org.telegram.desktop.desktop";
      "x-scheme-handler/tg" = "org.telegram.desktop.desktop";
    };
  };
}
