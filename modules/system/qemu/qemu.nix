{ config, lib, pkgs, ... }:

let
  cfg = config.my.system.qemu;
in
{
  options.my.system.qemu.enable = lib.mkEnableOption "QEMU/libvirt";

  config = lib.mkIf cfg.enable {
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  virtualisation.spiceUSBRedirection.enable = true;

  programs.virt-manager.enable = true;

  users.users.blackgolyb.extraGroups = [ "libvirtd" "kvm" ];

  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice-gtk
    virtio-win
    win-spice
  ];
  };
}
