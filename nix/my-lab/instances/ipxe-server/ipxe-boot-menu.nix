{
  lib,
  stdenvNoCC,
  writeText,
  syslinux,
  ipxe,
  netbootHosts ? [ ],
  ...
}:
let
  extraMenu = lib.concatMapStringsSep "\n" (x: "item ${x} Launch ${x}") netbootHosts;
  extraMenuItem = lib.concatMapStringsSep "\n" (x: ''
    :${x}
    chain -ar ${x}/netboot.ipxe
  '') netbootHosts;
in
stdenvNoCC.mkDerivation {
  name = "ipxe-boot-menu";
  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  installPhase =
    let
      stableVersion = "25.05";
      ipxeBootMenu = writeText "boot-menu.ipxe" ''
        #!ipxe

        # dhcp
        # Some menu defaults
        set menu-timeout 300000
        isset ''${menu-default} || set menu-default exit

        :start

        menu Please choose an type of node you want to install
        item --gap --           -------------------------- node type -------------------------
        item NixOS-installer (unstable)  Launch NixOS-unstable installer
        item NixOS-installer (${stableVersion})     Launch NixOS-${stableVersion} installer
        ${extraMenu}
        item --gap --           -------------------------- Advanced Option --------------------
        item --key c config     Configure settings
        item shell              Drop to iPXE shell
        item reboot             Reboot Computer
        choose --timeout ''${menu-timeout} --default ''${menu-default} selected || goto cancel
        goto ''${selected}

        ${extraMenuItem}

        :NixOS-installer (${stableVersion})
        kernel https://github.com/nix-community/nixos-images/releases/download/nixos-${stableVersion}/bzImage-x86_64-linux initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
        initrd https://github.com/nix-community/nixos-images/releases/download/nixos-${stableVersion}/initrd-x86_64-linux
        boot

        :NixOS-installer (unstable)
        kernel https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/bzImage-x86_64-linux initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
        initrd https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/initrd-x86_64-linux
        boot

        :exit
        exit

        :cancel
        echo You cancelled the menu, dropping you to a shell

        :shell
        echo Type 'exit' to get the back to the menu
        shell
        set menu-timeout 0
        goto start

        :reboot
        reboot

        :exit
        exit
      '';
    in
    ''
        runHook preInstall

        mkdir -p $out/var/tftp/pxelinux.cfg
        mkdir -p $out/var/www

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

      cp ${ipxeBootMenu} $out/var/www/boot-menu.ipxe

      runHook postInstall
    '';
}
