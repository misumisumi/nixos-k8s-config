{ pkgs, ... }:
{
  imports = [
    ../share
    ./bgp.nix
    ./network.nix
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
