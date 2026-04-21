{ pkgs, ... }:
{
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
}
