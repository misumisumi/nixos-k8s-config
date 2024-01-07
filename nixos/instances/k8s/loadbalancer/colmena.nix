{
  imports = [
    ../../init/colmena.nix
  ];
  deployment = {
    tags = [ "k8s" "loadbalancer" ];
  };
}
