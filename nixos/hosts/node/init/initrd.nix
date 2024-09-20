{ config
, pkgs
, ...
}:
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
    services.unmount-keystore = {
      wantedBy = [ "sysinit.target" ];
      after = [ "local-fs.target" "\x2ekeystore.mount" ];
      requires = [ "\x2ekeystore.mount" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.umount}/bin/umount -R /.keystore";
        ExecStart = "${config.boot.zfs.package}/bin/zfs unload-key PoolRootFS/keystore";
      };
    };
  };
}

