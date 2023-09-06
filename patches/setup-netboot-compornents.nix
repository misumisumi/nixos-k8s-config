{ stdenvNoCC
, lib
, syslinux
, ipxe
, callPackage
, serverIP ? "192.168.1.1"
, serverName ? "pxe-server"
}:
let
  ipxeBootMenu = callPackage ./ipxe-boot-menu.nix { };
in
stdenvNoCC.mkDerivation {
  pname = "setup-netboot-compornents";
  version = "0.0.1";
  phases = [ "installPhase" "fixupPhase" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/var/tftp/pxelinux.cfg
    mkdir -p $out/var/www/${serverName}

    cp ${syslinux}/share/syslinux/pxelinux.0 $out/var/tftp/pxelinux.0
    cp ${syslinux}/share/syslinux/lpxelinux.0 $out/var/tftp/lpxelinux.0
    cp ${syslinux}/share/syslinux/ldlinux.c32 $out/var/tftp/ldlinux.c32
    cp ${syslinux}/share/syslinux/menu.c32 $out/var/tftp/menu.c32
    cp ${ipxe}/* $out/var/tftp/

    cp ${ipxeBootMenu} $out/var/tftp/boot-menu.ipxe
    cp ${ipxeBootMenu} $out/var/www/${serverName}/boot-menu.ipxe

    runHook postInstall
  '';

  meta = with lib; {
    inherit version;
    description = "";
  };
}
