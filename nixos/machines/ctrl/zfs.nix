{ lib, config, ... }:
{
  networking = {
    useDHCP = true;
    hostId = "d8280a53";
  };
  boot = {
    supportedFilesystems = [ "zfs" ];
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    kernelModules = [ "nohibernate" ];
    extraModprobeConfig = ''
      options zfs zfs_arc_max=4294967296
    '';
    zfs = {
      requestEncryptionCredentials = [ "system" ];
      forceImportRoot = false;
    };
    initrd = {
      network = {
        enable = true;
        postCommands = lib.mkBefore ''
          mkdir -p /etc/secrets/initrd
        '';
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
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
