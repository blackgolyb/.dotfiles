{ config, pkgs, ... }:

let
  mythemes = pkgs.stdenv.mkDerivation {
    pname = "plymouth-mythemes";
    version = "1.7";

    src = ./.;

    installPhase = ''
      # Створюємо базову директорію для всіх тем
      DEST="$out/share/plymouth/themes"
      mkdir -p "$DEST"

      # Копіюємо абсолютно все з вашої локальної папки themes
      cp -r themes/* "$DEST/"

      # Шукаємо всі файли (.plymouth та .script) у всіх підпапках
      # і масово замінюємо /usr/ на актуальний шлях у Nix Store
      find "$DEST" -type f \( -name "*.plymouth" -o -name "*.script" \) -exec sed -i "s@/usr/@$out/@g" {} \;

      # Для налагодження: виведемо список файлів, які ми обробили
      echo "Themes installed in $DEST:"
      ls -R "$DEST"
    '';
  };
in
{
  environment.systemPackages = [
    mythemes
    pkgs.plymouth
  ];

  boot = {
    plymouth = {
      enable = true;
      theme = "loader";
      themePackages = with pkgs; [
        # By default we would install all themes
        (adi1090x-plymouth-themes.override {
          selected_themes = [ "loader" ];
        })
      ];
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;
  };
}
