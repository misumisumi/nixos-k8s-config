{ lib
, callPackage
, writeText
, ...
}:
let
  domain = "k8s.local";

  inherit (callPackage ../../utils/resources.nix { }) resourcesByRoleAndWS;
  inherit (callPackage ./settings.nix { }) csrConfig;

  writeJSONText = name: obj: writeText "${name}.json" (builtins.toJSON obj);
in
{
  # Get IP/DNS alternative names for all servers of this role.
  # We currently use the same certificates for all replicas of a role (where possible),
  # so, for example, etcd certificate will have alt names:
  # etcd1, etcd2, etcd3, 10.240.0.xx1, 10.240.0.xx2, 10.240.0.xx3
  getAltNames = role: ws:
    lib.flatten (map
      (r:
        [ r.values.name "${r.values.name}.${domain}" r.values.ip_address ])
      (resourcesByRoleAndWS role "k8s" ws));

  # Form a CSR request, as expected by cfssl
  mkCsr = name: { cn
                , altNames ? [ ]
                , organization ? null
                ,
                }:
    writeJSONText name (lib.attrsets.recursiveUpdate
      (csrConfig {
        inherit organization;
      })
      {
        CN = cn;
        hosts = [ cn ] ++ altNames;
      });
}
