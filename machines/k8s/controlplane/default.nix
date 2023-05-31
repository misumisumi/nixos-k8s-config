{
  lib,
  resourcesByRoles,
  ...
}: let
  pwd = builtins.toPath (builtins.getEnv "PWD");
  nodes = map (r: "${r.values.ip_address} ${r.values.id}") (resourcesByRoles ["etcd" "controlplane" "loadbalancer" "worker"]);
in {
  imports = [./addon-manager.nix ./apiserver.nix ./controller-manager.nix ./scheduler.nix];

  # For colmena
  deployment.keys."ca.pem" = {
    keyFile = "${pwd}/certs/generated/kubernetes/ca.pem";
    destDir = "/var/lib/secrets/kubernetes";
    user = "kubernetes";
  };

  services.kubernetes.clusterCidr = "10.200.0.0/16";

  networking.extraHosts = lib.strings.concatMapStrings (x: x + "\n") nodes;
}