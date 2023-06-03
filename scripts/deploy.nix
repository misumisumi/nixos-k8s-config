{writeShellApplication}:
writeShellApplication {
  name = "deploy";
  text = ''
    usage() {
      cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
    Usage: ''$(
        basename "''${BASH_SOURCE[0]}"
      ) <ter|nix> <cmd> <target> [-h] [-v]

      Deployment of terraform with workspace-specific variables

    Available options:

    -h, --help      Print this help and exit
    -v, --verbose   Print script debug info
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

      cmd=''$1
      subcmd=''$2
      target=''$3

      # check required params and arguments
      for value in "''${cmd[@]}"
      do
        [[ "''${value}" != "nix" ]] && [[ "''${value}" != "ter" ]] && die "Can use only 'plan' or 'apply'"
      done
      for value in "''${target[@]}"
      do
        [[ "''${value}" == "" ]] && die "Need workspace name"
        # colmena tag
        [[ "''${cmd}" == "nix" ]] && [[ "''${value}" != "hosts" ]] && [[ "''${value}" != "k8s" ]] && die "Can use tag 'hosts' or 'k8s'"
        # terraform workspace
        [[ "''${cmd}" == "ter" ]] && [[ "''${value}" != "develop" ]] && [[ "''${value}" != "product" ]] && die "Can use workspace 'develop' or 'product'"
      done

      return 0
    }

    parse_params "''$@"

    # script logic here
    if [ "''${cmd}" = "ter" ]; then
      terraform workspace select "''${target}"
      terraform "''${subcmd}" -var-file="''${target}".tfvars
      terraform show -json | jq >show.json
      terraform graph | dot -Tpng >show.png
      hcl2json "''${target}".tfvars > terraform.json
    fi

    if [ "''${cmd}" = "nix" ]; then
      colmena "''${subcmd}" --on @"''${target}"
    fi
  '';
}