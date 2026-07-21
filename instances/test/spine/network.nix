{ inputs, ... }:
let
  routerId = "10.10.10.10";
in
{
  imports = [
    inputs.homelab-modules.nixosModules.vlan-aware-vxlan
  ];
  networking = {
    useNetworkd = true;
    firewall.enable = false;
  };
  systemd.network = {
    enable = true;
    netdevs = {
      lo0 = {
        netdevConfig = {
          Name = "lo0";
          Kind = "dummy";
        };
      };
    };
    networks = {
      "5-lo0" = {
        name = "lo0";
        address = [
          "${routerId}/32"
        ];
      };
      "15-enp5s0" = {
        name = "enp5s0";
      };
    };
  };
}
