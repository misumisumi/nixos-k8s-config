{
  lib,
  config,
  pkgs,
  static,
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
  services.dnsmasq =
    let
      inherit (lib) optionals optionalAttrs;
    in
    {
      enable = true;
      multipleSessions = {
        pxe =
          let
            inherit (static.dnsmasq.pxe)
              dhcpRelay
              rangeStart
              server
              port
              ;
            inherit (static.dnsmasq.pxe.network)
              suffix
              baseIP
              baseIPv6
              ;
            ip = "${baseIP}${suffix}";
            ipv6 = "${baseIPv6}${suffix}";
            interface = "${config.systemd.network.networks."20-pxe-service".name}";
          in
          rec {
            inherit server port interface;

            no-resolv = true;
            dhcp-authoritative = true;
            except-interface = "lo";
            strict-order = true;
            # DNS settings
            domain = "pxe";
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
                "6,${ip}" # DNS server
                "15,${domain}" # published domain name
                "option6:dns-server,${ipv6}"
              ]
              ++ optionals (!dhcpRelay) [
                "3,${ip}" # default gateway
              ];
          }
          // optionalAttrs (!dhcpRelay) {
            # DHCPとPXEサーバを共存させる場合
            enable-ra = true;
            dhcp-range = [
              "${baseIP}${rangeStart},${baseIP}254,255.255.255.0,1h"
              "::,constructor:${interface},ra-stateless,1h"
            ];
            dhcp-boot = [
              "tag:iPXE,tag:X86PC,http://${ip}/boot-menu.php"
              "tag:iPXE,tag:X86-64_EFI,http://${ip}/boot-menu.php"
              "tag:!iPXE,tag:X86PC,undionly.kpxe"
              "tag:!iPXE,tag:X86-64_EFI,ipxe.efi"
            ];
          }
          // optionalAttrs dhcpRelay {
            #NOTE: DHCP PROXYモードでPXEサーバを構成する場合
            dhcp-range = [ "${static.pxe.base_ip}.0,proxy,255.255.255.0" ]; # DHCPプロキシモード
            pxe-service = [
              "tag:iPXE,X86PC,'iPXE boot menu',http://${ip}/boot-menu.php"
              "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${ip}/boot-menu.php"
              "tag:!iPXE,X86PC,'undionly.kpxe',undionly.kpxe"
              "tag:!iPXE,X86-64_EFI,'ipxe.efi',ipxe.efi"
            ];
          };

        kexec =
          let
            inherit (static.dnsmasq.kexec1)
              dhcpRelay
              rangeStart
              server
              port
              ;
            inherit (static.dnsmasq.kexec1.network)
              suffix
              baseIP
              baseIPv6
              ;
            ip = "${baseIP}${suffix}";
            ipv6 = "${baseIPv6}${suffix}";
            interface = "${config.systemd.network.networks."20-kexec1-service".name}";
          in
          rec {
            inherit server port interface;

            no-resolv = true;
            dhcp-authoritative = true;
            except-interface = "lo";
            strict-order = true;

            domain = "kexec";
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

            # tftp
            enable-tftp = true;
            #WARNING: 他のネットワーク経路からTFTPサーバへのアクセスを遮断するファイアウォールを適切に設定すること
            # このサーバが一時的かつ、プライマリな設定が無いこと
            # cockpitによる1st-boot時の一時的なマシン管理のためのssh認証を簡便化するためであり、セキュリティリスクは低いと考えられる
            tftp-root = "${config.users.users."nixos".home}/.ssh";
            user = "nixos";
            group = "users";
            tftp-secure = true;

            log-queries = true;
            log-dhcp = true;
            log-facility = "/var/log/dnsmasq.${domain}.log";
            dhcp-leasefile = "/tmp/dhcp.${domain}.leases";

            dhcp-option =
              optionals (port != 0) [
                "6,${ip}" # DNS server
                "15,${domain}" # published domain name
                "option6:dns-server,${ipv6}"
              ]
              ++ optionals (!dhcpRelay) [
                "3,${ip}" # default gateway
              ];
          }
          // optionalAttrs (!dhcpRelay) {
            # DHCPとPXEサーバを共存させる場合
            enable-ra = true;
            dhcp-range = [
              "${baseIP}${rangeStart},${baseIP}254,255.255.255.0,1h"
              "::,constructor:${interface},ra-stateless,1h"
            ];
            dhcp-boot = [
              "tag:iPXE,tag:X86PC,http://${ip}/boot-menu.php"
              "tag:iPXE,tag:X86-64_EFI,http://${ip}/boot-menu.php"
              "tag:!iPXE,tag:X86PC,undionly.kpxe"
              "tag:!iPXE,tag:X86-64_EFI,ipxe.efi"
            ];
          }
          // optionalAttrs dhcpRelay {
            #NOTE: DHCP PROXYモードでPXEサーバを構成する場合
            dhcp-range = [ "${static.pxe.base_ip}.0,proxy,255.255.255.0" ]; # DHCPプロキシモード
            pxe-service = [
              "tag:iPXE,X86PC,'iPXE boot menu',http://${ip}/boot-menu.php"
              "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${ip}/boot-menu.php"
              "tag:!iPXE,X86PC,'undionly.kpxe',undionly.kpxe"
              "tag:!iPXE,X86-64_EFI,'ipxe.efi',ipxe.efi"
            ];
          };
      };
    };
  systemd.services."dnsmasq@kexec".serviceConfig.ProtectHome = false;
}
