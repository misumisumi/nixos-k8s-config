
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

    LABEL NixOS-for-worker1
      MENU LABEL 6. NixOS-live-image
      kernel https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/bzImage-x86_64-linux init=/nix/store/8r6q1gbnqd54ibxbk2rmv0vkbbr4vg99-nixos-system-nixos-23.11pre130979.gfedcba/init initrd=initrd-x86_64-linux nohibernate loglevel=4 ''${cmdline}
      append load initrd=https://github.com/nix-community/nixos-images/releases/download/nixos-unstable/initrd-x86_64-linux
    EOF