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
        ''\t''\t''\tdevice minor ${builtins.head (builtins.match "^.*[[:space:]]([[:digit:]]+)$" name)};
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
  system.activationScripts.makeLinstorLoopDevice_mapping = lib.stringAfter [ "var" ] ''
    mkdir -p /var/lib/linstor
    touch /var/lib/linstor/loop_device_mapping
  '';
  # Disable to control with pacemaker
  systemd.services.drbd = lib.mkForce {
    enable = false;
    after = [ "network-online.target" "sshd.service" "drbdproxy.service" ];
    wants = [ "network-online.target" "sshd.service" ];
    before = [ "pacemaker.service" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      INIT_VERSION = "systemd";
    };
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
      ExecStart = "${pkgs.drbd}/etc/init.d/drbd start";
      ExecStop = "${pkgs.drbd}/etc/init.d/drbd stop";
      ExecReload = "${pkgs.drbd}/etc/init.d/drbd reload";
    };
    path = with pkgs; [ kmod ];
  };
}

