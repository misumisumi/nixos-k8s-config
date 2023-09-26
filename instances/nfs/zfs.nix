{ config, hostID, ... }:
{
  networking = {
    useDHCP = true;
    hostId = hostID;
  };
  boot = {
    supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelModules = [ "nohibernate" ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
    zfs = {
      requestEncryptionCredentials = [ "nixos" ];
      forceImportRoot = false;
    };
    initrd = {
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ /root/.ssh/id_ed25519 /root/.ssh/id_rsa ];
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
        };
      };
      availableKernelModules = [ "r8169" ];
    };
  };
  services.zfs = {
    trim.enable = true;
    autoScrub.enable = true;
    autoSnapshot = {
      enable = false;
    };
  };
}