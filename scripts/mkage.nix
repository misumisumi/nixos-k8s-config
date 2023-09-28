{ age
, ssh-to-age
, writeShellApplication
, writeShellScriptBin
}: {
  mkage4mgr = writeShellScriptBin "mkage4mgr" ''
    [ ! -d ~/.config/sops/age ] && mkdir -p ~/.config/sops/age && chmod 700 ~/.config/sops/age
    ${ssh-to-age}/bin/ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
    ${age}/bin/age-keygen -y ~/.config/sops/age/keys.txt
  '';
  mkage4instance = writeShellApplication {
    name = "mkage4instance";
    text = ''
      usage() {
        cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
      Usage: ''$(
          basename "''${BASH_SOURCE[0]}"
        ) [-h] [-v] -d <terraform-project-dir> -w <workspace>
      Generating age's shared key from instance's ssh key

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
        age=$(lxc exec "''${instance}" -- cat /etc/ssh/ssh_host_ed25519_key.pub </dev/null | ${ssh-to-age}/bin/ssh-to-age)
        echo "- &instance_''${workspace}_''${instance} ''${age}"
      done
    '';
  };
}

