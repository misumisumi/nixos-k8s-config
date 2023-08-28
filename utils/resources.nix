{ lib, ... }:
let
  json = env: "${builtins.getEnv "PWD"}/terraform/${env}/show.json";
  payload = env:
    if builtins.pathExists (json env)
    then builtins.fromJSON (builtins.readFile (json env))
    else { };
  resourcesInModule = type: module: builtins.filter (r: r.type == type) (module.resources or [ ]) ++ lib.flatten (map (resourcesInModule type) (module.child_modules or [ ]));
in
rec {
  resourcesByType = type: env: resourcesInModule type ((payload env).values.root_module or [ ]);
  resources = env: resourcesByType "lxd_instance" env;
  resourcesByRole = role: env: (builtins.filter (r: lib.strings.hasPrefix role r.values.name) (resources env));
  resourcesByRoles = roles: env: lib.flatten (lib.forEach roles (role: builtins.filter (r: lib.strings.hasPrefix role r.values.name) (resources env)));
  resourcesFromHosts = (builtins.fromJSON (builtins.readFile "${builtins.getEnv "PWD"}/config.json")).hosts;
}