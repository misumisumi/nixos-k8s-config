{
  config,
  lib,
  ...
}:
let
  svc = config.networking.vxlan.tenants.svc;

  # DNS を利用するクライアントのサブネット。
  # svc-leaf には svc テナントしか無いため、クライアントは静的列挙する。
  # 192.168.254.0/24 は svc 自身 (コンテナ/anycast 経由の問い合わせ) を含む。
  zoneSubnets = [
    "192.168.10.0/24"
    "192.168.20.0/24"
    "192.168.100.0/24"
    "192.168.254.0/24"
  ];

  dnsAddress = "192.168.254.253";
in
{
  # DNS は svc テナント (VRF) に所属させず、VRF 非所属の nspawn コンテナとして
  # svc ブリッジ上に置く。コンテナは通常のネットワークスタックで動作するため
  # ip vrf exec は不要。ゾーンからのクエリは D-VNI でこのホストに届く。
  containers.unbound = {
    autoStart = true;
    privateNetwork = true;
    hostBridge = "${svc.L3VNI.brIF}";
    localAddress = "${dnsAddress}/24";
    config = { config, ... }: {
      system.stateVersion = config.system.nixos.release;
      networking = {
        useDHCP = false;
        nftables.enable = true;
        defaultGateway = "192.168.254.254";
        nameservers = [ "127.0.0.1" ];
        firewall = {
          enable = true;
          extraInputRules = ''
            ip saddr { ${lib.concatStringsSep ", " zoneSubnets} } udp dport 53 accept
            ip saddr { ${lib.concatStringsSep ", " zoneSubnets} } tcp dport 53 accept
          '';
        };
      };
      services.resolved.enable = false;
      services.unbound = {
        enable = true;
        settings.server = {
          # コンテナは単一インターフェースのため、アドレス付与を待たずに
          # バインドできるようワイルドカードで待ち受ける。
          interface = [
            "0.0.0.0"
            "::1"
          ];
          port = "53";
          access-control = [
            "0.0.0.0/0 refuse"
            "127.0.0.0/8 allow"
            "::1/128 allow"
          ] ++ map (s: "${s} allow") zoneSubnets;
          auto-trust-anchor-file = "/var/lib/unbound/root.key";
          num-threads = "2";
          msg-cache-size = "128m";
          rrset-cache-size = "512m";
          msg-cache-slabs = 8;
          rrset-cache-slabs = 8;
          infra-cache-slabs = 8;
          key-cache-slabs = 8;
          key-cache-size = "32m";
          neg-cache-size = "16m";
          infra-cache-numhosts = "100000";
          prefetch = true;
          prefetch-key = true;
          serve-expired = true;
          serve-expired-client-timeout = 0;
          serve-expired-ttl = 86400;
          serve-expired-reply-ttl = 30;
          rrset-roundrobin = true;
          hide-version = true;
          hide-identity = true;
          qname-minimisation = true;
          aggressive-nsec = true;
          minimal-responses = true;
        };
      };
    };
  };

  # nspawn の hostBridge は svc-br が先に存在する必要がある。networkd が
  # netdevs を作る順序に依存するため、ブリッジ device unit を待つ。
  # host 側 veth 名は nspawn が vb-<machine> で作る (machine = unbound)。
  systemd.services."container@unbound" = {
    wants = [ "set-vni-vlan-tunneling.service" ];
    after = [
      "systemd-networkd.service"
      "set-vni-vlan-tunneling.service"
      "sys-subsystem-net-devices-svc\\x2dbr.device"
    ];
  };

  # host 側 veth (vb-unbound) を svc-br に収容し、untagged PVID 1010 を付与する。
  # ブリッジの DefaultPVID は module が "none" にしているため、コンテナ用
  # ポートだけ明示的に VLAN 1010 へ割り当てる。
  systemd.network.networks."30-vb-unbound" = {
    matchConfig.Name = "vb-unbound";
    networkConfig = {
      IPv6LinkLocalAddressGenerationMode = "none";
    };
    bridge = [ "${svc.L3VNI.brIF}" ];
    bridgeVLANs = [
      {
        VLAN = 1010;
        PVID = 1010;
        EgressUntagged = 1010;
      }
    ];
  };
}
