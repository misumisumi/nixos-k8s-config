{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    filterAttrs
    flatten
    head
    last
    mapAttrsToList
    splitString
    sublist
    ;
  inherit (config.networking.vxlan) tenants;

  # ゾーン = DNS を提供するテナント (wan を除く)
  zones = filterAttrs (n: _: n != "wan") tenants;

  pairData =
    p:
    let
      addr = head (splitString "/" p.address);
      prefix = last (splitString "/" p.address);
      base = concatStringsSep "." (sublist 0 3 (splitString "." addr));
    in
    {
      inherit (p) vlanIF;
      # home-leaf 自身の per-VTEP SVI アドレスで listen する
      listen = addr;
      subnet = "${base}.0/${prefix}";
    };

  pairs = flatten (mapAttrsToList (_: t: map pairData t.vniVlanPairs') zones);
  ifaceSet = "{ ${concatStringsSep ", " (map (p: "\"${p.vlanIF}\"") pairs)} }";
in
{
  services.resolved.enable = false;
  networking.nameservers = [ "127.0.0.1" ];

  services.unbound = {
    enable = true;
    settings = {
      server = {
        interface = map (p: p.listen) pairs;
        port = "53";
        access-control = [ "0.0.0.0/0 refuse" ] ++ map (p: "${p.subnet} allow") pairs;
        auto-trust-anchor-file = "/var/lib/unbound/root.key";
        num-threads = "2";
        msg-cache-size = "64m";
        rrset-cache-size = "128m";
        infra-cache-numhosts = "10000";
      };
    };
  };

  # ゾーン用 VLAN インターフェースは systemd-networkd が非同期に作成する。
  # network-online.target は wait-online 無効のため実際には待たないので、
  # SVI アドレスが付与されるまで明示的に待ってから起動する。
  systemd.services.unbound = {
    wants = [
      "set-vni-vlan-tunneling.service"
      "systemd-networkd.service"
    ];
    after = [
      "set-vni-vlan-tunneling.service"
      "systemd-networkd.service"
    ];
    path = [
      pkgs.coreutils
      pkgs.iproute2
      pkgs.gnugrep
    ];
    serviceConfig.ExecStartPre = [
      (pkgs.writeShellScript "unbound-wait-vlan-addresses" ''
        for entry in ${concatStringsSep " " (map (p: "${p.vlanIF}:${p.listen}") pairs)}; do
          iface=''${entry%%:*}
          addr=''${entry#*:}
          for _ in $(seq 1 120); do
            if ip -4 addr show dev "$iface" 2>/dev/null | grep -Fq "$addr/"; then
              break
            fi
            sleep 1
          done
          if ! ip -4 addr show dev "$iface" 2>/dev/null | grep -Fq "$addr/"; then
            echo "unbound: address $addr on $iface did not appear" >&2
            exit 1
          fi
        done
      '')
    ];
  };

  networking.firewall.extraInputRules = ''
    iifname ${ifaceSet} udp dport 53 accept
    iifname ${ifaceSet} tcp dport 53 accept
  '';
}
