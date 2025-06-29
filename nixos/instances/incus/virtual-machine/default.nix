{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/incus-virtual-machine.nix")
  ];
}
