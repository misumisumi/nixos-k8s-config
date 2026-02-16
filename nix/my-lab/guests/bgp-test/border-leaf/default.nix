{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # self.nixosModules.kexec
    ./network.nix
    ./bgp.nix
  ];
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
    tshark
  ];
  fonts.fontconfig.enable = false;
}
