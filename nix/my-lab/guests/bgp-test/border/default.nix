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
    ./network.nix
    ./bgp.nix
    ./microvm.nix
  ];
  environment.systemPackages = with pkgs; [
    dig
    socat
    traceroute
  ];
}
