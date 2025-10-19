{ writeShellApplication }:
writeShellApplication {
  name = "mksshhostkeys";
  text = ''
    usage() {
      cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
    Usage: ''$(
        basename "''${BASH_SOURCE[0]}"
      ) [-h] [-v] -d <terraform-project-dir> -w <workspace>
    Create an ssh key of the instances in the terraform project

    Available options:

    -h,  --help      Print this help and exit
    -v,  --verbose   Print script debug info
    -d,  --dir       Terraform project directory
    -w,  --workspace Terraform workspace to reference
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
      tf_dir=""
      workspace=""

      while (( $# > 0 )) do
        case "''${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -d | --dir)
          tf_dir=''${2-}
          shift
        ;;
        -w | --workspace)
          workspace=''${2-}
          shift
        ;;
        -?*) die "Unknown option: ''$1" ;;
        *) ;;
        esac
        shift
      done

      # check required params and arguments
      return 0
    }

    parse_params "''$@"

    project_root=$(git rev-parse --show-toplevel)
    jq -r ".values.outputs.instance_info.value | .[].name" < "''${project_root}"/terraform/"''${tf_dir}"/"''${workspace}".json | while read -r instance; do
      out_path=.ssh/host_keys/"''${workspace}"/"''${instance}"
      [ ! -d "''${out_path}" ] && mkdir -p "''${out_path}"
      mkdir -p "''${out_path}/{ssh,initrd}"
      ssh-keygen -t rsa -N "" -f "''${out_path}"/ssh/ssh_host_rsa_key
      ssh-keygen -t ed25519 -N "" -f "''${out_path}"/ssh/ssh_host_ed25519_key
      ssh-keygen -t ed25519 -N "" -f "''${out_path}"initrd/ssh_host_ed25519_key
    done
  '';
}
