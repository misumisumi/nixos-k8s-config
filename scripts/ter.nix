{writeShellApplication}:
writeShellApplication {
  name = "ter";
  text = ''
    usage() {
      cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
    Usage: ''$(
        basename "''${BASH_SOURCE[0]}"
      ) <cmd> <workspace> [-h] [-v]

      Launch container and VM by terraform using workspace-specific variables

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
        -?*) break ;;
        *) cmd=''${1-}
          shift
          workspace=''${1-}
        ;;
        esac
        shift
      done

      count="''$((count + 1))"
      return 0
    }

    parse_params "''$@"

    # check required params and arguments
    [[ "''${workspace}" == "" ]] && die "Need workspace name"

    # script logic here
    terraform workspace select "''${workspace}" || echo "''${workspace} is not listed in the workspace."
    terraform "''${cmd}" -var-file="''${workspace}".tfvars "''${@:count:(''$#-2)}"
    terraform show -json | jq >show.json
    terraform graph | dot -Tpng >show.png
    hcl2json "''${workspace}".tfvars > terraform.json
  '';
}