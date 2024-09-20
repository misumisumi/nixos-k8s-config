{ lib, pkgs, user, group, ... }: {
  users.groups = {
    incus-admin.members = [ "root" "${user}" ];
    kvm.members = [ "root" "${user}" ];
  };
  environment.systemPackages = with pkgs; [ lxd-to-incus ];
  virtualisation = {
    incus = {
      enable = true;
      startTimeout = 300;
      preseed = {
        config = {
          "core.https_address" = ":8443";
        };
        networks = [
          {
            description = "Default Incus network";
            config = {
              "ipv4.address" = "10.0.100.1/24";
              "ipv4.nat" = "true";
            };
            name = "incusbr0";
            type = "bridge";
          }
        ];
        profiles = [
          {
            description = "Default Incus profile";
            devices = {
              eth0 = {
                "name" = "eth0";
                "nictype" = "bridged";
                "parent" = "incusbr0";
                "type" = "nic";
              };
              root = {
                "path" = "/";
                "pool" = "default";
                "type" = "disk";
              };
            };
            name = "default";
          }
        ];
        storage_pools = [
          ({
            name = "default";
            description = "Default Incus storage";
          } // lib.optionalAttrs
            (group == "devnode")
            {
              driver = "dir";
            }
          // lib.optionalAttrs
            (group != "devnode")
            {
              driver = "btrfs";
              config = {
                size = "8GiB";
                source = "/var/lib/incus/disks/default.img";
              };
            }
          )
        ];
      };
    };
  };
}
