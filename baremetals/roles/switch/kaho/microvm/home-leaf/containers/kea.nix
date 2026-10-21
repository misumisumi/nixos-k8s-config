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
    listToAttrs
    mapAttrsToList
    splitString
    sublist
    toInt
    ;

  inherit (config.networking.vxlan) tenants;

  # ゾーン = DHCP を提供するテナント (wan を除く)
  zones = filterAttrs (n: _: n != "wan") tenants;

  pairData =
    p:
    let
      addr = head (splitString "/" p.address);
      prefixLen = last (splitString "/" p.address);
      base = concatStringsSep "." (sublist 0 3 (splitString "." addr));
    in
    {
      # vniVlanPairs' の vlan は apply = toString で文字列化されている
      vlan = toInt p.vlan;
      # コンテナ内ではホストの SVI ではなく VLAN サブインターフェースを使う。
      iface = "eth0.${toString p.vlan}";
      subnet = "${base}.0/${prefixLen}";
      pool = "${base}.1 - ${base}.150";
      router = head (splitString "/" p.anycastGateway.address);
      # DNS は svc テナントの nspawn コンテナ (svc-leaf) が提供する
      dns = "192.168.254.253";
      # DHCP サーバ自身のアドレス。anycast gateway (.254) とホスト SVI
      # (.250) のどちらとも重複させない。
      address = "${base}.253";
      prefixLength = toInt prefixLen;
    };

  pairs = flatten (mapAttrsToList (_: t: map pairData t.vniVlanPairs') zones);
  interfaces = map (p: p.iface) pairs;
  ifaceSet = "{ ${concatStringsSep ", " (map (i: "\"${i}\"") interfaces)} }";
in
{
  # DHCP は VRF 非所属の nspawn コンテナに置く。kea は VRF を認識せず、
  # VRF 内のアドレスへ raw socket を bind できない (VyOS T6211) ため、
  # コンテナの独立 netns で VLAN サブインターフェースに直接 bind させる。
  containers.kea = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = tenants.home.L3VNI.brIF;
    config = { config, ... }: {
      system.stateVersion = config.system.nixos.release;
      networking = {
        useDHCP = false;
        nftables.enable = true;
        # trunk (eth0) を up させるためだけのエントリ
        interfaces =
          {
            eth0 = {
              useDHCP = false;
            };
          }
          // listToAttrs (
            map (p: {
              name = p.iface;
              value.ipv4.addresses = [
                {
                  inherit (p) address prefixLength;
                }
              ];
            }) pairs
          );
        vlans = listToAttrs (
          map (p: {
            name = p.iface;
            value = {
              id = p.vlan;
              interface = "eth0";
            };
          }) pairs
        );
        firewall = {
          enable = true;
          extraInputRules = ''
            iifname ${ifaceSet} udp dport { 67, 68 } accept
          '';
        };
      };

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
            interface = p.iface;
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

      # VLAN サブインターフェースのアドレス付与が終わってから起動する。
      systemd.services.kea-dhcp4-server = {
        wants = map (i: "network-addresses-${i}.service") interfaces;
        after = map (i: "network-addresses-${i}.service") interfaces;
      };
    };
  };

  # nspawn の hostBridge は home-br が先に存在する必要がある。
  # host 側 veth 名は nspawn が vb-<machine> で作る (machine = kea)。
  systemd.services."container@kea" = {
    wants = [ "set-vni-vlan-tunneling.service" ];
    after = [
      "systemd-networkd.service"
      "set-vni-vlan-tunneling.service"
      "sys-subsystem-net-devices-home\\x2dbr.device"
    ];
  };

  # host 側 veth (vb-kea) を home-br に収容し、VLAN 10/20/100 を tagged で
  # 許可する。ブリッジは DefaultPVID=none のため untagged は通さない。
  systemd.network.networks."60-vb-kea" = {
    matchConfig.Name = "vb-kea";
    networkConfig = {
      IPv6LinkLocalAddressGenerationMode = "none";
    };
    bridge = [ "${tenants.home.L3VNI.brIF}" ];
    bridgeVLANs = map (p: { VLAN = p.vlan; }) pairs;
  };
}
