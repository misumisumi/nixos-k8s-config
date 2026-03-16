{
  self,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    # self.nixosModules.kexec
    ./network_svi.nix
    ./bgp.nix
    ../../_init/nix
    ./linstor.nix
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
