{ writeShellApplication }:
writeShellApplication {
  name = "deploy";
  text = ''
    usage() {
      cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
    Usage: ''$(
        basename "''${BASH_SOURCE[0]}"
      ) <cmd> <subcmd> [-t] [-w] [-h] [-v] -- <colmena option>

      Deployment NixOS by colmena with workspace-specific variables

    Available options:

    -t, --tag       Tag of managed remote machine
    -w, --workspace Workspace name (default: check 'terraform workspace list')
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
      workspace="dummy"
      cmd=""
      subcmd=""
      while (( $# > 0 )) do
        count=''$((count + 1))
        case "''${1-}" in
        -h | --help) usage ;;
        -v | --verbose) set -x ;;
        -w | --workspace) shift
          workspace=''${1-}
          count="''$((count + 1))"
        ;;
        -t | --tag) shift
          tag=''${1-}
          count="''$((count + 1))"
        ;;
        -- ) break
        ;;
        -?*) break;;
        *) if [ "''${cmd}" == "" ]; then
            cmd=''${1-}
          elif [ "''${subcmd}" == "" ]; then
            subcmd=''${1-}
          fi
        ;;
        esac
        shift
      done

      count="''$((count + 1))"
      return 0
    }

    parse_params "''$@"

    # check required params and arguments
    if [ "''${subcmd}" == "" ]; then
      TF_WORKSPACE="''${workspace}" colmena "''${cmd}" --on @"''${tag}" --impure "''${@:count:(''$#-2)}"
    else
      TF_WORKSPACE="''${workspace}" colmena "''${cmd}" "''${subcmd}" --on @"''${tag}" --impure "''${@:count:(''$#-2)}"
    fi
  '';
}
