{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    all
    concatMap
    concatStringsSep
    elem
    filter
    flatten
    head
    last
    mapAttrsToList
    mkIf
    splitString
    sublist
    toInt
    unique
    ;

  tenants = config.networking.vxlan.tenants;

  subnetOf =
    address:
    let
      addr = head (splitString "/" address);
      prefix = last (splitString "/" address);
      base = concatStringsSep "." (sublist 0 3 (splitString "." addr));
    in
    "${base}.0/${prefix}";

  allowedTo =
    tenant: vlan:
    unique (
      concatMap (
        rule:
        if rule.from == vlan then
          rule.to
        else
          [ ]
      ) tenant.isolation.allowed
    );

  rules = flatten (
    mapAttrsToList (
      _: t:
      let
        pairs = t.vniVlanPairs';
        perSrc =
          src:
          map (
            dst:
            "iifname \"${src.vlanIF}\" ip daddr ${subnetOf dst.address} drop"
          ) (
            filter (
              dst:
              dst.vlanIF != src.vlanIF
              && !(elem (toInt dst.vlan) (allowedTo t (toInt src.vlan)))
            ) pairs
          );
      in
      concatMap perSrc pairs
    ) tenants
  );

  extraRules = filter (rule: rule != "") (
    mapAttrsToList (_: t: t.isolation.extraRule) tenants
  );

  isolationAssertions = flatten (
    mapAttrsToList (
      name: t:
      let
        vlans = map (pair: toInt pair.vlan) t.vniVlanPairs';
        valid =
          rule:
          elem rule.from vlans && all (vlan: elem vlan vlans) rule.to;
      in
      map (rule: {
        assertion = valid rule;
        message = "networking.vxlan.tenants.${name}.isolation.allowed references a VLAN that is not in vniVlanPairs";
      }) t.isolation.allowed
    ) tenants
  );
in
{
  assertions = isolationAssertions;

  networking.nftables = mkIf (rules != [ ] || extraRules != [ ]) {
    enable = true;
    tables.tenant-isolation = {
      family = "ip";
      content = ''
        chain forward {
          type filter hook forward priority filter - 10; policy accept;
          ct state established,related accept
          ${concatStringsSep "\n" extraRules}
          ${concatStringsSep "\n" rules}
        }
      '';
    };
  };
}
