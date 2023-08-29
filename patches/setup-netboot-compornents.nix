{ stdenvNoCC
, lib
, syslinux
, nixos-generators
, serverIP ? "192.168.1.1"
}:
stdenvNoCC.mkDerivation {
  pname = "setup-netboot-compornents";
  version = "0.0.1";
  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/var/tftp/pxelinux.cfg

    ln -sf ${syslinux}/share/syslinux/pxelinux.0 $out/var/tftp/pxelinux.0
    ln -sf ${syslinux}/share/syslinux/lpxelinux.0 $out/var/tftp/lpxelinux.0
    ln -sf ${syslinux}/share/syslinux/ldlinux.c32 $out/var/tftp/ldlinux.c32
    ln -sf ${syslinux}/share/syslinux/menu.c32 $out/var/tftp/menu.c32

    cat <<EOF > $out/var/tftp/pxelinux.cfg/default
    DEFAULT menu.c32
    PROMPT 0
    TIMEOUT 300
    ONTIMEOUT Local

    MENU TITLE PXE Boot Menu

    LABEL NixOS-for-worker1
      MENU LABEL 1. NixOS-for-worker1
      kernel vmlinuz
      append initrd=initrd.img boot=live fetch=http://${serverIP}/nixos-worker1.iso

    LABEL NixOS-for-worker2
      MENU LABEL 2. NixOS-for-worker2
      kernel nixos/vmlinuz
      append initrd=initrd.img boot=live fetch=http://${serverIP}/nixos-worker2.iso

    LABEL NixOS-for-Recovery
      MENU LABEL 3. NixOS-for-Recovery
      kernel nixos/vmlinuz
      append initrd=initrd.img boot=live fetch=http://${serverIP}/nixos-worker2.iso

    LABEL Reboot
      MENU LABEL 4. Reboot
      COM32 reboot.c32

    LABEL Poweroff
        MENU LABEL 5. Poweroff
        COMBOOT poweroff.com
    EOF

    runHook postInstall
  '';

  meta = with lib; {
    inherit version;
    description = "";
  };
}