{ config
, pkgs
, tag
, ...
}:
let
  pwd = /. + builtins.getEnv "PWD";
  getKeys = filenames: builtins.filter builtins.pathExists filenames;

  hostKeys = getKeys [
    "/etc/secrets/${tag}/initrd/ssh_host_ed25519_key"
    "/etc/secrets/${tag}/initrd/ssh_host_rsa_key"
  ];
in
{
  boot = {
    initrd = {
      network = {
        enable = true;
        udhcpc.enable = true;
        ssh = {
          enable = true;
          port = 2222;
          inherit hostKeys;
          authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
        };
        postCommands = ''
          zpool import -a
          echo "zfs load-key -a; killall zfs; exit 0" >> /root/.profile
        '';
      };
      # r8169 is realtek, igb and e1000e is intel Gigabit Ethernet driver
      availableKernelModules = [ "r8169" "igb" "e1000e" ];
    };
  };
  systemd = {
    services.unload-zfs = {
      requiredBy = [ "cryptsetup.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = "yes";
        ExecStartPre = "${pkgs.umount}/bin/umount -R /.keystore";
        ExecStart = "${config.boot.zfs.package}/bin/zfs unload-key PoolRootFS/keystore";
      };
    };
  };
}
