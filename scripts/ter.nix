{ writeShellApplication }:
let
  inherit (builtins.fromJSON (builtins.readFile ../config.json)) workspaces;
  genWS = map (ws: "[[ $(tofu workspace list | grep ${ws}) == '' ]] && tofu workspace new ${ws}") workspaces;
in
writeShellApplication {
  name = "ter";
  text = ''
    usage() {
      cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
    Usage: ''$(
        basename "''${BASH_SOURCE[0]}"
      ) <cmd> [-w] [-h] [-v] -- <tofu option>

      Launch container and VM by tofu using workspace-specific variables

    Available options:

    -w, --workspace Workspace name (Required for subcommands other than "ter init")
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
      cmd=""
      workspace=""
      while (( $# > 0 )) do
        count=''$((count + 1))
        case "''${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -w | --workspace) shift
          workspace=''${1-}
          count="''$((count + 1))"
        ;;
        -- ) break
        ;;
        -?*) break ;;
        *) cmd=''${1-} ;;
        esac
        shift
      done

      count="''$((count + 1))"
      return 0
    }

    parse_params "''$@"

    # check required params and arguments
    if [ "''${cmd}" == "init" ]; then
      tofu init "''${@:count:(''$#-1)}"
      ${builtins.concatStringsSep "\n" genWS}
      exit 0
    elif [ "$(tofu workspace list | grep "''${workspace}")" == "" ]; then
      die "''${workspace} is not listed in the workspace."
    else
      tofu workspace select "''${workspace}"
    fi

    # script logic here
    tofu "''${cmd}" -var-file="''${workspace}".tfvars "''${@:count:(''$#-1)}"
    if [[ "''${cmd}" == "apply"  ]]; then
      tofu show -json > "''${workspace}".json
      tofu output -json > "''${workspace}_output".json
      tofu graph | dot -Tpng > "''${workspace}".png
    elif [[ "''${cmd}" == "destroy" ]]; then
      rm "''${workspace}".json
      rm "''${workspace}".png
    fi
  '';
}
