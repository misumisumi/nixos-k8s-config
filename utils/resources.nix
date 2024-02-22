{ lib, ... }:
let
  workspace = builtins.getEnv "TF_WORKSPACE";
  check_path = path: builtins.pathExists path;
  tf_output_path = part_of: "${builtins.getEnv "PWD"}/terraform/${part_of}/${workspace}.json";
  payload = part_of: if check_path (tf_output_path part_of) then builtins.fromJSON (builtins.readFile (tf_output_path part_of)) else { };
  resourcesInModule = type: module: builtins.filter (r: r.type == type) (module.resources or [ ])
    ++ lib.flatten (map (resourcesInModule type) (module.child_modules or [ ]));
  resourcesByType = type: part_of: resourcesInModule type ((payload part_of).values.root_module or [ ]);

  tf_output_path_by_ws = part_of: ws: "${builtins.getEnv "PWD"}/terraform/${part_of}/${ws}.json";
  payloadByWS = part_of: ws: if check_path (tf_output_path_by_ws part_of ws) then builtins.fromJSON (builtins.readFile (tf_output_path_by_ws part_of ws)) else { };
  resourcesByTypeAndWS = type: part_of: ws: resourcesInModule type ((payloadByWS part_of ws).values.root_module or [ ]);
in
rec {
  resources = part_of: resourcesByType "incus_instance" part_of;
  resourcesByRole = role: part_of: (builtins.filter (r: lib.strings.hasPrefix role r.values.name) (resources part_of));
  resourcesByRoles = roles: part_of: lib.flatten (lib.forEach roles
    (role: builtins.filter
      (r: lib.strings.hasPrefix role r.values.name)
      (resources part_of)));

  resourcesByWS = part_of: ws: resourcesByTypeAndWS "incus_instance" part_of ws;
  resourcesByRoleAndWS = role: part_of: ws: (builtins.filter (r: lib.strings.hasPrefix role r.values.name) (resourcesByWS part_of ws));
  outputsByRole = role: part_of: (builtins.filter (r: lib.strings.hasPrefix role r.name) (payload part_of).values.outputs.instance_info.value);

  nodeIP = r: r.values.ipv4_address;
  machineType = target: tag: builtins.head (map (r: r.values.type) (resourcesByRole target tag));
}
