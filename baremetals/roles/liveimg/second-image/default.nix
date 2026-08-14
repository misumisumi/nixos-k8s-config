{
  inputs,
  lib,
  modulesPath,
  static,
  ...
}:
let
  inherit (lib) mkForce;
  manageIP = lib.removeNetmask static.mngr.image-server.networks.manage.address;
in
{
  imports = [
    ../../share/apps/bash.nix
    ../../share/apps/debug.nix
    ../../share/apps/pkgs.nix
    ../../share/settings/console.nix
    ../../share/settings/locale.nix
    ../../share/settings/security.nix
    ../../share/settings/ssh.nix
    ../../share/settings/system.nix
    ../../share/settings/users.nix
    ../share/ssh.nix
    ./hardware-configuration.nix
    ./network.nix
    ./regist-machine.nix
    inputs.homelab-modules.nixosModules.diskless
  ];
  image.modules = mkForce {
    inherit (inputs.homelab-modules.nixosModules) kexec incus-vm;
    lxc-metadata = modulesPath + "/virtualisation/lxc-image-metadata.nix";
  };

  services.diskless.kexec = {
    enable = true;
    service.enable = false;
    serverURL = "http://${manageIP}/kexec";
    metaJSON = "kexec-images.json";
    useUUID = true;
    fallBackImage = "second-image/nixos-kexec.tar.zst";
  };
}
