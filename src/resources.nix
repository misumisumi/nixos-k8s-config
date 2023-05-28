{lib, ...}: let
  pwd = builtins.getEnv "PWD";
  payload = builtins.fromJSON (builtins.readFile "${pwd}/show.json");
  resourcesInModule = type: module: builtins.filter (r: r.type == type) (module.resources or []) ++ lib.flatten (map (resourcesInModule type) (module.child_modules or []));
  resourcesByType = type: resourcesInModule type payload.values.root_module;
in rec {
  resources = resourcesByType "lxd_container";
  resourcesByRole = role: (builtins.filter (r: lib.strings.hasPrefix role r.values.name) resources);
  resourcesByRoles = roles: lib.flatten (lib.forEach roles (role: builtins.filter (r: lib.strings.hasPrefix role r.values.name) resources));
}