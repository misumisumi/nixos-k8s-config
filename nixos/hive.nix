{ lib
, inputs
, self
, ...
}:
let
  conf = with builtins; lib.filterAttrs (n: v: (match ".*-(install|test)" n) == null && (match "(lxc)-.*" n == null)) self.nixosConfigurations;
in
{
  meta = {
    nixpkgs = import inputs.nixpkgs {
      system = "x86_64-linux";
    };
    # nodeSpecialArgs = lib.listToAttrs (
    #   map (name: { inherit name; value = specialArgs4k8s; }) (controlPlaneHosts ++ etcdHosts ++ loadBalancerHosts ++ workerHosts)
    # );
    nodeSpecialArgs = builtins.mapAttrs (name: value: value._module.specialArgs) conf;
  };
}
  // builtins.mapAttrs
  (name: value:
    let
      extracted_name = with builtins; head (match "([a-z]+)[0-9]?+" name);
    in
    {
      imports = value._module.args.modules
      ++ lib.optional (builtins.pathExists ./hosts/${extracted_name}/colmena.nix) ./hosts/${extracted_name}/colmena.nix
      ++ lib.optional (builtins.pathExists ./instances/${extracted_name}/colmena.nix) ./instances/${extracted_name}/colmena.nix
      ++ lib.optional (builtins.pathExists ./instances/k8s/${extracted_name}/colmena.nix) ./instances/k8s/${extracted_name}/colmena.nix;
    })
  conf
