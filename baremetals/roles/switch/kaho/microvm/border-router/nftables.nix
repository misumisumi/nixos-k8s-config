{ isDev, static, ... }:
let
  inherit (static.microvm.borderRouter) PSID IPIP6_IPv4;

  fakeRule = {
    "nat" = {
      enable = true;
      family = "inet";
      content = ''
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          oifname "enp0s4" masquerade
        }
      '';
    };
  };

  mapeRule = {
    "map-e-nat" = {
      enable = true;
      family = "ip";
      content =
        let
          blockStride = 4096; # nxps
          blockCount = 16; # lp+1
          portsPerBlock = 16;
          portBase = PSID * portsPerBlock; # 2576

          map-e-nat-chains = builtins.concatStringsSep "\n" (
            builtins.genList (
              mark:
              let
                low = mark * blockStride + portBase;
                high = low + portsPerBlock - 1;
              in
              "chain chain-${toString mark} { meta l4proto { tcp, udp, icmp } snat to ${IPIP6_IPv4}:${toString low}-${toString high} persistent; }"
            ) blockCount
          );

          # vmap も生成
          map-e-nat-vmap = builtins.concatStringsSep ",\n" (
            builtins.genList (mark: "${toString mark} : goto chain-${toString mark}") blockCount
          );
        in
        ''
          chain postrouting {
            type nat hook postrouting priority srcnat; policy accept;
            oifname "v6plus-tnl" meta l4proto { tcp, udp, icmp } mark set numgen inc mod 16 offset 0
            oifname "v6plus-tnl" meta mark vmap {
              ${map-e-nat-vmap}
            }
          }

          ${map-e-nat-chains}
        '';
    };
    "map-e-filter" = {
      enable = true;
      family = "ip";
      content = ''
        chain postrouting {
          type filter hook postrouting priority mangle; policy accept;
          iifname "v6plus-tnl" tcp flags & syn == syn tcp option maxseg size set rt mtu
          oifname "v6plus-tnl" tcp flags & syn == syn tcp option maxseg size set rt mtu
        }
      '';
    };
  };
in
{
  networking.nftables = {
    enable = true;
    tables = if isDev then fakeRule else mapeRule;
  };
}
