{
  lib,
  config,
  pkgs,
  static,
  group,
  hostname,
  ...
}:
let
  inherit (builtins) match head;
  inherit (lib) optionals optionalAttrs;
  inherit (static.${group}.${hostname}) networks dnsmasq;
  manageIP = lib.removeNetmask networks.manage.address;
in
{
  environment = {
    pathsToLink = [
      "/var/tftp"
    ];
    systemPackages = [
      (pkgs.buildEnv {
        name = "pxelinux";
        paths = [
          "/var"
        ];
        postBuild = ''
          mkdir -p $out/var/tftp
          mkdir -p $out/var/tftp/pxelinux.cfg
          cp ${pkgs.syslinux}/share/syslinux/pxelinux.0 $out/var/tftp/pxelinux.0
          cp ${pkgs.syslinux}/share/syslinux/lpxelinux.0 $out/var/tftp/lpxelinux.0
          cp ${pkgs.syslinux}/share/syslinux/ldlinux.c32 $out/var/tftp/ldlinux.c32
          cp ${pkgs.syslinux}/share/syslinux/menu.c32 $out/var/tftp/menu.c32
          cp ${
            (pkgs.ipxe.override {
              additionalOptions = [
                "VLAN_CMD"
                "NET_PROTO_IPV6"
              ];
            }).overrideAttrs
              (old: {
                makeFlags = old.makeFlags ++ [
                  "DEBUG=efi_snp,open,httpcore"
                ];
              })
          }/* $out/var/tftp/
        '';
      })
    ];
  };
  networking.firewall = {
    allowedTCPPorts = [
      53 # DNS
    ];
    allowedUDPPorts = [
      53 # DNS
      67 # DHCP
      546 # DHCPv6
      547 # DHCPv6
      69 # TFTP
    ]
    ++ optionals (dnsmasq.rangeStart == "") [
      #NOTE: https://ipxe.org/appnote/proxydhcp
      4011 # DHCPv4 PROXY
    ];
  };
  services.dnsmasq = {
    enable = true;
    multipleSessions = {
      images =
        let
          interface = "${config.systemd.network.networks."20-manage".name}";
          ipSegment = head (match "([0-9]+.[0-9]+.[0-9]+).[0-9]+" manageIP);
        in
        rec {
          inherit interface;
          inherit (dnsmasq) server port;

          no-resolv = true;
          dhcp-authoritative = true;
          except-interface = "lo";
          strict-order = true;
          # DNS settings
          domain = "images.home";
          local = "/${domain}/";
          cache-size = 1000;
          domain-needed = true;
          expand-hosts = true;
          # security
          bogus-priv = true;
          localise-queries = true;
          stop-dns-rebind = true;
          rebind-localhost-ok = true;
          local-service = true;

          enable-tftp = true;
          tftp-root = "/run/current-system/sw/var/tftp/";
          dhcp-userclass = "set:ipxe,iPXE";
          dhcp-match = [
            "set:iPXE,175"
            "set:X86PC,option:client-arch,0"
            "set:X86-64_EFI,option:client-arch,7"
            "set:X86-64_EFI,option:client-arch,9"
          ];
          log-queries = true;
          log-dhcp = true;
          log-facility = "/var/log/dnsmasq.${domain}.log";
          dhcp-leasefile = "/tmp/dhcp.${domain}.leases";

          dhcp-option =
            optionals (port != 0) [
              "6,${manageIP}" # DNS server
              "15,${domain}" # published domain name
              # "option6:dns-server,${ipv6}"
            ]
            ++ optionals (dnsmasq.rangeStart != "") [
              "3,${manageIP}" # default gateway
            ];
        }
        // optionalAttrs (dnsmasq.rangeStart != "") {
          #NOTE: DHCPとPXEサーバを共存させる場合
          enable-ra = true;
          dhcp-range = [
            "${ipSegment}.${dnsmasq.rangeStart},${ipSegment}.254,255.255.255.0,1h"
            "::,constructor:${interface},ra-stateless,1h"
          ];
          dhcp-boot = [
            "tag:iPXE,tag:X86PC,http://${manageIP}/boot-menu.php"
            "tag:iPXE,tag:X86-64_EFI,http://${manageIP}/boot-menu.php"
            "tag:!iPXE,tag:X86PC,undionly.kpxe"
            "tag:!iPXE,tag:X86-64_EFI,ipxe.efi"
          ];
        }
        // optionalAttrs (dnsmasq.rangeStart == "") {
          #NOTE: 外部にDHCPがありDHCP PROXYモードでPXEサーバを構成する場合
          dhcp-range = [ "${ipSegment}.0,proxy,255.255.255.0" ]; # DHCPプロキシモード
          pxe-service = [
            "tag:iPXE,X86PC,'iPXE boot menu',http://${manageIP}/boot-menu.php"
            "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${manageIP}/boot-menu.php"
            "tag:!iPXE,X86PC,'undionly.kpxe',undionly.kpxe"
            "tag:!iPXE,X86-64_EFI,'ipxe.efi',ipxe.efi"
          ];
        };
    };
  };
}
