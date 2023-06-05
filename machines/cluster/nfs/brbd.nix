{
  lib,
  resourcesByRole,
  ...
}: let
  _nfsHosts = lib.flatten (map (r:
    map (d:
      if d.values.type == "disk"
      then [r.values.name d.values.properties.path r.values.ip_address]
      else [])
    r.values.device) (resourcesByRole "nfs"));
  nfsHosts =
    lib.imap (i: v: ''
      on "${builtins.elemAt v 0}" {
        node-id ${i};
        disk "${builtins.elemAt v 1}";
      }
    '')
    _nfsHosts;
  nfsHostIps =
    map (v: ''
      host "${builtins.elemAt v 0}" address "${builtins.elemAt v 2}:7788";
    '')
    _nfsHosts;
in {
  networking.firewall.allowedTCPPorts = [7788];
  services.drbd = {
    enable = true;
    config = ''
      #include "drbd.d/global_common.conf";
      #include "drdb.d/*.res";
      resource "r0" {
        device minor 1;
        meta-disk internal;
        ${builtins.concatStringsSep "\n" nfsHosts}
        connection {
          ${builtins.concatStringsSep "\n" nfsHostIps}
        }
      }
    '';
  };
}