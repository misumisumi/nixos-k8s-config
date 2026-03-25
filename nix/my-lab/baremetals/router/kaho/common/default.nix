{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    self.nixosModules.kexec
    inputs.microvm.nixosModules.host
    ./microvm.nix
  ];
  environment.systemPackages = with pkgs; [
    dig
    ethtool
    socat
    traceroute
  ];
}
