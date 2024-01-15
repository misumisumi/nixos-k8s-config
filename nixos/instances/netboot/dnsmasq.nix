{ config, nodeIP, ... }:
{
  networking.firewall.allowedUDPPorts = [
    67 # DHCP
    69 # tftp
    4011 # Proxy-DHCP
  ];
  services.ntp.enable = true;
  services.dnsmasq = {
    enable = true;
    settings = {
      port = 0;
      dhcp-range = [ "192.168.1.0,proxy,255.255.255.0" ];
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
        "tag:iPXE,X86PC,'iPXE boot menu',http://${nodeIP}/boot-menu.ipxe"
        "tag:iPXE,X86-64_EFI,'iPXE boot menu',http://${nodeIP}/boot-menu.ipxe"
        "tag:!iPXE,X86PC,'undionly.kpxe',undionly.kpxe"
        "tag:!iPXE,X86-64_EFI,'ipxe.efi',ipxe.efi"
      ];
      dhcp-boot = [
        "tag:!iPXE,X86PC,undionly.kpxe"
        "tag:!iPXE,X86-64_EFI,ipxe.efi"
      ];
      log-queries = true;
      log-dhcp = true;
    };
  };
}
