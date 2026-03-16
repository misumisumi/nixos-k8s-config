{
  self,
  config,
  inputs,
  ...
}:
{
  imports = [
    # ./cockpit.nix
    ./dnsmasq.nix
    ./network.nix
    ./nginx.nix
    ./ssh.nix
    # ../_init/nix
    self.nixosModules.multiple-dnsmasq
    inputs.nixos-linstor.nixosModules.default
  ];
  services.linstor = {
    controller.enable = true;
    controller.webui.enable = true;
    client.enable = true;
  };
  system.stateVersion = config.system.nixos.release;
}
