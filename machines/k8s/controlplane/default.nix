{...}: let
  pwd = builtins.toPath (builtins.getEnv "PWD");
in {
  imports = [./apiserver.nix ./controller-manager.nix ./scheduler.nix];

  # For colmena
  deployment.keys."ca.pem" = {
    keyFile = "${pwd}/certs/generated/kubernetes/ca.pem";
    destDir = "/var/lib/secrets/kubernetes";
    user = "kubernetes";
  };

  services.kubernetes.clusterCidr = "10.200.0.0/16";
}