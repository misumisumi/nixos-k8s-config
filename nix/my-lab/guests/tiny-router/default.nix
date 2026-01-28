{ self, config, ... }:
{
  imports = [
    ./cockpit.nix
    ./dnsmasq.nix
    ./network.nix
    ./nginx.nix
    ./ssh.nix
    self.nixosModules.multiple-dnsmasq
    self.nixosModules.static
  ];
  system.stateVersion = config.system.nixos.release;
}
