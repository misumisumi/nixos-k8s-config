{ lib, ... }:
let
  _workspace = builtins.getEnv "TF_WORKSPACE";
  config = builtins.fromJSON (builtins.readFile "${builtins.getEnv "PWD"}/config.json");
in
rec {
  inherit (config) workspaces;
  workspace = if _workspace == "" then "development" else _workspace;
  constByKey = key: config.${key};
  virtualIP = target: (constByKey "virtualIPs").${target}.${workspace};
  nodeIP = node: (constByKey "instanceIPs").${workspace}.${node};
  nodeIPsByRole = role: lib.filterAttrs
    (x: y: lib.hasPrefix role x)
    (constByKey "instanceIPs").${workspace};
  nodeIPsByRoles = roles: builtins.listToAttrs (lib.flatten
    (lib.forEach roles
      (role:
        lib.mapAttrsToList (x: y: { name = x; value = y; })
          (lib.filterAttrs
            (x: y: lib.hasPrefix role x)
            (constByKey "instanceIPs").${workspace}
          )
      )
    )
  );
  nodeIPByWS = node: ws: (constByKey "instanceIPs").${ws}.${node};
  nodeIPsByRoleAndWS = role: ws: lib.filterAttrs (x: y: lib.hasPrefix role x) (constByKey "instanceIPs").${ws};
}

