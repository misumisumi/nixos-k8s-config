{ nodeIP, ... }:
{
  imports = [
    ./coredns/colmena.nix
    ./flannel/colmena.nix
    ./kube-proxy/colmena.nix
  ];

  deployment.targetHost = nodeIP;
}
