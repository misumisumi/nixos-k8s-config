{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    tcpdump
  ];
}
