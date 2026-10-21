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
  boot = {
    kernelParams = [
      "intel_iommu=on"
      "iommu=pt"
    ];
    kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];
  };
  systemd.network = {
    netdevs = {
      br_router2host = {
        netdevConfig = {
          Name = "br_router2host";
          Kind = "bridge";
          Description = "Bridge for border router VM to host";
          MTUBytes = static.microvm.borderRouter.mtu;
        };
      };
      br_home2host = {
        netdevConfig = {
          Name = "br_home2host";
          Kind = "bridge";
          Description = "Bridge for home leaf VM to host";
          MTUBytes = static.microvm.homeLeaf.mtu;
        };
      };
      br_svc2host = {
        netdevConfig = {
          Name = "br_svc2host";
          Kind = "bridge";
          Description = "Bridge for svc leaf VM to host";
          MTUBytes = static.microvm.svcLeaf.mtu;
        };
      };
    };
    networks = {
      # BGP unnumbered の underlay リンク (15- 接頭辞は bgp.nix が自動で LEAF ピア化)
      "15-br_router2host" = {
        name = "br_router2host";
        linkConfig = {
          MTUBytes = static.microvm.borderRouter.mtu;
        };
      };
      "15-br_home2host" = {
        name = "br_home2host";
        linkConfig = {
          MTUBytes = static.microvm.homeLeaf.mtu;
        };
      };
      "15-br_svc2host" = {
        name = "br_svc2host";
        linkConfig = {
          MTUBytes = static.microvm.svcLeaf.mtu;
        };
      };
      "16-router2host-network" = {
        bridge = [ "br_router2host" ];
        matchConfig = {
          Name = [ "vm_router2host" ];
        };
        linkConfig = {
          MTUBytes = static.microvm.borderRouter.mtu;
        };
      };
      "16-home2host-network" = {
        bridge = [ "br_home2host" ];
        matchConfig = {
          Name = [ "vm_home2host" ];
        };
        linkConfig = {
          MTUBytes = static.microvm.homeLeaf.mtu;
        };
      };
      "16-svc2host-network" = {
        bridge = [ "br_svc2host" ];
        matchConfig = {
          Name = [ "vm_svc2host" ];
        };
        linkConfig = {
          MTUBytes = static.microvm.svcLeaf.mtu;
        };
      };
    };
  };
  # home-leaf の 40G macvtap (vm_leaf2home40g) は mlx4_en の enp2s0d1 を親に
  # する。NIC の出現が macvtap service より遅れると "Cannot find device"
  # で失敗するため、device unit の出現を待ってから作成する。
  systemd.services."microvm-macvtap-interfaces@home-leaf" = {
    overrideStrategy = "asDropin";
    wants = [ "sys-subsystem-net-devices-enp2s0d1.device" ];
    after = [ "sys-subsystem-net-devices-enp2s0d1.device" ];
  };
  microvm.vms = {
    # border-router = import ./border-router {
    #   inherit
    #     self
    #     lib
    #     inputs
    #     isDev
    #     isNixOSTest
    #     user
    #     static
    #     ;
    # };
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
    svc-leaf = import ./svc-leaf {
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
