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

    check_in_host() {
      local json=''$1
      local target=''$2
      jq -r ".hosts[].name" "''$json" | while read -r host
      do
        if [ "''${host}" == "''${target}" ]; then
            return 0
        fi
      done
      return 1
    }

    parse_params() {
      # default values of variables set from params
      count=0
      while (( $# > 0 )) do
        count=''$((count + 1))
        case "''${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -- )
          count=''$((count + 1))
          break
        ;;
        -?*) die "Unknown option: ''$1" ;;
        *) ;;
        esac
        shift
      done

      return 0
    }

    parse_params "''$@"

    cmd=''$1
    subcmd=''$2
    target=''$3

    # check required params and arguments
    [[ "''${cmd}" != "nix" ]] && [[ "''${cmd}" != "ter" ]] && die "Can use only 'plan' or 'apply'"
    [[ "''${target}" == "" ]] && die "Need workspace name"
    # colmena tag
    [[ "''${cmd}" == "nix" ]] && [[ "''${target}" != "hosts" ]] && [[ "''${target}" != "k8s" ]] && check_in_host hosts.json "''${target}" && die "Can use tag 'hosts' or 'k8s'"
    # terraform workspace
    [[ "''${cmd}" == "ter" ]] && [[ "''${target}" != "develop" ]] && [[ "''${target}" != "product" ]] && die "Can use workspace 'develop' or 'product'"

    # script logic here
    if [ "''${cmd}" = "ter" ]; then
      terraform workspace select "''${target}"
      terraform "''${subcmd}" -var-file="''${target}".tfvars
      terraform show -json | jq >show.json
      terraform graph | dot -Tpng >show.png
      hcl2json "''${target}".tfvars > terraform.json
    fi

    if [ "''${cmd}" = "nix" ]; then
      colmena "''${subcmd}" --on @"''${target}" --impure  "''${@:count:(''$#-2)}"
    fi
  '';
}