{
  lib,
  writeShellApplication,
}: let
  inherit (builtins.fromJSON (builtins.readFile "${builtins.getEnv "PWD"}/config.json")) virtualIPs;
  genWS = lib.mapAttrsToList (ws: ip: "[[ $(terraform workspace list | grep ${ws}) == '' ]] && terraform workspace new ${ws}") virtualIPs;
in
  writeShellApplication {
    name = "mkenv";
    text = ''
      [[ ! -d ./.terraform ]] && terraform init
      ${builtins.concatStringsSep "\n" genWS}

      echo "initialization complete"
    '';
  }