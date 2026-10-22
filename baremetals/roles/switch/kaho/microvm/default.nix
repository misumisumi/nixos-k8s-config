{
  self,
  lib,
  inputs,
  pkgs,
  config,
  isDev,
  isNixOSTest,
  user,
  static,
  ...
}:
{
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen; # Inclouding ACS override patch
    kernelParams = [
      "pci=realloc"
      "intel_iommu=on"
      "iommu=pt"
      "vfio-pci.ids=15b3:1004,15b3:1003,8086:10fb" # connectx-3-pro's SR-IOV VF (2nd Slot PCIe Slot's Card)
      "pcie_acs_override=downstream,multifunction" # ACS override
    ];
    kernelModules = [
      "vfio"
      "vfio_iommu_type1"
      "vfio_pci"
    ];
    extraModprobeConfig = ''
      options mlx4_core num_vfs=1,1,0 probe_vf=0,0,0
    '';
  };
  # mlx4_core は PF の probe 中に VF を生成するため、sysinit.target 直後に
  # 走る microvm-pci-devices@ では VF の sysfs がまだ存在しないことがある
  # (実測: pci-setup 08:54:29 / VF 0000:02:00.2 生成 08:54:38)。
  # VF には netdev が無く .device ユニットも作られないため、
  # pci-setup の実行前に sysfs をポーリングして待つ。
  systemd.services = lib.mkMerge (
    lib.mapAttrsToList (
      name: vm:
      let
        guestConfig = if vm.evaluatedConfig != null then vm.evaluatedConfig.config else vm.config.config;
        pciDevices = builtins.filter (d: d.bus == "pci") guestConfig.microvm.devices;
      in
      lib.optionalAttrs (pciDevices != [ ]) {
        "microvm-pci-devices@${name}" = {
          overrideStrategy = "asDropin";
          serviceConfig.ExecStartPre = [
            (pkgs.writeShellScript "wait-pci-devices" ''
              set -eu
              for d in ${lib.concatStringsSep " " (map (d: d.path) pciDevices)}; do
                i=0
                until [ -e "/sys/bus/pci/devices/$d" ]; do
                  i=$((i + 1))
                  if [ "$i" -ge 300 ]; then
                    echo "timed out waiting for PCI device $d" >&2
                    exit 1
                  fi
                  sleep 1
                done
              done
            '')
          ];
        };
      }
    ) config.microvm.vms
    ++ [
      # home-leaf の 40G macvtap (vm_leaf2hm40g) は mlx4_en の enp2s0d1 を親に
      # する。NIC の出現が macvtap service より遅れると "Cannot find device"
      # で失敗するため、device unit の出現を待ってから作成する。
      {
        "microvm-macvtap-interfaces@home-leaf" = {
          overrideStrategy = "asDropin";
          wants = [ "sys-subsystem-net-devices-enp2s0d1.device" ];
          after = [ "sys-subsystem-net-devices-enp2s0d1.device" ];
        };
      }
    ]
  );
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
