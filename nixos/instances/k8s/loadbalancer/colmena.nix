{
  imports = [
    ../../init/colmena.nix
  ];
  deployment = {
    tags = [ "cardinal" "k8s" "loadbalancer" ];
  };
}
