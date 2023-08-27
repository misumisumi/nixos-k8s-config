{ inputs }:
let
  inherit (inputs.nixpkgs) lib;
  inherit (import ../../utils/resources.nix { inherit lib; }) resourcesFromHosts;

  hosts = map (r: r.name) resourcesFromHosts;

  hostConf =
    { name
    , ip_address
    , ...
    }: {
      imports = [ ./autoresources.nix ./common ./${name} ];
      deployment.tags = [ "hosts" "${name}" ];
      deployment.targetHost = ip_address;
      networking.hostName = name;
    };
in
builtins.listToAttrs (map
  (h: {
    name = h;
    value = hostConf;
  })
  hosts)
