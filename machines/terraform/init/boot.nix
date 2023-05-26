{modulesPath, ...}: {
  imports = [
    "${toString modulesPath}/virtualisation/lxc-container.nix"
  ];

  # fileSystems."/" = {
  #   device = "/dev/disk/by-label/nixos";
  #   fsType = "ext4";
  #   autoResize = true;
  # };

  # boot.growPartition = true;
  # boot.kernelParams = ["console=ttyS0"];
  # boot.loader.grub.device = "/dev/vda";
  security.polkit.enable = true;
  boot.loader.grub.device = "nodev";
}