{
  config,
  pkgs,
  # nodeIPv4,
  # nodeIPv6,
  ...
}:
# let
#   serverIP = "10.0.200.5";
# in
{
  networking = {
    hostName = "trigger-server";
    firewall.enable = false;
    useDHCP = true;
    # interfaces = {
    #   eth0.useDHCP = true; # eth0 is wan
    #   # eth1 is lan
    #   eth1 = {
    #     ipv4.addresses = [
    #       {
    #         address = "${serverIP}";
    #         prefixLength = 24;
    #       }
    #     ];
    #     ipv6.addresses = [
    #       {
    #         address = "fd42:3a98:dc40:60c1::5";
    #         prefixLength = 64;
    #       }
    #     ];
    #   };
    # };
    # defaultGateway = {
    #   address = "10.0.200.1";
    #   interface = "eth1";
    # };
    # defaultGateway6 = {
    #   address = "fd42:3a98:dc40:60c1::1";
    #   interface = "eth1";
    # };
    # nameservers = [
    #   "10.0.200.1"
    # ];
  };
  services.dnsmasq = {
    enable = true;
    settings = {
      # port = 0;
      no-resolv = false;
      dhcp-no-override = true;
      interface = "eth0";
      server = [ "10.0.200.1" ];
      dhcp-range = [ "10.0.200.0,proxy,255.255.255.0" ];

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
        # "tag:iPXE,X86PC,'iPXE boot menu',http://${serverIP}/boot-menu.ipxe"
        # "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${serverIP}/boot-menu.ipxe"
        "tag:iPXE,X86PC,'iPXE boot menu',http://${config.networking.hostName}/boot-menu.ipxe"
        "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${config.networking.hostName}/boot-menu.ipxe"
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
