{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/lxd-virtual-machine.nix")
  ];
}
