{
  lib,
  writeText,
  netbootHosts ? [ ],
  ...
}:
let
  extraMenu = lib.concatMapStringsSep "\n" (x: "item ${x} Launch ${x}") netbootHosts;
  extraMenuItem = lib.concatMapStringsSep "\n" (x: ''
    :${x}
    chain -ar ${x}/netboot.ipxe
  '') netbootHosts;
  stableVersion = "25.05";
in
writeText "boot-menu.ipxe" ''
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
''
