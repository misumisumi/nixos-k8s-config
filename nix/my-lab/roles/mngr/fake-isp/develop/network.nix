{
  hostname,
  ...
}:
{
  boot = {
    kernel.sysctl = {
      "net.ipv4.conf.all.rp_filter" = 0;
      "net.ipv4.conf.default.rp_filter" = 0;
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv6.conf.default.forwarding" = 1;
    };
    kernelModules = [
      "ip6_tunnel"
    ];
  };
  networking = {
    hostName = hostname;
    useNetworkd = true;
    firewall = {
      enable = true;
      filterForward = true;
      extraInputRules = ''
        # meta l4proto は、IPv6拡張ヘッダがあっても追跡して最終的なプロトコルを見てくれる
        # 4 = IPv4-in-IPv6 (IPIP), 41 = IPv6-in-IPv6（将来混在しても通す場合）
        iifname "enp6s0" meta nfproto ipv6 meta l4proto { 4, 41 } counter accept comment "Allow tunnel proto from CE"
      '';
      extraForwardRules = ''
        iifname "map-e-br" oifname "enp5s0" accept
        iifname "enp5s0" oifname "map-e-br" ct state established,related accept
      '';
    };
    nftables = {
      enable = true;
      ruleset = ''
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100;
            # 物理インターフェース（外部接続側）から出るパケットをNAT
            oifname "enp5s0" masquerade
          }
        }
        table ip filter {
          chain forward {
            type filter hook forward priority 0;
            tcp flags syn tcp option maxseg size set 1420
          }
        }
      '';
    };
  };
  services.resolved.enable = false;
  systemd.network = {
    enable = true;
    netdevs = {
      "map-e-br" = {
        netdevConfig = {
          Name = "map-e-br";
          Kind = "ip6tnl";
        };
        tunnelConfig = {
          # 受信時は送信元を問わないため Mode は any または ip4ip6
          Mode = "ipip6";
          # CE側から見た "Remote" アドレス（自分自身のIPv6）
          Local = "fd42:3a98:dc40:52c6::254";
          Remote = "fd42:3a98:dc40:52c6::100";
          DiscoverPathMTU = true;
          EncapsulationLimit = "none";
        };
      };
    };
    networks = {
      "10-enp5s0" = {
        matchConfig.Name = "enp5s0";
        address = [ "10.150.150.5/24" ];
        networkConfig = {
          IPv4Forwarding = true;
        };
        routes = [
          {
            Gateway = "10.150.150.1";
            Destination = "0.0.0.0/0";
          }
        ];
      };
      "10-enp6s0" = {
        name = "enp6s0";
        networkConfig = {
          Description = "BR physical interface";
          IPv6AcceptRA = true;
          IPv4Forwarding = true;
          IPv6Forwarding = true;
        };
        address = [ "fd42:3a98:dc40:52c6::254/64" ];
        tunnel = [ "map-e-br" ];
      };
      "11-map-e-br" = {
        matchConfig.Name = "map-e-br";
        networkConfig = {
          Description = "MAP-E Tunnel Endpoint";
          IPv4Forwarding = true;
        };

        # ------------------------------------------------------------
        # 重要: 戻りパケット（インターネット -> CE）のルーティング
        # ------------------------------------------------------------
        # インターネットから戻ってきた 203.0.113.1 宛のパケットを
        # このトンネルデバイス（＝その先にいるCE）へ流し込みます。
        # 実際には Mode=any の場合、ここで宛先IPv6を特定する設定が別途必要になる場合があります。
        # 実験的な1対1構成であれば、以下のようにスタティックルートを引きます。
        # ------------------------------------------------------------
        routes = [
          {
            routeConfig = {
              Destination = "203.0.113.1/32";
              PreferredSource = "10.150.150.5";
              Scope = "link";
            };
          }
        ];
      };
    };
  };
}
