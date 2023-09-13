{ lib, ... }:
let
  workspace = builtins.getEnv "TF_WORKSPACE";
  payload = target: builtins.fromJSON (builtins.readFile "${builtins.getEnv "PWD"}/terraform/${target}/${workspace}.json");
  resourcesInModule = type: module: builtins.filter (r: r.type == type) (module.resources or [ ])
    ++ lib.flatten (map (resourcesInModule type) (module.child_modules or [ ]));
  resourcesByType = type: target: resourcesInModule type ((payload target).values.root_module or [ ]);

  payloadByWS = target: ws: builtins.fromJSON (builtins.readFile "${builtins.getEnv "PWD"}/terraform/${target}/${ws}.json");
  resourcesByTypeAndWS = type: target: ws: resourcesInModule type ((payloadByWS target ws).values.root_module or [ ]);

in
rec {
  resources = target: resourcesByType "lxd_instance" target;
  resourcesByRole = role: target: (builtins.filter (r: lib.strings.hasPrefix role r.values.name) (resources target));
  resourcesByRoles = roles: target: lib.flatten (lib.forEach roles
    (role: builtins.filter
      (r: lib.strings.hasPrefix role r.values.name)
      (resources target)));

  resourcesByWS = target: ws: resourcesByTypeAndWS "lxd_instance" target ws;
  resourcesByRoleAndWS = role: target: ws: (builtins.filter (r: lib.strings.hasPrefix role r.values.name) (resourcesByWS target ws));
  nodeIP = r: r.values.ip_address;
}