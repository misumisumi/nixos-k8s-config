{ lib, writeText, netbootHosts ? [ ], ... }:
let
  extraMenu = lib.concatMapStringsSep "\n"
    (x: "item ${x} Launch ${x}")
    netbootHosts;
  extraMenuItem = lib.concatMapStringsSep "\n"
    (x: ''
      :${x}
      chain -ar ${x}/netboot.ipxe
    ''
    )
    netbootHosts;

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
  item NixOS-installer(unstable)  Launch NixOS-unstable installer
  item NixOS-installer(23.05)     Launch NixOS-23.05 installer
  ${extraMenu}
  item --gap --           -------------------------- Advanced Option --------------------
  item --key c config     Configure settings
  item shell              Drop to iPXE shell
  item reboot             Reboot Computer
  choose --timeout ''${menu-timeout} --default ''${menu-default} selected || goto cancel
  goto ''${selected}

  ${extraMenuItem}

  :NixOS-installer(unstable)
  kernel https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/bzImage-x86_64-linux init=/nix/store/8r6q1gbnqd54ibxbk2rmv0vkbbr4vg99-nixos-system-nixos-23.11pre130979.gfedcba/init initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
  initrd https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/initrd-x86_64-linux
  boot

  :NixOS-installer(23.05)
  kernel https://github.com/nix-community/nixos-images/releases/download/nixos-23.05/bzImage-x86_64-linux init=/nix/store/rw55hls1rah957jg260bw5g1s1pbvbb1-nixos-system-nixos-23.05beta-356385.gfedcba/init initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
  initrd https://github.com/nix-community/nixos-images/releases/download/nixos-23.05/initrd-x86_64-linux
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

