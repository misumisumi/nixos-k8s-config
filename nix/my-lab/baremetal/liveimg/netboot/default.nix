{ self, pkgs, ... }:
{
  imports = [
    ../../_init/settings
    ./network.nix
    self.nixosModules.netboot
  ];
  virtualisation.incus.agent.enable = true;
  environment.systemPackages = with pkgs; [
    coreutils # GNU coreutils
    dnsutils
    pciutils # Device utils
    tcpdump
    traceroute # Track the network route
  ];
}
