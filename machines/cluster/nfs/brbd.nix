{ lib
, pkgs
, resourcesByRole
, ...
}:
let
  _nfsHosts = lib.flatten (map
    (r:
      map
        (d:
          if d.type == "disk"
          then {
            inherit (r.values) name ip_address;
            inherit (d.properties) path;
            id = lib.removePrefix "nfs" r.values.name;
          }
          else [ ])
        r.values.device)
    (resourcesByRole "nfs"));
  nfsHosts =
    map
      (v: ''
        on "${v.name}" {
          disk "${v.path}";
          address ${v.ip_address}:7788;
        }
      '')
      _nfsHosts;
in
{
  networking.firewall.allowedTCPPorts = [ 7788 ];
  services.drbd = {
    enable = true;
    config = ''
      #include "drbd.d/global_common.conf";
      #include "drdb.d/*.res";
      resource "r0" {
        device minor 1;
        meta-disk internal;
        ${builtins.concatStringsSep "\n" nfsHosts}
      }
    '';
  };
  systemd.services.drbd = {
    serviceConfig = {
      ExecStart = lib.mkForce "${pkgs.drbd}/bin/drbdadm up all";
      ExecStop = lib.mkForce "${pkgs.drbd}/bin/drbdadm down all";
    };
    path = with pkgs; [ kmod ];
  };
}
