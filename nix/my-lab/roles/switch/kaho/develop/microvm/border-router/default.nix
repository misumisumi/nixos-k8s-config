{ pkgs, ... }:
{
  imports = [
    ../share
    ./bgp.nix
    ./network.nix
    ./v6plus.nix
  ];
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
    tshark
    tcpdump
  ];
}
