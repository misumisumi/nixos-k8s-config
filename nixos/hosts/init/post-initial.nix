{ config, ... }:
{
  boot = {
    # r8169 is realtek, igb is intel Gigabit Ethernet driver
    kernelModules = [ "r8169" "igb" ];
    initrd = {
      systemd.enable = true;
      network = {
        enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/etc/secrets/initrd/ssh_host_rsa_key" "/etc/secrets/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
        };
      };
      kernelModules = [ "r8169" "igb" ];
    };
  };
}
