{
  stdenvNoCC,
  lib,
  syslinux,
  ipxe,
  callPackage,
  nixosConfigs ? { },
  serverName ? "pxe-server",
}:
let
  netbootHosts = lib.mapAttrsToList (name: config: "${name}") nixosConfigs;
  ipxeBootMenu = callPackage ./ipxe-boot-menu.nix { inherit netbootHosts; };
in
stdenvNoCC.mkDerivation {
  pname = "setup-netboot-compornents";
  version = "0.0.1";
  phases = [
    "installPhase"
    "fixupPhase"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/var/tftp/pxelinux.cfg
    mkdir -p $out/var/www/${serverName}

    cp ${syslinux}/share/syslinux/pxelinux.0 $out/var/tftp/pxelinux.0
    cp ${syslinux}/share/syslinux/lpxelinux.0 $out/var/tftp/lpxelinux.0
    cp ${syslinux}/share/syslinux/ldlinux.c32 $out/var/tftp/ldlinux.c32
    cp ${syslinux}/share/syslinux/menu.c32 $out/var/tftp/menu.c32
    cp ${
      (ipxe.override {
        additionalOptions = [
          "VLAN_CMD"
        ];
      }).overrideAttrs
        (old: {
          makeFlags = old.makeFlags ++ [
            "DEBUG=efi_snp,open,httpcore"
          ];
        })
    }/* $out/var/tftp/

    cp ${ipxeBootMenu} $out/var/www/${serverName}/boot-menu.ipxe
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (n: v: ''
        mkdir -p $out/var/www/${serverName}/${n}
        cp ${v.config.system.build.kernel}/bzImage $out/var/www/${serverName}/${n}/bzImage
        cp ${v.config.system.build.netbootRamdisk}/initrd $out/var/www/${serverName}/${n}/initrd
        cp ${v.config.system.build.netbootIpxeScript}/netboot.ipxe $out/var/www/${serverName}/${n}/netboot.ipxe
      '') nixosConfigs
    )}

    runHook postInstall
  '';

  meta = with lib; {
    inherit version;
    description = "";
  };
}
