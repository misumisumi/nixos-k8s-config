{modulesPath, ...}: {
  imports = [
    "${toString modulesPath}/virtualisation/lxc-container.nix"
  ];
  security.polkit.enable = true;
  boot.loader.grub.device = "nodev";
  time.timeZone = "Asia/Tokyo"; # Time zone and internationalisation
}