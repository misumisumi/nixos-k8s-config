{
  services.dnsmasq = {
    enable = true;
    settings = {
      port = 0;
      dhcp-range = [ "192.168.1.0,proxy,255.255.255.0" ];
      dhcp-match = [
        "set:iPXE,175"
        "set:X86PC,option:client-arch,0"
        "set:X86-64_EFI,option:client-arch,7"
        "set:X86-64_EFI,option:client-arch,9"
      ];
      pxe-service = [
        "tag:!iPXE,X86PC,'undionlykpxe',undionly.kpxe"
        "tag:!iPXE,X86-64_EFI,'ipxe.efi',ipxe.efi"
        "tag:!iPXE,X86PC,'boot.ipxe',boot.ipxe"
        "tag:!iPXE,X86-64_EFI,'boot.ipxe',boot.ipxe"
      ];
      dhcp-boot = [
        "tag:!iPXE,X86PC,undionly.kpxe"
        "tag:!iPXE,X86-64_EFI,ipxe.efi"
        "tag:!iPXE,boot.ipxe"
      ];
    };
  };
}
