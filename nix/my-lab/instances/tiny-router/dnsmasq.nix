{
  lib,
  lan_ip,
  lan_ipv6,
  pkgs,
  ...
}:
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
    ];
  };
  services.dnsmasq = {
    enable = true;
    settings = rec {
      no-resolv = true;
      dhcp-authoritative = true;
      interface = "eth1";
      server = [ "8.8.8.8" ];

      #NOTE: DHCP PROXYモードでPXEサーバを構成する場合、コメントアウト
      # port = 0; # DNSサーバを起動しない
      # server = [ "${lan_base_ip}.1" ]; # 上位DNSサーバの指定
      # dhcp-range = [ "${lan_base_ip}.0,proxy,255.255.255.0" ]; # DHCPプロキシモード

      # DHCPとPXEサーバを共存させる場合
      enable-ra = true;
      dhcp-range =
        let
          inherit (lib) removeSuffix;
          base = removeSuffix ".1" lan_ip;
        in
        [
          "${base}.10,${base}.254,255.255.255.0,1h"
          "::,constructor:${interface},ra-stateless,1h"
        ];
      dhcp-option = [
        "3,${lan_ip}"
        "6,${lan_ip}"
        "15,lan"
        "option6:dns-server,${lan_ipv6}"
      ];
      domain = "lan";
      local = "/lan/";
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
      #NOTE: DHCP PROXYモードでPXEサーバを構成する場合、コメントアウト
      # pxe-service = [
      #   "tag:iPXE,X86PC,'iPXE boot menu',http://${lan_ip}/boot-menu.php"
      #   "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${lan_ip}/boot-menu.php"
      #   # "tag:iPXE,X86PC,'iPXE boot menu',http://${config.networking.hostName}/boot-menu.php"
      #   # "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${config.networking.hostName}/boot-menu.php"
      #   "tag:!iPXE,X86PC,'undionly.kpxe',undionly.kpxe"
      #   "tag:!iPXE,X86-64_EFI,'ipxe.efi',ipxe.efi"
      # ];
      dhcp-boot = [
        "tag:iPXE,tag:X86PC,http://${lan_ip}/boot-menu.php"
        "tag:iPXE,tag:X86-64_EFI,http://${lan_ip}/boot-menu.php"
        "tag:!iPXE,tag:X86PC,undionly.kpxe"
        "tag:!iPXE,tag:X86-64_EFI,ipxe.efi"
      ];
      log-queries = true;
      log-dhcp = true;
      log-facility = "/var/log/dnsmasq.log";
      dhcp-leasefile = "/tmp/dhcp.leases";
    };
  };
}
