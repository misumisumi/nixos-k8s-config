{writeShellApplication}:
writeShellApplication {
  name = "deploy";
  text = ''
    usage() {
      cat <<EOF # remove the space between << and EOF, this is due to web plugin issue
    Usage: ''$(
        basename "''${BASH_SOURCE[0]}"
      ) <plan|apply> <workspace> [-h] [-v]

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
      workspace=''$2

      # check required params and arguments
      for value in "''${cmd[@]}"
      do
        [[ "''${value}" != "plan" ]] && [[ "''${value}" != "apply" ]] && die "Can use only 'plan' or 'apply'"
      done
      for value in "''${workspace[@]}"
      do
        [[ "''${value}" == "" ]] && die "Need workspace name"
      done

      return 0
    }

    parse_params "''$@"

    # script logic here

    terraform workspace select "''${workspace}"
    terraform "''${cmd}" -var-file="''${workspace}".tfvars
    terraform show -json | jq >show.json
    hcl2json "''${workspace}.tfvars" > terraform.json
  '';
}