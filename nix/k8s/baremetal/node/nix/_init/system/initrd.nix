{ config, ... }:
{
  boot = {
    initrd = {
      network = {
        enable = true;
        udhcpc.enable = true;
        ssh = {
          enable = true;
          port = 2222;
          hostKeys = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
        };
      };
      # r8169 is realtek, igb and e1000e is intel Gigabit Ethernet driver
      availableKernelModules = [
        "r8169"
        "igb"
        "e1000e"
      ];
    };
  };
}
