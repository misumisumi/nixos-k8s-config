{writeShellApplication}: {
  mountrootfs = writeShellApplication {
    name = "mountrootfs";
    text = ''
      usage() {
        cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
      Usage: ''$(
          basename "''${BASH_SOURCE[0]}"
        ) [-h] [-v] BOOTPART VGNAME -l LUKSPART

      Making bootfs
      You must run as root user.

      Available options:

      -h,  --help      Print this help and exit
      -v,  --verbose   Print script debug info
      -l,  --lukspart  LUKS partion (if you need unlock partion)
      EOF
        exit
      }

      cleanup() {
        trap - SIGINT SIGTERM ERR EXIT
        # script cleanup here
      }

      msg() {
        echo >&2 -e "''${1-}"
      }

      die() {
        local msg=''$1
        local code=''${2-1} # default exit status 1
        msg "''$msg"
        exit "''$code"
      }

      parse_params() {
        # default values of variables set from params
        LUKSPART=""
        while :; do
          case "''${1-}" in
          -h | --help) usage ;;
          -v | --verbose) set -x ;;
          -l | --lukspart) LUKSPART=''${2-} ;;
          -?*) die "Unknown option: ''$1" ;;
          *) break ;;
          esac
          shift
        done

        # check required params and arguments
        return 0
      }

      parse_params "''$@"
      [[ "''$(whoami)" != "root" ]] && echo "Run must as root !" && exit 1
      BOOTPART=''$1
      VGNAME=''$2
      [[ "''$BOOTPART" == "" ]] && echo "You must set boot disk part" && exit 1

      [[ ! -d /mnt ]] && mkdir /mnt && echo "Create /mnt"
      if [ "''$LUKSPART" != "" ]; then
        cryptsetup open "''$LUKSPART" cryptolvm
      fi
      lvnames=("lvolroot" "lvolvar" "lvolnix" "lvolswap" "lvolhome")
      for lvname in "''${lvnames[@]}"; do
        if [ "''$lvname" == "lvolroot" ]; then
          mount /dev/mapper/"''$VGNAME-''$lvname" /mnt
          mkdir -p /mnt/{boot,home,var,nix}
        elif [ "''$lvname" == "lvolswap" ]; then
          continue
        else
          mount /dev/mapper/"''$VGNAME-''$lvname" /mnt/"''${lvname//lvol/}"
        fi
      done
      mount "''$BOOTPART" /mnt/boot

      lsblk
      echo "Finish!"
    '';
  };
  mkbootfs = writeShellApplication {
    name = "mkbootfs";
    text = ''
      usage() {
        cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
      Usage: ''$(
          basename "''${BASH_SOURCE[0]}"
        ) [-h] [-v] DEVICE NAME

      Making bootfs
      You must run as root user.

      Available options:

      -h,  --help      Print this help and exit
      -v,  --verbose   Print script debug info
      EOF
        exit
      }

      cleanup() {
        trap - SIGINT SIGTERM ERR EXIT
        # script cleanup here
      }

      msg() {
        echo >&2 -e "''${1-}"
      }

      die() {
        local msg=''$1
        local code=''${2-1} # default exit status 1
        msg "''$msg"
        exit "''$code"
      }

      parse_params() {
        # default values of variables set from params
        while :; do
          case "''${1-}" in
          -h | --help) usage ;;
          -v | --verbose) set -x ;;
          -?*) die "Unknown option: ''$1" ;;
          *) break ;;
          esac
          shift
        done

        # check required params and arguments
        return 0
      }

      parse_params "''$@"

      [[ "''$(whoami)" != "root" ]] && echo "Run must as root !" && exit 1
      DEVICE=''$1
      NAME=''$2
      read -r -p "Setup boot to ''$DEVICE. Are you sure? (Type 'yes' in capital letters): " CHECK
      [[ "''${CHECK}" != "YES" ]] && echo "Process stop." && exit 1

      mkfs.vfat "''$DEVICE"
      dosfslabel "''$DEVICE" "''$(echo "''$NAME" | cut -c -3)-boot"

      echo "Finish!"
    '';
  };
  mkrootfs = writeShellApplication {
    name = "mkrootfs";
    text = ''
      usage() {
        cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
      Usage: ''$(
          basename "''${BASH_SOURCE[0]}"
        ) [-h] [-v] DEVICE NAME -rs root_size -hs home_size -vs var_size -ns nix_size -ss swap_size

      Making rootfs using LVM on LUKS.
      You must run as root user.

      Available options:

      -h,  --help      Print this help and exit
      -v,  --verbose   Print script debug info
      -rs, --root_size Logical partition size for root (default: 4G)
      -hs, --home_size Logical partition size for home (default: "" (This mean +100%FREE))
      -vs, --var_size  Logical partition size for var  (default: 128G)
      -ns, --nix_size  Logical partition size for nix  (default: 64G)
      -ss, --swap_size Logical partition size for swap (default: 8G)
      EOF
        exit
      }

      cleanup() {
        trap - SIGINT SIGTERM ERR EXIT
        # script cleanup here
      }

      msg() {
        echo >&2 -e "''${1-}"
      }

      die() {
        local msg=''$1
        local code=''${2-1} # default exit status 1
        msg "''$msg"
        exit "''$code"
      }

      parse_params() {
        # default values of variables set from params
        root_size="4G"
        home_size=""
        var_size="128G"
        nix_size="64G"
        swap_size="8G"

        while :; do
          case "''${1-}" in
          -h | --help) usage ;;
          -v | --verbose) set -x ;;
          -rs | --root_size) root_size=''${2-} ;;
          -hs | --home_size) home_size=''${2-} ;;
          -vs | --var_size) var_size=''${2-} ;;
          -ns | --nix_size) nix_size=''${2-} ;;
          -ss | --swap_size) swap_size=''${2-} ;;
          -?*) die "Unknown option: ''$1" ;;
          *) break ;;
          esac
          shift
        done

        # check required params and arguments
        return 0
      }

      parse_params "''$@"
      [[ "''$(whoami)" != "root" ]] && echo "Run must as root !" && exit 1

      DEVICE=''$1
      NAME=''$2
      read -r -p "Create luks to ''$DEVICE. Are you sure? (Type 'yes' in capital letters): " CHECK
      [[ "''${CHECK}" != "YES" ]] && echo "Process stop." && exit 1

      VGNAME=VolGroup"''${NAME^}"

      declare -A partitions=(
        ["lvolroot"]="''$root_size"
        ["lvolvar"]="''$var_size"
        ["lvolnix"]="''$nix_size"
        ["lvolswap"]="''$swap_size"
        ["lvolhome"]="''$home_size"
      )

      cryptsetup -s 512 -h sha512 luksFormat "''$DEVICE" &&
        cryptsetup open "''$DEVICE" cryptolvm &&
        pvcreate /dev/mapper/cryptolvm &&
        vgcreate "''$VGNAME" /dev/mapper/cryptolvm
      echo "VG name: ''$VGNAME"

      lvnames=("lvolroot" "lvolvar" "lvolnix" "lvolswap" "lvolhome")
      for lvname in "''${lvnames[@]}"; do
        if [ "''$lvname" == "lvolhome" ] && [ "''${partitions["lvolhome"]}" == "" ]; then
          lvcreate -l +100%FREE "''$VGNAME" --name "''$lvname"
        else
          lvcreate -L "''${partitions[''$lvname]}" "''$VGNAME" --name "''$lvname"
        fi
      done

      for lvname in "''${lvnames[@]}"; do
        mkfs.ext4 /dev/mapper/"''$VGNAME-''$lvname"
        e2label /dev/mapper/"''$VGNAME-''$lvname" "''$NAME-''${lvname//lvol//}"
      done

      echo "Finish!"
    '';
  };
}