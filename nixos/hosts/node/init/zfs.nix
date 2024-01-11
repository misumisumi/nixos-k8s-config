{ lib, config, pkgs, ... }:
{
  # system.activationScripts.keygen-for-initrdssh.text = ''
  #   if [ ! -d /etc/secrets/initrd ]; then
  #     mkdir -p /etc/secrets/initrd
  #     ${pkgs.openssh}/bin/ssh-keygen -t rsa -N "" -f /etc/secrets/initrd/ssh_host_rsa_key
  #     ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -N "" -f /etc/secrets/initrd/ssh_host_ed25519_key
  #   fi
  # '';
  boot = {
    initrd.supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelParams = [ "nohibernate" ];
  };
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
    autoSnapshot = {
      enable = true;
      daily = 7;
      flags = "-k -p --utc";
      frequent = 15;
      hourly = 24;
      monthly = 12;
      weekly = 4;
    };
  };
}
