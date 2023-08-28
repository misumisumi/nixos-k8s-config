{ pkgs, ... }:
{
  services.tftpd = {
    enable = true;
    path = "/srv/tftp";
  };
  system.activationScripts = {
    file-placement4ipxe.text = ''
      [ ! -d /var/www/tftp ] && mkdir -p /var/www/tftp
      ln -sf ${pkgs.syslinux}/share/syslinux/pxelinux.0 /var/www/tftp/
      ln -sf ${pkgs.syslinux}/share/syslinux/lpxelinux.0 /var/www/tftp/
      ln -sf ${pkgs.syslinux}/share/syslinux/ldlinux.c32 /var/www/tftp/
    '';
  };
}

