{ config, ... }:
{
  imports = [
    ./autoresources.nix
    ./cockpit.nix
    ./dnsmasq.nix
    ./networking.nix
    ./nginx.nix
    ./ssh.nix
  ];
  system.stateVersion = config.system.nixos.release;
}
