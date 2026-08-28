# Headscale (self-hosted Tailscale control server) + 内蔵 DERP リレー。
{
  imports = [
    ./client.nix
    ./dex.nix
    ./headplane.nix
    ./nginx.nix
    ./server.nix
  ];
}
