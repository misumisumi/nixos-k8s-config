{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # self.nixosModules.kexec
    inputs.microvm.nixosModules.host
    ./bgp.nix
    ./microvm.nix
    ./network.nix
  ];
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
  ];
}
