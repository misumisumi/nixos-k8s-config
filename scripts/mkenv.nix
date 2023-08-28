{ writeShellApplication
,
}:
let
  workspaces = [ "development" "staging" "production" ];
  genWS = map (ws: "[[ $(terraform workspace list | grep ${ws}) == '' ]] && terraform workspace new ${ws}") workspaces;
in
writeShellApplication {
  name = "mkenv";
  text = ''
    [[ ! -d ./.terraform ]] && terraform init
    ${builtins.concatStringsSep "\n" genWS}

    echo "initialization complete"
  '';
}
