{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    concatStringsSep
    filterAttrs
    flatten
    head
    imap1
    last
    mapAttrsToList
    replaceStrings
    splitString
    sublist
    ;
  inherit (config.networking.vxlan) tenants;

  # ゾーン = DHCP を提供するテナント (wan を除く)
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
      subnet = "${base}.0/${prefix}";
      pool = "${base}.100 - ${base}.200";
      router = head (splitString "/" p.anycastGateway.address);
      # unbound は各ゾーンの SVI (home-leaf 自身の .250) で listen する
      dns = addr;
    };

  pairs = flatten (mapAttrsToList (_: t: map pairData t.vniVlanPairs') zones);
  interfaces = map (p: p.vlanIF) pairs;
  ifaceSet = "{ ${concatStringsSep ", " (map (i: "\"${i}\"") interfaces)} }";

  # systemd は各ネットワークインターフェースを
  # sys-subsystem-net-devices-<iface>.device という device unit として公開する。
  # ユニット名では '-' が \x2d にエスケープされる。
  vlanDeviceUnits = map (
    iface: "sys-subsystem-net-devices-${replaceStrings [ "-" ] [ "\\x2d" ] iface}.device"
  ) interfaces;
in
{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      "interfaces-config" = {
        interfaces = interfaces;
        "dhcp-socket-type" = "raw";
        "re-detect" = false;
      };
      "lease-database" = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/dhcp4.leases";
      };
      "valid-lifetime" = 3600;
      "renew-timer" = 900;
      "rebind-timer" = 1800;
      authoritative = true;
      subnet4 = imap1 (i: p: {
        id = i;
        subnet = p.subnet;
        interface = p.vlanIF;
        pools = [
          {
            pool = p.pool;
          }
        ];
        option-data = [
          {
            name = "routers";
            data = p.router;
          }
          {
            name = "domain-name-servers";
            data = p.dns;
          }
        ];
      }) pairs;
    };
  };

  # ゾーン用 VLAN インターフェースが作成されるまで起動を待つ。
  # network-online.target は wait-online 無効のため実際には待たないので,
  # 各インターフェースの device unit に依存させる (systemd が udev の作成を待つ)。
  systemd.services.kea-dhcp4-server = {
    wants = [
      "set-vni-vlan-tunneling.service"
      "systemd-networkd.service"
    ] ++ vlanDeviceUnits;
    after = [
      "set-vni-vlan-tunneling.service"
      "systemd-networkd.service"
    ] ++ vlanDeviceUnits;
  };

  # DHCP は raw socket のため基本的に netfilter を迂回するが, ゾーン向けに明示許可
  networking.firewall.extraInputRules = ''
    iifname ${ifaceSet} udp dport { 67, 68 } accept
  '';
}
