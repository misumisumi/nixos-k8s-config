{ config, ... }:
{
  boot.initrd = {
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 2222;
        hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
        authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      };
    };
    availableKernelModules = [ "r8169" ];
  };
}
