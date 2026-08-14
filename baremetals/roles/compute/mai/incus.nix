{
  group,
  hostname,
  pkgs,
  static,
  user,
  ...
}:
let
  inherit (static.${group}.${hostname}.bgp) routerId;
  inherit (static.${group}) virtualIPs;
  inherit (static.${group}.${hostname}) networks;
in
{
  services.frr = {
    vrrpd.enable = true;
    config = ''
      interface ${networks.manage.IF}
       vrrp 5 version 3
       vrrp 5 priority 100
       vrrp 5 advertisement-interval 1500
       vrrp 5 ip ${virtualIPs.incus.address}
    '';
  };
  systemd = {
    services.init-incus-cluster = {
      wantedBy = [ "multi-user.target" ];
      wants = [
        "network-online.target"
        "incus.service"
      ];
      after = [
        "network-online.target"
        "incus.service"
      ];
      script = ''
        if [ ! -f /var/lib/incus/cluster.crt ]; then
          ${pkgs.incus}/bin/incus remote add ajisai ${static.${group}.ajisai.bgp.routerId} --accept-certificate
          printf '%s\n' "${routerId}" "${hostname}" yes | ${pkgs.incus}/bin/incus cluster join ajisai:
        fi
      '';
      serviceConfig = {
        ExecStartPre = "${pkgs.curl}/bin/curl -sS --fail --connect-timeout 5 --max-time 10 -o /dev/null http://${
          static.${group}.ajisai.bgp.routerId
        }:8443";
        Restart = "on-failure";
        RestartSec = "10s";
        RestartSteps = "4";
        RestartMaxDelaySec = "160s";
        TimeoutStartSec = "600s";
        User = "${user}";
        Group = "users";
      };
    };
    network = {
      netdevs = {
        vrrp4-incus = {
          netdevConfig = {
            Name = "vrrp4-incus";
            Kind = "macvlan";
            MACAddress = "00:00:5e:00:01:05"; # VRRP MAC address for VRID 5
          };
          macvlanConfig = {
            Mode = "bridge";
          };
        };
      };
      networks = {
        "10-manage".macvlan = [ "vrrp4-incus" ];
        "20-vrrp4-incus" = {
          name = "vrrp4-incus";
          networkConfig = {
            Description = "VRRP for Ajisai";
          };
          address = [ "${virtualIPs.incus.address}/${virtualIPs.incus.cidr}" ];
        };
      };
    };
  };
}
