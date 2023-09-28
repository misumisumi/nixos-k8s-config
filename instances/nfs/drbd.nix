{ lib
, config
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
  drbdVolumeConfigPerNode = node: lib.mapAttrsToList
    (name: value:
      ''
        ''\t''\t${name} {
        ''\t''\t''\tdevice minor ${builtins.head ((builtins.match "^.*[[:space:]]([[:digit:]]+)$" name))};
        ''\t''\t''\tdisk ${value.${node}};
        ''\t''\t''\tmeta-disk internal;
        ''\t''\t}
      ''
    )
    drbdDevices;
  drbdNodeConfig = map
    (v: ''
      ''\ton "${v.name}" {
      ${lib.concatStringsSep "\n" (drbdVolumeConfigPerNode v.name)}
      ''\t''\taddress ${v.ip_address}:7789;
      ''\t}
    ''
    )
    nfsHosts;
  # For drbd 9.0
  # drbdVolumeConfig = lib.mapAttrsToList
  #   (name: value:
  #     ''
  #       ''\t${name} {
  #       ''\t''\tdevice minor ${builtins.head ((builtins.match "^.*[[:space:]]([[:digit:]]+)$" name))};
  #       ''\tmeta-disk internal;
  #       ''\t}
  #     ''
  #   )
  #   drbdDevices;
  # drbdConnectionConfig = map
  #   (v:
  #     ''
  #       ''\t''\thost "${v.name}" address "${v.ip_address}:7788";
  #     ''
  #   )
  #   nfsHosts;
in
{
  networking.firewall.allowedTCPPorts = [ 7789 ];
  services.drbd = {
    enable = true;
    config = ''
      resource "r0" {
      ''\tnet {
      ''\t''\tprotocol C;
      ''\t}
      ${lib.concatStringsSep "\n" drbdNodeConfig}
      }
    '';
    # ''\tconnection {
    # ${lib.concatStringsSep "\n" drbdConnectionConfig}
    # ''\t}
  };
  systemd.services.drbd = {
    enable = false;
    # before = [ ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = lib.mkForce "${pkgs.drbd}/etc/init.d/drbd start";
      ExecStop = lib.mkForce "${pkgs.drbd}/etc/init.d/drbd stop";
      ExecReload = "${pkgs.drbd}/etc/init.d/drbd reload";
    };
    path = with pkgs; [ kmod ];
  };
}

