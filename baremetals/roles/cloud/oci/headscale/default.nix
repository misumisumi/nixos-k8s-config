# Headscale (self-hosted Tailscale control server) + 内蔵 DERP リレー。
# prod のみ（isDev では証明書・公開 DNS がないため無効）。
{
  imports = [
    ./client.nix
    ./dex.nix
    ./headplane.nix
    ./nginx.nix
    ./server.nix
  ];
}
