{writeShellApplication}:
writeShellApplication {
  name = "mkdisk";
  text = ''
    DEVICE=''$1
    VGNAME=''$2
    MNT=''${3:-/mnt}
    [[ "''$(whiami)" != "root" ]] && echo "Run must as root !" && exit 1
    read -p "Create luks to ''$DEVICE. Are you sure? (Type 'yes' in capital letters): " CHECK
    [[ "''${CHECK}" != "YES" ]] && echo "Process stop." && exit 1

    cryptsetup -s 512 -h sha512 luksFormat "''${DEVICE}"
    cryptsetup open "''${DEVICE}" cryptolvm
    pvcreate /dev/mapper/cryptolvm
    vgcreate $VGNAME /dev/mapper/cryptolvm
    lvcreate -L 4G $VGNAME -n lvolroot
    lvcreate -L 64G $VGNAME -n lvolnix
    lvcreate -L 128G $VGNAME -n lvolvar
    lvcreate -L 8G $VGNAME -n lvolswap
    lvcreate -l +100%FREE $VGNAME -n lvolhome

    echo "Finish!"
  '';
}