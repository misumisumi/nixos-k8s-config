{
  imports = [
    ./cilium
    ./coredns.nix
    ./external-dns.nix
    ./gateway-api.nix
    ./traefik.nix
    ./cert-manager
  ];
}
