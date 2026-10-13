{
  self,
  lib,
  inputs,
  isDev,
  isNixOSTest,
  user,
  static,
  ...
}:
{
  systemd.network = {
    netdevs = {
      br_router2host = {
        netdevConfig = {
          Name = "br_router2host";
          Kind = "bridge";
          Description = "Bridge for border router VM to host";
        };
      };
      br_home2host = {
        netdevConfig = {
          Name = "br_home2host";
          Kind = "bridge";
          Description = "Bridge for home leaf VM to host";
        };
      };
    };
    networks = {
      # BGP unnumbered の underlay リンク (15- 接頭辞は bgp.nix が自動で LEAF ピア化)
      "15-br_router2host" = {
        name = "br_router2host";
      };
      "15-br_home2host" = {
        name = "br_home2host";
      };
      "16-router2host-network" = {
        bridge = [ "br_router2host" ];
        matchConfig = {
          Name = [ "vm_router2host" ];
        };
      };
      "16-home2host-network" = {
        bridge = [ "br_home2host" ];
        matchConfig = {
          Name = [ "vm_home2host" ];
        };
      };
    };
  };
  microvm.vms = {
    border-router = import ./border-router {
      inherit
        self
        lib
        inputs
        isDev
        isNixOSTest
        user
        static
        ;
    };
    home-leaf = import ./home-leaf {
      inherit
        self
        lib
        inputs
        isDev
        isNixOSTest
        user
        static
        ;
    };
  };
}
