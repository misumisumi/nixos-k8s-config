{ lib, ... }:
let
  json = "${builtins.getEnv "PWD"}/show.json";
  payload =
    if builtins.pathExists json
    then builtins.fromJSON (builtins.readFile json)
    else { };
  resourcesInModule = type: module: builtins.filter (r: r.type == type) (module.resources or [ ]) ++ lib.flatten (map (resourcesInModule type) (module.child_modules or [ ]));
in
rec {
  resourcesByType = type: resourcesInModule type (payload.values.root_module or [ ]);
  resources = resourcesByType "lxd_container";
  resourcesByRole = role: (builtins.filter (r: lib.strings.hasPrefix role r.values.name) resources);
  resourcesByRoles = roles: lib.flatten (lib.forEach roles (role: builtins.filter (r: lib.strings.hasPrefix role r.values.name) resources));
  resourcesFromHosts = (builtins.fromJSON (builtins.readFile "${builtins.getEnv "PWD"}/config.json")).hosts;
}
