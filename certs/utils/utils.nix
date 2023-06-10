{
  lib,
  callPackage,
  writeText,
  ...
}: let
  domain = "k8s.local";

  inherit (callPackage ../../utils/resources.nix {}) resourcesByRole;
  inherit (callPackage ./settings.nix {}) csrConfig;
  inherit (import ../../utils/utils.nix) nodeIP;

  writeJSONText = name: obj: writeText "${name}.json" (builtins.toJSON obj);
in {
  # Get IP/DNS alternative names for all servers of this role.
  # We currently use the same certificates for all replicas of a role (where possible),
  # so, for example, etcd certificate will have alt names:
  # etcd1, etcd2, etcd3, 10.240.0.xx1, 10.240.0.xx2, 10.240.0.xx3
  getAltNames = role: let
    hosts = map (r: r.values.name) (resourcesByRole role);
    ips = map nodeIP (resourcesByRole role);
  in
    hosts ++ (map (h: "${h}.${domain}") hosts) ++ ips;

  # Form a CSR request, as expected by cfssl
  mkCsr = name: {
    cn,
    altNames ? [],
    organization ? null,
  }:
    writeJSONText name (lib.attrsets.recursiveUpdate (csrConfig {inherit organization;}) {
      CN = cn;
      hosts = [cn] ++ altNames;
    });
}