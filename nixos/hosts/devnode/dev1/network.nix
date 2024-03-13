{ lib
, hostname
, tag
, ...
}:
let
  interfaceName = "enp1s0";
  inherit (import ../../../../utils/hosts.nix { inherit tag; }) ipv4_address hosts;
  inherit (hosts.${tag}) dns gateway;
in
{
  services = {
    nscd = {
      enable = true;
    };
  };
  boot.initrd.network.udhcpc.extraArgs = [
    "-i"
    "${interfaceName}"
  ];
  networking = {
    hostName = "${hostname}";
    interfaces.${interfaceName}.wakeOnLan.enable = true;
    firewall = {
      enable = true;
      trustedInterfaces = [
        "br0"
      ];
    };
  };

  systemd = {
    network = {
      netdevs = {
        "br0".netdevConfig = {
          Kind = "bridge";
          Name = "br0";
          MACAddress = "71:9a:a2:fa:05:${toString(90 + lib.toInt (lib.removePrefix "dev" tag))}";
        };
      };
      networks = {
        "10-wired" = {
          name = interfaceName;
          bridge = [ "br0" ];
        };
        "20-br0" = {
          name = "br0";
          DHCP = "yes";
          address = [ "${ipv4_address}/24" ];
          dns = [ dns ];
          gateway = [ gateway ];
        };
      };
    };
  };
}
