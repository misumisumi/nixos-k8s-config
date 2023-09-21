{ lib
, pkgs
, resourcesByRole
, constByKey
, ...
}:
let
  nfsHosts = lib.flatten (map
    (r:
      map
        (d:
          if d.type == "disk"
          then {
            inherit (r.values) name ip_address;
          }
          else [ ])
        r.values.device)
    (resourcesByRole "nfs" "nfs"));
  drbdDevices = constByKey "drbdDevices";
  drbdVolumeConfig = lib.mapAttrsToList
    (name: value:
      ''
        ''\t${name} {
        ''\t''\tdevice minor ${(lib.charToInt (builtins.match ".*([0-9].+)" name))+1};
        ''\tmeta-disk internal;
        ''\t}
      ''
    )
    drbdDevices;
  drbdVolumeConfigPerNode = node: lib.mapAttrsToList
    (name: value:
      ''
        ''\t''\t${name} {
        ''\t''\t''\tdisk ${value.${name}}
        ''\t''\t}
      ''
    )
    drbdDevices;
  drbdNodeConfig = map
    (v: ''
      ''\ton "${v.name}" {
      ''\t''\tnode-id ${builtins.match ".*([0-9].+)" v.name};
      ${lib.concatStringsSep "\n" (drbdVolumeConfigPerNode v.name)}
      ''\t}
    ''
    )
    nfsHosts;
  drbdConnectionConfig = map
    (v:
      ''
        ''\t''\thost "${v.name}" address "${v.ip_address}:7788"
      ''
    )
    nfsHosts;
in
{
  networking.firewall.allowedTCPPorts = [ 7788 ];
  services.drbd = {
    enable = true;
    config = '' #include "drbd.d/global_common.conf";
      #include "drdb.d/*.res";
      resource "r0" {
      ''\tmeta-disk internal;
      ${lib.concatStringsSep "\n" drbdVolumeConfig}
      ${lib.concatStringsSep "\n" drbdNodeConfig}
      ''\tconnection {
      ${lib.concatStringsSep "\n" drbdConnectionConfig}
      ''\t}
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
