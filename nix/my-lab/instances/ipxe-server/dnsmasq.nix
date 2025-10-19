{
  pkgs,
  # nodeIPv4,
  # nodeIPv6,
  ...
}:
{
  networking = {
    hostName = "trigger-server";
    useDHCP = true;
    firewall.enable = false;
    dhcpcd.enable = false;
    interfaces = {
      eth0 = {
        ipv4.addresses = [
          {
            address = "192.168.11.254";
            prefixLength = 24;
          }
        ];
        # ipv6.addresses = [
        #   {
        #     address = "fd42:dbd:6ffc:5b0d::1/64";
        #     prefixLength = 64;
        #   }
        #j];
      };
    };
    # defaultGateway = {
    #   address = "127.0.0.1";
    #   interface = "eth0";
    # };
    # defaultGateway6 = {
    #   address = "fe80::1";
    #   interface = "eth0";
    # };
    # firewall.allowedUDPPorts = [
    #   67 # DHCP
    #   69 # tftp
    #   4011 # Proxy-DHCP
    # ];

  };
  environment.systemPackages = [
    (pkgs.callPackage ./ipxe-boot-menu.nix { })
  ];
  services.dnsmasq = {
    enable = true;
    settings = {
      # port = 0;
      no-resolv = true;
      interface = "eth0";
      # server = [
      # "127.0.0.1"
      # "1.1.1.1"
      # ];
      # dhcp-range = [
      #   "192.168.11.100,192.168.11.200,255.255.255.0,12h"
      #   # "fd42:dbd:1::100,fd42:dbd:1::200,64,12h"
      # ];
      # dhcp-option = [
      #   "3,192.168.11.254"
      #   "6,192.168.11.254"
      #   # "66,192.168.11.254"
      # ];
      dhcp-range = [ "192.168.11.0,proxy,255.255.255.0" ];

      tftp-root = "/run/current-system/sw/var/tftp/";
      enable-tftp = true;
      dhcp-userclass = "set:ipxe,iPXE";
      dhcp-match = [
        "set:iPXE,175"
        "set:X86PC,option:client-arch,0"
        "set:X86-64_EFI,option:client-arch,7"
        "set:X86-64_EFI,option:client-arch,9"
      ];
      pxe-service = [
        # "tag:iPXE,X86PC,'iPXE boot menu',http://${nodeIPv4}/boot-menu.ipxe"
        # "tag:iPXE,X86PC,'iPXE boot menu',http://${nodeIPv6}/boot-menu.ipxe"
        # "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${nodeIPv4}/boot-menu.ipxe"
        # "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${nodeIPv6}/boot-menu.ipxe"
        "tag:iPXE,X86PC,'iPXE boot menu',http://192.168.11.254/boot-menu.ipxe"
        "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://192.168.11.254/boot-menu.ipxe"
        "tag:!iPXE,X86PC,'undionly.kpxe',undionly.kpxe"
        "tag:!iPXE,X86-64_EFI,'ipxe.efi',ipxe.efi"
      ];
      dhcp-boot = [
        "tag:!iPXE,X86PC,undionly.kpxe"
        "tag:!iPXE,X86-64_EFI,ipxe.efi"
      ];
      log-queries = true;
      log-dhcp = true;
      log-facility = "/var/log/dnsmasq.log";
    };
  };
}
