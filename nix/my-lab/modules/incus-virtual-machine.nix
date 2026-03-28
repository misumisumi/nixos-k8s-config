{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  serialDevice = if pkgs.stdenv.hostPlatform.isx86 then "ttyS0" else "ttyAMA0";
in

{
  disabledModules = [ "virtualisation/incus-virtual-machine.nix" ];
  imports = [
    (modulesPath + "/installer/cd-dvd/channel.nix")
    (modulesPath + "/profiles/clone-config.nix")
    (modulesPath + "/profiles/minimal.nix")

    (modulesPath + "/profiles/qemu-guest.nix")
    (modulesPath + "/image/file-options.nix")
  ];
  config = rec {
    #NOTE: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/virtualisation/incus-virtual-machine.nix
    system.build.qemuImage = import (modulesPath + "/../lib/make-disk-image.nix") {
      inherit pkgs lib config;

      partitionTableType = "efi";
      format = "qcow2-compressed";
      copyChannel = config.system.installer.channel.enable;
    };
    system.build.image = system.build.qemuImage;
    image.filePath = "nixos.qcow2";

    fileSystems = {
      "/" = {
        device = "/dev/disk/by-label/nixos";
        autoResize = true;
        fsType = "ext4";
      };
      "/boot" = {
        device = "/dev/disk/by-label/ESP";
        fsType = "vfat";
      };
    };

    boot.growPartition = true;
    boot.loader.systemd-boot.enable = true;

    # image building needs to know what device to install bootloader on
    boot.loader.grub.device = "/dev/vda";

    boot.kernelParams = [
      "console=tty1"
      "console=${serialDevice}"
    ];

    # CPU hotplug
    services.udev.extraRules = ''
      SUBSYSTEM=="cpu", CONST{arch}=="x86-64", TEST=="online", ATTR{online}=="0", ATTR{online}="1"
    '';

    virtualisation.incus.agent.enable = lib.mkDefault true;

    #NOTE: https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/virtualisation/lxc-instance-common.nix
    # Allow the user to login as root without password.
    users.users.root.initialHashedPassword = lib.mkOverride 150 "";

    # Some more help text.
    services.getty.helpLine = ''

      Log in as "root" with an empty password.
    '';

    # Containers should be light-weight, so start sshd on demand.
    services.openssh.enable = lib.mkDefault true;
    services.openssh.startWhenNeeded = lib.mkDefault true;

    # friendlier defaults than minimal profile provides
    # but we can't use mkDefault since minimal uses it
    documentation.enable = lib.mkOverride 890 true;
    documentation.nixos.enable = lib.mkOverride 890 true;
    services.logrotate.enable = true;
  };
}
