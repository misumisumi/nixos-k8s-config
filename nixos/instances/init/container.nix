{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/virtualisation/lxc-container.nix")
    (modulesPath + "/virtualisation/lxc-image-metadata.nix")
  ];
}
