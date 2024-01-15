{ lib, writeText, netbootHosts ? [ ], ... }:
writeText "default" ''
  DEFAULT menu.c32
  PROMPT 0
  TIMEOUT 300
  ONTIMEOUT Local

  MENU TITLE PXE Boot Menu

  LABEL NixOS-installer(unstable)
    MENU LABEL 1. NixOS-unstable-live-image
    kernel https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/bzImage-x86_64-linux init=/nix/store/8r6q1gbnqd54ibxbk2rmv0vkbbr4vg99-nixos-system-nixos-23.11pre130979.gfedcba/init initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
    append load initrd=https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/initrd-x86_64-linux

  LABEL NixOS-installer(23.05)
    MENU LABEL 2. NixOS-23.05-live-image
    kernel https://github.com/nix-community/nixos-images/releases/download/nixos-23.05/bzImage-x86_64-linux init=/nix/store/8r6q1gbnqd54ibxbk2rmv0vkbbr4vg99-nixos-system-nixos-23.11pre130979.gfedcba/init initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
    append load initrd=https://github.com/nix-community/nixos-images/releases/download/nixos-23.05/initrd-x86_64-linux

  LABEL NixOS-installer(23.11)
    MENU LABEL 3. NixOS-23.11-live-image
    kernel https://github.com/nix-community/nixos-images/releases/download/nixos-23.11/bzImage-x86_64-linux init=/nix/store/8r6q1gbnqd54ibxbk2rmv0vkbbr4vg99-nixos-system-nixos-23.11pre130979.gfedcba/init initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
    append load initrd=https://github.com/nix-community/nixos-images/releases/download/nixos-23.11/initrd-x86_64-linux

  LABEL Reboot
    MENU LABEL 4. Reboot
    COM32 reboot.c32

  LABEL Poweroff
      MENU LABEL 5. Poweroff
      COMBOOT poweroff.com
''
